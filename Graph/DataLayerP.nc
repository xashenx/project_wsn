/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		DataLayerP.nc
 *	DESCRIPTION:	Data layer component
 *
 */

 #include <Timer.h>
 #include "DataMsg.h"

module DataLayerP
{
	provides{
		interface DataToNetwork;
	}	
	uses{
		interface Timer<TMilli> as TimerSend;
		interface Timer<TMilli> as TimerMessage;
		interface Leds;
		interface Boot;
		interface PacketAcknowledgements as Acks;
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Receive;
		interface Random;
		interface Queue<DataMsg>;
		interface NetworkToData;
	}
}
implementation
{
	bool sending;
	bool updated;
	#ifndef BESTEFFORT
	bool doRetransmission;
	#ifdef REMOVEPARENT
	uint16_t tries;
	#endif
	#endif
	message_t pkt;
	uint16_t my_parent;

	event void Boot.booted(){
		call AMControl.start();
		sending = FALSE;
		updated = FALSE;
		#ifndef BESTEFFORT
		doRetransmission = FALSE;
		#ifdef REMOVEPARENT
		tries = 0;
		#endif
		#endif
	}

	event void AMControl.startDone(error_t err){
		if (err != SUCCESS){
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err){}

	task void forwardMessage(){
		uint16_t queueSize;
		queueSize = call Queue.size();
		if(queueSize>0){
		/*
		 *	IF THE QUEUE CONTAINS AT LEAST AN ELEMENT, PROCEED WITH THE FORWARDING
		 *	THE CHECK COULD BE DONE EVEN USING !Queue.empty();
		 */
			DataMsg payload = (DataMsg) call Queue.dequeue();
			DataMsg * toDeliver = (DataMsg*) (call Packet.getPayload(&pkt,sizeof(DataMsg)));
			*toDeliver = payload;
			call Acks.requestAck(&pkt);
			sending = TRUE;
			toDeliver -> hops += 1;// toDeliver->hops+1;
			my_parent = signal DataToNetwork.nextParent();
			#ifdef DATA
				dbg("data","SENDING\t%u\tTO\t%u\n",toDeliver->data,my_parent);
			#endif
			call AMSend.send(my_parent,&pkt,sizeof(DataMsg));
		}
	}

	task void enqueueHello(){
	/*
	 *	SEND A DUMMY MESSAGE CONTAINING THE ID OF THE ORIGIN
	 */
	 	message_t helloMsg;
		DataMsg* hello = (DataMsg*)(call Packet.getPayload(&helloMsg,sizeof(DataMsg)));
		hello -> data = TOS_NODE_ID;
		hello -> hops = 0;
		call Queue.enqueue(*hello);
	}

	event void TimerSend.fired(){
		#ifdef REMOVEPARENT
		if(tries>CPR_DATA_TRIGGER){
			dbg("data","removing parent from dataL: %u\n",my_parent);
			signal DataToNetwork.removeParent(my_parent);
			my_parent = signal DataToNetwork.nextParent();
		}
		#endif
		if(!sending){
			post forwardMessage();
		} 
		#ifndef BESTEFFORT
		else if(doRetransmission){
		/*
		 *	IF THE RETRANSMISSION FLAG IS SET, THEN THE PROCEDURE IS ACTIVATED
		 */
			#ifdef DATA
				DataMsg* payload = (DataMsg*)(call Packet.getPayload(&pkt,sizeof(DataMsg)));
				dbg("data","RESEND\t%u\tTO\t%u\n",payload->data,my_parent);
			#endif
			call Acks.requestAck(&pkt);
			call AMSend.send(my_parent,&pkt,sizeof(DataMsg));
			#ifdef REMOVEPARENT
			tries++;
			#endif
		}
		#endif
	}

	event void TimerMessage.fired(){
		uint16_t queueSize;
		//if(TOS_NODE_ID != 4 && TOS_NODE_ID != 1){
		/*
		 *	PREVENT THE DIRECTLY CONNECTED NODES TO SPAM
		 */
			queueSize = call Queue.size();
			if(queueSize<20)
				post enqueueHello();
		//}
	}

	event void AMSend.sendDone(message_t* msg, error_t error){
		#ifdef DATA
			DataMsg* payload = (DataMsg*)(call Packet.getPayload(&pkt,sizeof(DataMsg)));
		#endif
		if (&pkt == msg && error == SUCCESS){
			#ifndef BESTEFFORT
			if(!call Acks.wasAcked(msg)){
			/*
			 *	CHECKS IF THE MESSAGE WAS ACKED
			 */
				//dbg("data","failed ack on %u\n",payload->data);
				doRetransmission = TRUE;
			}else{
			/*
			 *	THE MESSAGE WAS SUCCESSFULLY SENT
			 */
			 	#ifdef DATA
				if(doRetransmission)
					dbg("data","RESEND OF\t%u\tSUCCESSFULL\n",payload->data);
				#endif
				doRetransmission = FALSE;
				#ifdef REMOVEPARENT
				tries = 0;
				#endif
			#endif
				sending = FALSE;
				signal DataToNetwork.messageForwarded(my_parent);
		#ifndef BESTEFFORT
			}

		}else{
		/*
		 *	THE TRANSMISSION WAS NOT SUCCESSFULL, SO RETRANSMISSION IS NECESSARY
		 */
			doRetransmission = TRUE;
			//dbg("data","failed transmission");
		#endif
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		if (len == sizeof(DataMsg)){
			if(TOS_NODE_ID!=0){
			/*
			 *	ANY NODE BUT SINK SHOULD FORWARD THE MESSAGE
				//dbg("data","received %u\n",((DataMsg*)payload)->data);	
			 */
			 	#ifdef DATA
				if(((DataMsg*)payload) -> data == TOS_NODE_ID)
					dbg("data","LOOP\tDETECTED!\n");
				#endif
				call Queue.enqueue(*(DataMsg*)payload);
			}
			#ifdef DOUBLE
			/*
			 *	WHEN USING THE SECOND SINK (SPERIMENTAL!)
			 *
			 */
			if(TOS_NODE_ID!=6)
				call Queue.enqueue(*(DataMsg*)payload);	
			#endif
			else
				dbg("data","RECEIVED\t%u\tTHROUGH\t\t%u\tHOP(S)\n",((DataMsg*)payload)->data,((DataMsg*)payload)->hops);
		}
		return msg;
	}

	event void NetworkToData.parentUpdate(uint16_t parent){
		//if(parent != my_parent)
		//	post enqueueHello();
		my_parent = parent;
		if(!updated){
			updated = TRUE;
			sending = FALSE;
			#ifdef REMOVEPARENT
			tries = 0;
			#endif
			if(TOS_NODE_ID!=0){
			/*
			 *	ALL BUT THE SINK KEEP SPINNING ON TIMER TO RETRANSMIT
			 */
				//retransmissions = 0;
				post enqueueHello();
				call TimerSend.startPeriodic(SEND_PERIOD);
				call TimerMessage.startPeriodic(MESSAGE_PERIOD);
			}
		}
	}

	/*event bool NetworkToData.sendRequest(uint16_t mode){
		if(mode==0){
			// the network layer asks for sending
			if(sending)
				return FALSE;
			else{
				sending = TRUE;
				return TRUE;
			}
		}else{
			// the network layer has performed its
			// send, the lock is released
			sending = FALSE;
			return TRUE;
		}
	}*/

	event bool NetworkToData.stopData(){
		// the next parent update will restart the timers
		#ifdef RELIABILITY
			dbg("data","stopping data transmission\n");
		#endif
		updated = FALSE;
		sending = TRUE;
		#ifndef BESTEFFORT
		doRetransmission = FALSE;
		#endif
		call TimerSend.stop();
		call TimerMessage.stop();
		return TRUE;
	}
}

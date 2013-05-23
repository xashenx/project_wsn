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
	bool doRetransmission;
	message_t pkt;
	uint16_t my_parent;

	event void Boot.booted(){
		call AMControl.start();
		sending = FALSE;
		updated = FALSE;
		doRetransmission = FALSE;
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
			#ifdef DATA
			dbg("data","sending %u to %u\n",toDeliver->data,my_parent);
			#endif
			call AMSend.send(my_parent,&pkt,sizeof(DataMsg));
		}
	}

	task void enqueueHello(){
	/*
	 *	SEND A DUMMY MESSAGE CONTAINING THE ID OF THE ORIGIN
	 */
		DataMsg* hello = (DataMsg*)(call Packet.getPayload(&pkt,sizeof(DataMsg)));
		hello -> data = TOS_NODE_ID;
		call Queue.enqueue(*hello);
	}

	event void TimerSend.fired(){
		if(!sending){
			post forwardMessage();
		} else if(doRetransmission){
		/*
		 *	IF THE RETRANSMISSION FLAG IS SET, THEN THE PROCEDURE IS ACTIVATED
		 */
			#ifdef DATA
				DataMsg* payload = (DataMsg*)(call Packet.getPayload(&pkt,sizeof(DataMsg)));
				dbg("data","retransmitting %u to %u\n",payload->data,my_parent);
			#endif
			call Acks.requestAck(&pkt);
			call AMSend.send(my_parent,&pkt,sizeof(DataMsg));
		}
	}

	event void TimerMessage.fired(){
		uint16_t queueSize;
		//if(TOS_NODE_ID != 4 && TOS_NODE_ID != 1){
		/*
		 *	PREVENT THE DIRECTLY CONNECTED NODES TO SPAM
		 */
			queueSize = call Queue.size();
			if(queueSize<12)
				post enqueueHello();
		//}
	}

	event void AMSend.sendDone(message_t* msg, error_t error){
		#ifdef DATA
			DataMsg* payload = (DataMsg*)(call Packet.getPayload(&pkt,sizeof(DataMsg)));
		#endif
		if (&pkt == msg && error == SUCCESS){
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
					dbg("data","retransmission successfull on %u\n",payload->data);
				#endif
				sending = FALSE;
				doRetransmission = FALSE;
			}
		}else{
		/*
		 *	THE TRANSMISSION WAS NOT SUCCESSFULL, SO RETRANSMISSION IS NECESSARY
		 */
			doRetransmission = TRUE;
			//dbg("data","failed transmission");
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		if (len == sizeof(DataMsg)){
			if(TOS_NODE_ID!=0)
			/*
			 *	ANY NODE BUT SINK SHOULD FORWARD THE MESSAGE
				//dbg("data","received %u\n",((DataMsg*)payload)->data);	
			 */
				call Queue.enqueue(*(DataMsg*)payload);
			else
				dbg("data","received %u\n",((DataMsg*)payload)->data);
		}
		return msg;
	}

	event void NetworkToData.parentUpdate(uint16_t parent){
		//if(parent != my_parent)
		//	post enqueueHello();
		my_parent = parent;
		if(!updated){
			updated = TRUE;
			if(TOS_NODE_ID!=0){
			/*
			 *	ALL BUT THE SINK KEEP SPINNING ON TIMER TO RETRANSMIT
			 */
				post enqueueHello();
				call TimerSend.startPeriodic(SEND_PERIOD);
				call TimerMessage.startPeriodic(MESSAGE_PERIOD);
			}
		}
	}

	event bool NetworkToData.sendRequest(uint16_t mode){
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
	}

	event bool NetworkToData.stopData(){
		// the next parent update will restart the timers
		#ifdef RELIABILITY
			dbg("data","stopping data transmission\n");
		#endif
		updated = FALSE;
		call TimerSend.stop();
		call TimerMessage.stop();
		return TRUE;
	}
}

/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		DataCollectionP.nc
 *	DESCRIPTION:	Data layer component
 *
 */

 #include <Timer.h>
 #include "DataMsg.h"

module DataCollectionP
{
	provides{
		interface DataToRouting;
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
		interface RoutingToData;
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
			dbg("routing","sending %u to %u\n",toDeliver->data,my_parent);
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
		bool alive = TRUE;
		if(!sending){
			post forwardMessage();
		}
		else if(doRetransmission){
		/*
		 *	IF THE RETRANSMISSION FLAG IS SET, THEN THE PROCEDURE IS ACTIVATED
		 */
			DataMsg* payload = (DataMsg*)(call Packet.getPayload(&pkt,sizeof(DataMsg)));
			dbg("routing","retransmitting %u to %u\n",payload->data,my_parent);
			call Acks.requestAck(&pkt);
			call AMSend.send(my_parent,&pkt,sizeof(DataMsg));
		}
	}

	event void TimerMessage.fired(){
		uint16_t queueSize;
		if(TOS_NODE_ID != 4 && TOS_NODE_ID != 1){
		/*
		 *	PREVENT THE DIRECTLY CONNECTED NODES TO SPAM
		 */
			/*queueSize = call Queue.size();
			if(queueSize<12)
				post enqueueHello();*/
		}
	}

	event void AMSend.sendDone(message_t* msg, error_t error){
		DataMsg* payload = (DataMsg*)(call Packet.getPayload(&pkt,sizeof(DataMsg)));
		if (&pkt == msg && error == SUCCESS){
			if(!call Acks.wasAcked(msg)){
			/*
			 *	CHECKS IF THE MESSAGE WAS ACKED
			 */
				//dbg("routing","failed ack on %u\n",payload->data);
				doRetransmission = TRUE;
			}else{
			/*
			 *	THE MESSAGE WAS SUCCESSFULLY SENT
			 */
				if(doRetransmission)
					dbg("routing","retransmission successfull on %u\n",payload->data);
				sending = FALSE;
				doRetransmission = FALSE;
			}
		}else{
		/*
		 *	THE TRANSMISSION WAS NOT SUCCESSFULL, SO RETRANSMISSION IS NECESSARY
		 */
			doRetransmission = TRUE;
			//dbg("routing","failed transmission");
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		if (len == sizeof(DataMsg)){
			if(TOS_NODE_ID==0)
				dbg("routing","received %u\n",((DataMsg*)payload)->data);
			else{
			/*
			 *	ANY OTHER NODE SHOULD FORWARD THE MESSAGE
			 */
				call Queue.enqueue(*(DataMsg*)payload);
				//dbg("routing","received %u\n",((DataMsg*)payload)->data);
			}	
		}
		return msg;
	}

	event void RoutingToData.parentUpdate(uint16_t parent){
		my_parent = parent;
		if(!updated){
			updated = TRUE;
			if(TOS_NODE_ID!=0){
			/*
			 *	ALL BUT THE SINK KEEP SPINNING ON TIMER TO RETRANSMIT
			 */
				post enqueueHello();
//				if(TOS_NODE_ID == 4 || TOS_NODE_ID == 1)
				//call TimerSend.startPeriodic(((parent+4)*(80+((parent+1)*6))));
				call TimerSend.startPeriodic(SEND_PERIOD);
				call TimerMessage.startPeriodic(MESSAGE_PERIOD);
//				call TimerApp.startPeriodic((((parent-15)%15)*80));
			}
		}
	}

	event bool RoutingToData.sendRequest(uint16_t mode){
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
}

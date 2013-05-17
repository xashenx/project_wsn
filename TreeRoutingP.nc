 #include <Timer.h>
 #include "TreeBuilding.h"

module TreeRoutingP{
	provides{
		interface TreeConnection;
	}
	uses{
		interface Timer<TMilli> as TimerRefresh;
		interface Timer<TMilli> as TimerNotification;
		interface Leds;
		interface Boot;
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Receive;
	#ifndef TOSSIM
		interface CC2420Packet;
	#else
		interface TossimPacket;
	#endif
		interface Read<uint16_t> as Voltage;
		interface Random;
	}
}

implementation{
	message_t pkt;
	bool sending;
	uint16_t current_parent;
	uint16_t current_cost;
  	uint16_t current_seq_no;
	uint16_t num_received;
  
	event void Boot.booted(){
		current_parent = TOS_NODE_ID;
		current_cost = 0;
		current_seq_no = 0;
		num_received = 0;
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err){
		if (err == SUCCESS){
			if (TOS_NODE_ID == 0){
				call TimerRefresh.startPeriodic(REFRESH_PERIOD);
			}
		} else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err){}

	task void sendNotification(){
		TreeBuilding* msg = (TreeBuilding*) (call Packet.getPayload(&pkt, NULL));
		error_t error;
		msg->seq_no = current_seq_no;
		msg->metric = current_cost;
/*		dbg("routing", "NOT\tSEQ\t%u\tCOST\t%u\n", current_seq_no, current_cost); */
		if ((error = call AMSend.send(AM_BROADCAST_ADDR, &pkt,
			sizeof(TreeBuilding))) == SUCCESS){
			call Leds.led2On();
			sending = TRUE;
		} else {
			dbg("routing", "\n\n\n\nERROR\t%u\n", error);
			call TimerNotification.startOneShot(call Random.rand16()%500);
		}
	}

	event void TimerRefresh.fired(){
		if (!sending){
			current_seq_no++;
			post sendNotification();
		}
	}

	event void TimerNotification.fired(){
		if (!sending)
			post sendNotification();
	}

	event void AMSend.sendDone(message_t* msg, error_t error){
		if (&pkt == msg && error == SUCCESS)
			sending = FALSE;
		else
			call TimerNotification.startOneShot(call Random.rand16()%500);
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		if (len == sizeof(TreeBuilding) && TOS_NODE_ID != 0){
			TreeBuilding* treemsg = (TreeBuilding*) payload;
			uint16_t temp_cost;
		#ifdef TOSSIM
			//temp_cost = treemsg->metric + 1;
			temp_cost = treemsg->metric + (-1*call TossimPacket.strength(msg));
		#else        
			temp_cost = treemsg->metric + call CC2420Packet.getLqi(msg);
		#endif
			num_received++;
			//dbg("routing","lqi from %u is %u\n", call CC2420Packet.getLqi(msg),call AMPacket.source(msg));
			/*dbg("routing", "MSG\t%u\tSOURCE\t%u\tSEQ\t%u\tMETRIC\t%u\n",
			num_received, call AMPacket.source(msg),
			treemsg->seq_no, temp_cost); */
			if (treemsg->seq_no < current_seq_no)
				return msg;
			if (treemsg->seq_no > current_seq_no){
				current_seq_no = treemsg->seq_no;
				current_parent = call AMPacket.source(msg);
				signal TreeConnection.parentUpdate(current_parent);
				current_cost = temp_cost;
				dbg("routing", "SET\tPARENT\t%u\tCOST\t%u\n", current_parent, current_cost);
				call TimerNotification.startOneShot(call Random.rand16()%500);
			} else {
				if (current_cost > temp_cost ||
					call AMPacket.source(msg) == current_parent){
					current_seq_no = treemsg->seq_no;
					current_parent = call AMPacket.source(msg);
					signal TreeConnection.parentUpdate(current_parent);
					current_cost = temp_cost;
					dbg("routing", "SET\tPARENT\t%u\tCOST\t%u\n", current_parent, current_cost);
					call TimerNotification.startOneShot(call Random.rand16()%500);
				}
			}
		}
		return msg;
	}

	event void Voltage.readDone(error_t result, uint16_t val){}

}

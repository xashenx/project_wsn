/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		GraphRoutingP.nc
 *	DESCRIPTION:	Network layer component
 *
 */

 #include <Timer.h>
 //#include "GraphBuilding.h"
 #include "RoutingMsg.h"

module GraphRoutingP{
	provides{
		interface GraphConnection;
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
		interface Random;
	}
}

implementation{
	message_t pkt;
	bool sending;
	uint16_t current_parent;
	uint16_t current_cost;
  	uint16_t current_seq_no;
	uint16_t num_received; // counter of received messages
	RoutingMsg parents[MAX_PARENTS]; // structure array of the parents of the node
	uint16_t active_parents; //counter of active parents
  
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
		//GraphBuilding* msg = (GraphBuilding*) (call Packet.getPayload(&pkt, NULL));
		RoutingMsg* msg = (RoutingMsg*) (call Packet.getPayload(&pkt,sizeof(RoutingMsg)));
		error_t error;
		msg->seq_no = current_seq_no;
		msg->metric = current_cost;
/*		dbg("routing", "NOT\tSEQ\t%u\tCOST\t%u\n", current_seq_no, current_cost); */
		if ((error = call AMSend.send(AM_BROADCAST_ADDR, &pkt,
			sizeof(RoutingMsg))) == SUCCESS){
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
		if (len == sizeof(RoutingMsg) && TOS_NODE_ID != 0){
			RoutingMsg* routing_msg = (RoutingMsg*) payload;
			uint16_t temp_cost;
		#ifdef TOSSIM
			temp_cost = routing_msg->metric + 1;
			//temp_cost = routing_msg->metric + (-1*call TossimPacket.strength(msg));
		#else        
			temp_cost = routing_msg->metric + call CC2420Packet.getLqi(msg);
		#endif
			num_received++;
			//dbg("routing","lqi from %u is %u\n", call CC2420Packet.getLqi(msg),call AMPacket.source(msg));
			/*dbg("routing", "MSG\t%u\tSOURCE\t%u\tSEQ\t%u\tMETRIC\t%u\n",
			num_received, call AMPacket.source(msg),
			routing_msg->seq_no, temp_cost); */
			if (routing_msg->seq_no < current_seq_no)
				return msg;
			if (routing_msg->seq_no > current_seq_no){
				current_seq_no = routing_msg->seq_no;
				current_parent = call AMPacket.source(msg);
				signal GraphConnection.parentUpdate(current_parent);
				current_cost = temp_cost;
				dbg("routing", "SET\tPARENT\t%u\tCOST\t%u\n", current_parent, current_cost);
				call TimerNotification.startOneShot(call Random.rand16()%500);
			} else {
				if (current_cost > temp_cost ||
					call AMPacket.source(msg) == current_parent){
					current_seq_no = routing_msg->seq_no;
					current_parent = call AMPacket.source(msg);
					parents[0].parent = current_parent;
					parents[0].metric = temp_cost;
					parents[0].forwarded = 11;
					signal GraphConnection.parentUpdate(current_parent);
					current_cost = temp_cost;
					//dbg("routing", "SET\tPARENT\t%u\tCOST\t%u\n", current_parent, current_cost);
					dbg("routing", "parent,cost,forw: %u,%u,%u\n",parents[0].parent,parents[0].metric,parents[0].forwarded);
					call TimerNotification.startOneShot(call Random.rand16()%500);
				}
			}
		}
		return msg;
	}
}

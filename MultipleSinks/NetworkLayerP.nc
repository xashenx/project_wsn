/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		NetworkLayerP.nc
 *	DESCRIPTION:	Network layer component
 *
 */

 #include <Timer.h>
 #include "RoutingMsg.h"

module NetworkLayerP{
	provides{
		interface NetworkToData;
		command uint16_t checkForParent(uint16_t parent);
	}
	uses{
		interface Timer<TMilli> as TimerRefresh;
		interface Timer<TMilli> as TimerNotification;
		interface Timer<TMilli> as TimerAlive;
		interface PacketAcknowledgements as Acks;
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
		interface Queue<RoutingMsg>;
		interface DataToNetwork;
		//interface NetworkInterfaces;
	}
}

implementation{
	// BEGIN TREE SECTION
	uint16_t current_parent;
	uint16_t parent_state;
	// END TREE SECTION
	message_t pkt;
	message_t alive;
	bool sending;
	uint16_t current_cost;
  	uint16_t current_seq_no;
	uint16_t next_parent;
	uint16_t num_received; // counter of received messages
	Parent parents[MAX_PARENTS]; // structure array of the parents of the node
	uint16_t active_parents; //counter of active parents
	uint16_t overload; // number of messages sent to the more ovearloaded node

	event void Boot.booted(){
		current_parent = TOS_NODE_ID;
		if(TOS_NODE_ID == 0 || TOS_NODE_ID == 6)
			current_cost = 0;
		else{
			current_cost = 999;
			next_parent = 0;
		}
		current_seq_no = 0;
		num_received = 0;
		parent_state = 999;
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err){
		if (err == SUCCESS){
				call TimerRefresh.startPeriodic(REFRESH_PERIOD);
		} else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err){}

	task void sendNotification(){
		RoutingMsg* msg = (RoutingMsg*) (call Packet.getPayload(&pkt,sizeof(RoutingMsg)));
		error_t error;
		msg->parent = current_parent;
		msg->seq_no = current_seq_no;
		msg->metric = current_cost;
		if ((error = call AMSend.send(AM_BROADCAST_ADDR, &pkt,
			sizeof(RoutingMsg))) == SUCCESS){
			call Leds.led2On();
			sending = TRUE;
		} else {
			dbg("routing", "\n\n\n\nERROR\t%u\n", error);
			call TimerNotification.startOneShot(call Random.rand16()%500);
		}
	}

	task void sendAlive(){
		AliveMsg* msg = (AliveMsg*)(call Packet.getPayload(&alive,sizeof(AliveMsg)));
		error_t error;
		msg->node = TOS_NODE_ID;
		call Acks.requestAck(&alive);
		if ((error = call AMSend.send(current_parent,&alive,sizeof(AliveMsg))) == SUCCESS){
			#ifdef RELIABILITY
				dbg("routing","sending alive to %u\n",current_parent);
			#endif
			call Leds.led2On();
			sending = TRUE;
		} else {
			dbg("routing", "\n\n\n\nERROR\t%u\n", error);
			call TimerAlive.startOneShot(call Random.rand16()%500);
		}
	}

	task void checkState(){
		switch(parent_state){
			case 2:
				// the parent has not sent the comunication once
				// let's give it another chance 
				parent_state--;
				break;
			case 1: // the link does not regularly respond
				// stop the data communications and send an Alive Message
				// to check if it is alive or mark as dead and change parent
				post sendAlive();
				signal NetworkToData.stopData();
				parent_state--;
				break;
			case 0: // the link to the parent is dead
				#ifdef RELIABILITY
					dbg("routing","No link to my parent\n");
				#endif
				current_cost = 999;
				break;
			default:
				parent_state--;
				break;
		}
	}

	command uint16_t checkForParent(uint16_t parent){
		uint16_t position = 0;
		bool found = FALSE;
		while (!found && position < active_parents){
			if(parents[position].id == parent)
				found = TRUE;
			position++;
		}
		if (found)
			return --position;
		return NOT_PARENT;
	}

	event void TimerRefresh.fired(){
		if(TOS_NODE_ID == 0 || TOS_NODE_ID == 6){
			if (!sending){
				current_seq_no++;
				#ifdef ROUTING
					dbg("routing","sending refresh with #%u\n",current_seq_no);
				#endif
				post sendNotification();
			}
		}else{
			post checkState();
		}
	}

	event void TimerNotification.fired(){
		if (!sending)
			post sendNotification();
	}

	event void TimerAlive.fired(){
		if (!sending)
			post sendAlive();
	}

	event void AMSend.sendDone(message_t* msg, error_t error){
		if (&pkt == msg && error == SUCCESS){
			sending = FALSE;
		}
		if(&alive == msg && error == SUCCESS){
			if(call Acks.wasAcked(msg)){
				#ifdef ROUTING
					dbg("routing","my Alive message was Acked!\n");
				#endif
				parent_state = 3;
			}else{
				// the link to the parent is probably down
				signal NetworkToData.stopData();
				current_seq_no--;
				current_cost = 999;
			}
		}
		else
			call TimerNotification.startOneShot(call Random.rand16()%500);
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		if (len == sizeof(RoutingMsg) && TOS_NODE_ID != 0 && TOS_NODE_ID != 6){
			RoutingMsg* routing_msg = (RoutingMsg*) payload;
			uint16_t temp_parent;
			uint16_t temp_seq_no;
			uint16_t temp_cost;
			uint16_t position;
			bool parent;
		#ifdef TOSSIM
			temp_cost = routing_msg->metric + 1;
			temp_parent = call AMPacket.source(msg);
			temp_seq_no = routing_msg->seq_no;
			//temp_cost = routing_msg->metric + (-1*call TossimPacket.strength(msg));
		#else        
			temp_cost = routing_msg->metric + call CC2420Packet.getLqi(msg);
		#endif
			num_received++;
			#ifdef SILLY
			dbg("routing","received message with #%u from %u(%u)\n",temp_seq_no,temp_parent,temp_cost);
			#endif
			position = call checkForParent(temp_parent);
			if(position != NOT_PARENT)
				parent = TRUE;
			else
				position = 0;

			if (temp_seq_no < current_seq_no)
				return msg;
			if (temp_seq_no > current_seq_no){
				if(current_cost == temp_cost){
					if(!parent && active_parents < MAX_PARENTS){
					// IF A NODE ARRIVES AS FIRST AND IS NOT AMONG THE
					// PARENTS, WE PUT IT INTO THE STRUCTURE, WITHOUT
					// RESETTING IT
						parents[active_parents].id = temp_parent;
						parents[active_parents].state = HEALTHY;
						parents[active_parents].forwarded = 0;
						active_parents++;
					}
				}else{
				// REACHING THE NODE AS FIRST WITH A SMALLER COST IS COMMON
				// BUT HERE EVEN A COMMUNICATION WITH A GREATER COST IT TAKEN
				// INTO CONSIDERATION, BECAUSE IF IT HAS ARRIVED AS FIRST,
				// MAYBE THE FORMER PARENTS ARE NOT ABLE TO COMMUNICATE ANYMORE
				//
				// SO IN BOTH CASES WE RESET THE STRUCTURE AND PUT THE NEW PARENT
					active_parents = 1;
					if(parent){
						parents[0].forwarded = parents[position].forwarded;
						overload = parents[position].forwarded;
					}
					else{
						parents[0].forwarded = 0;
						overload = 0;
					}
					parents[0].id = temp_parent;
					current_cost = temp_cost;
					parents[0].state = HEALTHY;
					signal NetworkToData.parentUpdate(temp_parent);
				}
				current_seq_no = temp_seq_no;
				current_cost = temp_cost;
				#ifdef ROUTING
				dbg("routing", "NEW\tSEQNO\t%u\tCOST\t%u{%u}\n",temp_parent,current_cost,position);
				#endif
				call TimerNotification.startOneShot(call Random.rand16()%500);
			} else {
				if (current_cost > temp_cost ||
					parent){
					if (parent && current_cost == temp_cost){
						// AN UPDATE FROM ONE OF OUR PARENT
						// WE CAN JUST DROP IT!
						#ifdef SILLY
							dbg("routing","USELESS\tUPDATE\t%u\n",current_parent);
						#endif
					}else {
						// WE HAVE A NEW MINIMUM COST, SO WE RESET THE STRUCTURE
						active_parents = 1;
						if (parent){
							current_cost = temp_cost;
							#ifdef ROUTING
							dbg("routing","PARENT\tUPDATE\t%u\tCOST\t%u(%u){%u}\n",current_parent,current_cost,parent_state,position);
							#endif
						}else{
							current_parent = temp_parent;
							//parents[0].cost = temp_cost;
							parents[0].forwarded = 0;
							parents[0].id = temp_parent;
							signal NetworkToData.parentUpdate(current_parent);
							current_cost = temp_cost;
							overload = 0;
							#ifdef ROUTING
							dbg("routing","SET\tPARENT\t%u\tCOST\t%u{%u}\n",current_parent,current_cost,position);
							#endif
						}
						parents[0].state = HEALTHY;
						call TimerNotification.startOneShot(call Random.rand16()%500);
					}
					parents[0].state = HEALTHY;
				}else if (current_cost == temp_cost){
					// IN THE GRAPH TOPOLOGY ROUTING WE WILL PUT AS PARENTS
					// NODES WITH THE SAME CURRENT_COST
					dbg("routing","CHECK\tPARENT\t%u\tSAME\t%u{%u}\n",temp_parent,temp_cost,position);
					/*if(TOS_NODE_ID==6 && temp_parent == 3){
						current_parent = temp_parent;
						signal NetworkToData.parentUpdate(current_parent);
					}*/
					if(active_parents<MAX_PARENTS){
						parents[active_parents].id = temp_parent;
						parents[active_parents].state = HEALTHY;
						parents[active_parents].forwarded = 0;
						active_parents++;
					}
				}
			}
		}
		#ifdef RELIABILITY
			else if(len == sizeof(AliveMsg))
				dbg("routing","Alive message received from %u!\n",call AMPacket.source(msg));
		#endif
		return msg;
	}

	event uint16_t DataToNetwork.nextParent(){
		uint16_t messages;
		next_parent = (uint16_t)(next_parent % active_parents);
		//dbg("routing","next %u active %u\n", next_parent,active_parents);
		if(active_parents > 1){
			uint16_t checked = 0;
			messages = parents[next_parent].forwarded;
			while(checked < active_parents && messages == overload){
			//while(checked < active_parents && (messages == overload || parents[next_parent].state == DEAD)){
				next_parent = (++next_parent % active_parents);
				messages = parents[next_parent].forwarded;
				checked++;
			}
		}
		#ifdef SILLY
			dbg("routing","SENDING\tPARENT\t%u\n",parents[0].id);
		#endif
		return parents[next_parent++].id;
	}

	event void DataToNetwork.removeParent(uint16_t parent){
		uint16_t result = call checkForParent(parent);
		if(result != NOT_PARENT){
			//dbg("routing","REMOVING\tPARENT\t%u[result:%u]\n",parent,result);
			if(active_parents == 1)
				signal NetworkToData.stopData();
			else if(active_parents == (result)+1){
				//dbg("routing","basta cancellare\n");
				active_parents--;
			}
			else if(active_parents > 1){
				//dbg("routing","metto %u in %u\n",parents[active_parents-1].id,parents[result].id);
				//dbg("routing","metto %u in %u\n",parents[active_parents-1].state,parents[result].state);
				//dbg("routing","metto %u in %u\n",parents[active_parents-1].forwarded,parents[result].forwarded);
				parents[result].id = parents[active_parents-1].id;
				parents[result].forwarded = parents[active_parents-1].forwarded;
				parents[result].state = parents[active_parents-1].state;
				active_parents--;
			}
			/*while(result+1 < active_parents){
				dbg("routing","%u - %u\n",parents[result].forwarded,overload);
				parents[result].id = parents[result+1].id;
				parents[result].state = parents[result+1].state;
				parents[result].forwarded = parents[result+1].forwarded;
				result++;
			}*/
		}else
			dbg("data","ERROR\tNO\tPARENT\tFOUND\n");
		//dbg("routing","prossimo parent: %u\n",signal DataToNetwork.nextParent());
	}

	event void DataToNetwork.messageForwarded(uint16_t parent){
		uint16_t messages;
		uint16_t result = call checkForParent(parent);
		if(result != NOT_PARENT){
			messages = ++parents[result].forwarded;
			if(messages > overload)
				overload = messages;
			//#ifdef ROUTING
			dbg("routing","MESSAGE\tFORWARDED\tTO\t%u:\t%u\n",parents[result].id,parents[result].forwarded);
			//#endif
			//parents[result].forwarded += 1;
		}
		else
			dbg("data","ERROR\tNO\tPARENT\tFOUND\n");
	}
}

/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		RoutingMsg.h
 *	DESCRIPTION:	Parameters and structures used for the routing
 *
 */

#ifndef ROUTMSG_H
#define ROUTMSG_H

enum
{
	AM_GRAPHBUILDING = 33,
	//SINK_REFRESH_PERIOD = 10000, // 10 seconds
	//RANDOM_MAX = 500,
	SINK_REFRESH_PERIOD = 300000, // 5 minutes
	RANDOM_MAX = 3500,
	#ifdef REFRESH
	REFRESH_PERIOD = 10000,
	#endif
//	REFRESH_PERIOD = 300000,
	ALIVE_PERIOD = 1000,
	MAX_PARENTS = 10,
	HEALTHY = 3,
	WARNING = 2,
	STOP = 1,
	DEAD = 0,
	NOT_PARENT = 99,
// CODE OF GENERIC MESSAGES
	#ifdef REMOVEPARENT
	NO_PARENT_MSG = 0,
	#ifdef REBUILDMSG
	ROR_MSG = 1,
	#endif
	#endif
};
//nx_uint16_t forwarded; // messages forwarded from the node (hop-count)
typedef nx_struct RoutingMsg{
	nx_uint16_t seq_no;
	nx_uint16_t metric; // from the node to the sink (hop-count)
	#ifdef BUFFER_METRIC
	nx_uint16_t buffer; // actual usage of the buffer
	#endif
	#ifdef TRAFFIC_METRIC
	nx_uint16_t traffic; // traffic on the node
	#endif
} RoutingMsg;
#ifdef ALIVE
typedef nx_struct AliveMsg{
	nx_uint16_t node;
} AliveMsg;
#endif
typedef nx_struct GenericMsg{
	nx_uint16_t code;
	/*
	 *	0: the sending node has no parents, so force the others to remove him
	 */
} GenericMsg;

typedef nx_struct Parent{
	nx_uint16_t id;	// Node ID of the parent
	nx_uint16_t forwarded; // messages forwarded from the parent
	#ifdef BUFFER_METRIC
	nx_uint16_t buffer; // buffer usage of the parent @ last beacon
	#endif
	#ifdef TRAFFIC_METRIC
	nx_uint16_t traffic; // traffic on the parent @ last beacon
	#endif
	#ifdef ALIVE
	/*
	*	state of the link to the parent
	*	3: the link is ALIVE
	*	2: the link is on YELLOW ALERT, the data layer will still try to send DataMsg
	*	1: the link is on RED ALERT, the data layer will send an AliveMsg instead of a DataMsg
	*	0: the link is DEAD, then it can be substituted
	*/
	nx_uint16_t state; 
	#endif
} Parent;
#endif

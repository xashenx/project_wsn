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
	REFRESH_PERIOD = 10000,
	ALIVE_PERIOD = 1000,
	MAX_PARENTS = 5,
	HEALTHY = 3,
	WARNING = 2,
	STOP = 1,
	DEAD = 0,
	NOT_PARENT = 99,
};

typedef nx_struct RoutingMsg{
	nx_uint16_t parent; // node id of the parent
	nx_uint16_t seq_no;
	nx_uint16_t metric; // from the node to the sink
	nx_uint16_t forwarded; // messages forwarded from the node
} RoutingMsg;

typedef nx_struct AliveMsg{
	nx_uint16_t node;
} AliveMsg;

typedef nx_struct Parent{
	nx_uint16_t id;
	nx_uint16_t forwarded; // messages forwarded from the parent
	/*
	*	state of the link to the parent
	*	3: the link is ALIVE
	*	2: the link is on YELLOW ALERT, the data layer will still try to send DataMsg
	*	1: the link is on RED ALERT, the data layer will send an AliveMsg instead of a DataMsg
	*	0: the link is DEAD, then it can be substituted
	*/
	nx_uint16_t state; 
} Parent;
#endif

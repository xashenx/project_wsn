/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		DataMsg.h
 *	DESCRIPTION:	Parameters and structure of the data messages 
 *
 */

 #ifndef DATAMSG_H
 #define DATAMSG_H

enum
{
  AM_DATAMSG = 22,
  SEND_PERIOD = 5000,// 5 seconds
  MESSAGE_PERIOD = 10500,// 10.5 seconds
/*  SEND_PERIOD = 1000,
  MESSAGE_PERIOD = 3500,*/
};

typedef nx_struct DataMsg{
	nx_uint16_t msg_id; // id number of the message
	nx_uint16_t data;
	nx_uint16_t hops; // number of hops performed through the network
} DataMsg;

#endif

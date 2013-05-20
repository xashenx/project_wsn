 /*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		DataCollectionC.nc
 *	DESCRIPTION:	Data layer configuration 
 *
 */
 #include "DataMsg.h"

configuration DataCollectionC
{
	provides interface DataToRouting;
}
implementation
{
	components DataCollectionP;
	components MainC, GraphRoutingC, ActiveMessageC, LedsC;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components new AMSenderC(AM_DATAMSG);
	components new AMReceiverC(AM_DATAMSG);
	components RandomC;
	components new QueueC(DataMsg, 12) as DataQueue;

	DataToRouting = DataCollectionP;
	DataCollectionP.Boot -> MainC.Boot;
	DataCollectionP.TimerSend -> Timer0;
	DataCollectionP.TimerMessage -> Timer1;
	DataCollectionP.Leds -> LedsC;
	DataCollectionP.Packet -> AMSenderC;
	DataCollectionP.AMPacket -> ActiveMessageC;
	DataCollectionP.AMSend -> AMSenderC;
	DataCollectionP.AMControl -> ActiveMessageC;
	DataCollectionP.Receive -> AMReceiverC;
	DataCollectionP.Random -> RandomC;
	DataCollectionP.RoutingToData -> GraphRoutingC;
	DataCollectionP.Queue -> DataQueue;
	DataCollectionP.Acks -> ActiveMessageC;
}


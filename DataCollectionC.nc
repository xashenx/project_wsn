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
}
implementation
{
  components DataCollectionP;
  components MainC, GraphRoutingC, ActiveMessageC, LedsC;
  components new TimerMilliC() as Timer0;
  components new AMSenderC(AM_DATAMSG);
  components new AMReceiverC(AM_DATAMSG);
  components RandomC;
  components new QueueC(DataMsg, 12) as DataQueue;

  DataCollectionP.Boot -> MainC.Boot;
  DataCollectionP.TimerApp -> Timer0;
  DataCollectionP.Leds -> LedsC;
  DataCollectionP.Packet -> AMSenderC;
  DataCollectionP.AMPacket -> ActiveMessageC;
  DataCollectionP.AMSend -> AMSenderC;
  DataCollectionP.AMControl -> ActiveMessageC;
  DataCollectionP.Receive -> AMReceiverC;
  DataCollectionP.Random -> RandomC;
  DataCollectionP.GraphConnection -> GraphRoutingC;
  DataCollectionP.Queue -> DataQueue;
  DataCollectionP.Acks -> ActiveMessageC;
}


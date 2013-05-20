/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		GraphRoutingC.nc
 *	DESCRIPTION:	Network layer configuration
 *
 */

 #include "RoutingMsg.h" 

configuration GraphRoutingC
{
	provides interface RoutingToData;
}
implementation
{
	components MainC, GraphRoutingP, ActiveMessageC, LedsC;
	components DataCollectionC;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components new TimerMilliC()  as Timer2;
	components new AMSenderC(AM_GRAPHBUILDING);
	components new AMReceiverC(AM_GRAPHBUILDING);
	components RandomC;
	components new QueueC(RoutingMsg, 12) as RoutingQueue;
#ifdef TOSSIM
	components TossimActiveMessageC;
	GraphRoutingP.TossimPacket -> TossimActiveMessageC;
#else
	components CC2420PacketC;
	GraphRoutingP.CC2420Packet -> CC2420PacketC;
#endif
  
	RoutingToData = GraphRoutingP;
	GraphRoutingP -> MainC.Boot;
	GraphRoutingP.TimerNotification -> Timer0;
	GraphRoutingP.TimerRefresh -> Timer1;
	GraphRoutingP.TimerSend -> Timer2;
	GraphRoutingP.Leds -> LedsC;
	GraphRoutingP.Packet -> AMSenderC;
	GraphRoutingP.AMPacket -> ActiveMessageC;
	GraphRoutingP.AMSend -> AMSenderC;
	GraphRoutingP.AMControl -> ActiveMessageC;
	GraphRoutingP.Receive -> AMReceiverC;
	GraphRoutingP.Random -> RandomC;
	GraphRoutingP.Queue -> RoutingQueue;
	GraphRoutingP.DataToRouting -> DataCollectionC;
}


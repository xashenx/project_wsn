/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		NetworkLayerC.nc
 *	DESCRIPTION:	Network layer configuration
 *
 */

 #include "RoutingMsg.h" 

configuration NetworkLayerC
{
	provides interface NetworkToData;
}
implementation
{
	components MainC, NetworkLayerP, ActiveMessageC, LedsC;
	components DataLayerC;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components new TimerMilliC()  as Timer2;
	components new AMSenderC(AM_GRAPHBUILDING);
	components new AMReceiverC(AM_GRAPHBUILDING);
	components RandomC;
	components new QueueC(RoutingMsg, 12) as RoutingQueue;
#ifdef TOSSIM
	components TossimActiveMessageC;
	NetworkLayerP.TossimPacket -> TossimActiveMessageC;
#else
	components CC2420PacketC;
	NetworkLayerP.CC2420Packet -> CC2420PacketC;
#endif
  
	NetworkToData = NetworkLayerP;
	NetworkLayerP -> MainC.Boot;
	NetworkLayerP.TimerNotification -> Timer0;
	NetworkLayerP.TimerRefresh -> Timer1;
	NetworkLayerP.TimerAlive -> Timer2;
	NetworkLayerP.Leds -> LedsC;
	NetworkLayerP.Packet -> AMSenderC;
	NetworkLayerP.AMPacket -> ActiveMessageC;
	NetworkLayerP.AMSend -> AMSenderC;
	NetworkLayerP.AMControl -> ActiveMessageC;
	NetworkLayerP.Receive -> AMReceiverC;
	NetworkLayerP.Random -> RandomC;
	NetworkLayerP.Queue -> RoutingQueue;
	NetworkLayerP.DataToNetwork -> DataLayerC;
	NetworkLayerP.Acks -> ActiveMessageC;
}


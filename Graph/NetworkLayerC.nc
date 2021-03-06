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
	provides command uint16_t checkForParent(uint16_t parent);
	provides command void removeParentC(uint16_t position);
}
implementation
{
	components MainC, NetworkLayerP, ActiveMessageC, LedsC;
	components DataLayerC;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
#ifdef ALIVE
	components new TimerMilliC() as Timer2;
#endif
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
  	checkForParent = NetworkLayerP.checkForParent;
	removeParentC = NetworkLayerP.removeParentC;
	NetworkToData = NetworkLayerP;
	NetworkLayerP -> MainC.Boot;
	NetworkLayerP.TimerNotification -> Timer0;
	NetworkLayerP.TimerRefresh -> Timer1;
#ifdef ALIVE
	NetworkLayerP.TimerAlive -> Timer2;
#endif
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


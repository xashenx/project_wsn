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
  provides interface GraphConnection;
}
implementation
{
  components MainC, GraphRoutingP, ActiveMessageC, LedsC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new AMSenderC(AM_GRAPHBUILDING);
  components new AMReceiverC(AM_GRAPHBUILDING);
  components RandomC;
#ifdef TOSSIM
	components TossimActiveMessageC;
	GraphRoutingP.TossimPacket -> TossimActiveMessageC;
#else
  components CC2420PacketC;
  GraphRoutingP.CC2420Packet -> CC2420PacketC;
#endif
  
  GraphConnection = GraphRoutingP;

  GraphRoutingP -> MainC.Boot;
  GraphRoutingP.TimerNotification -> Timer0;
  GraphRoutingP.TimerRefresh -> Timer1;
  GraphRoutingP.Leds -> LedsC;
  GraphRoutingP.Packet -> AMSenderC;
  GraphRoutingP.AMPacket -> ActiveMessageC;
  GraphRoutingP.AMSend -> AMSenderC;
  GraphRoutingP.AMControl -> ActiveMessageC;
  GraphRoutingP.Receive -> AMReceiverC;
  GraphRoutingP.Random -> RandomC;
}


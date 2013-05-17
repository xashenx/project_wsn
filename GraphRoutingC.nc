 #include "TreeBuilding.h"

configuration TreeRoutingC
{
  provides interface TreeConnection;
}
implementation
{
  components MainC, TreeRoutingP, ActiveMessageC, LedsC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new AMSenderC(AM_TREEBUILDING);
  components new AMReceiverC(AM_TREEBUILDING);
  components RandomC;
#ifdef TOSSIM
  	components new DemoSensorC() as ReadVoltage;
	components TossimActiveMessageC;
	TreeRoutingP.TossimPacket -> TossimActiveMessageC;
#else
  components new VoltageC() as ReadVoltage;
  components CC2420PacketC;
  TreeRoutingP.CC2420Packet -> CC2420PacketC;
#endif
  
  TreeConnection = TreeRoutingP;

  TreeRoutingP -> MainC.Boot;
  TreeRoutingP.TimerNotification -> Timer0;
  TreeRoutingP.TimerRefresh -> Timer1;
  TreeRoutingP.Leds -> LedsC;
  TreeRoutingP.Packet -> AMSenderC;
  TreeRoutingP.AMPacket -> ActiveMessageC;
  TreeRoutingP.AMSend -> AMSenderC;
  TreeRoutingP.AMControl -> ActiveMessageC;
  TreeRoutingP.Receive -> AMReceiverC;
  TreeRoutingP.Voltage -> ReadVoltage;
  TreeRoutingP.Random -> RandomC;
}


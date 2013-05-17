#include "DataMsg.h"

configuration DataCollectionC
{
}
implementation
{
  components DataCollectionP;
  components MainC, TreeRoutingC, ActiveMessageC, LedsC;
  components new TimerMilliC() as Timer0;
  components new AMSenderC(AM_DATAMSG);
  components new AMReceiverC(AM_DATAMSG);
  components RandomC;
  components new QueueC(DataMsg, 12);

  DataCollectionP.Boot -> MainC.Boot;
  DataCollectionP.TimerApp -> Timer0;
  DataCollectionP.Leds -> LedsC;
  DataCollectionP.Packet -> AMSenderC;
  DataCollectionP.AMPacket -> ActiveMessageC;
  DataCollectionP.AMSend -> AMSenderC;
  DataCollectionP.AMControl -> ActiveMessageC;
  DataCollectionP.Receive -> AMReceiverC;
  DataCollectionP.Random -> RandomC;
  DataCollectionP.TreeConnection -> TreeRoutingC;
  DataCollectionP.Queue -> QueueC;
  DataCollectionP.Acks -> ActiveMessageC;
}


 /*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		DataLayerC.nc
 *	DESCRIPTION:	Data layer configuration 
 *
 */
 #include "DataMsg.h"

configuration DataLayerC
{
	provides interface DataToNetwork;
}
implementation
{
	components DataLayerP;
	components MainC, NetworkLayerC, ActiveMessageC, LedsC;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components new AMSenderC(AM_DATAMSG);
	components new AMReceiverC(AM_DATAMSG);
	components RandomC;
	components new QueueC(DataMsg, 12) as DataQueue;

	DataToNetwork = DataLayerP;
	DataLayerP.Boot -> MainC.Boot;
	DataLayerP.TimerSend -> Timer0;
	DataLayerP.TimerMessage -> Timer1;
	DataLayerP.Leds -> LedsC;
	DataLayerP.Packet -> AMSenderC;
	DataLayerP.AMPacket -> ActiveMessageC;
	DataLayerP.AMSend -> AMSenderC;
	DataLayerP.AMControl -> ActiveMessageC;
	DataLayerP.Receive -> AMReceiverC;
	DataLayerP.Random -> RandomC;
	DataLayerP.NetworkToData -> NetworkLayerC;
	DataLayerP.Queue -> DataQueue;
	DataLayerP.Acks -> ActiveMessageC;
}


/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		.nc
 *	DESCRIPTION:	Function calls from network to data layer 
 *
 */

interface RoutingToData {

  /* Notifies the update of the parent or the availability of a new parent */
	event void parentUpdate(uint16_t parent);
	// Routing layer asks to the data one if it can send
	event bool sendRequest(uint16_t mode);

}

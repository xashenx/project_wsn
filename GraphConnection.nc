/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		GraphConnection.nc
 *	DESCRIPTION:	Connection between network and data layers 
 *
 */

interface GraphConnection {

  /* Notifies the update of the parent or the availability of a new parent */
  event void parentUpdate(uint16_t parent);

}

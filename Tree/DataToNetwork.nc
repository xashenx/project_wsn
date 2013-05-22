/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		DataToNetwork.nc
 *	DESCRIPTION:	Function calls from data to network layer 
 *
 */

interface DataToNetwork {

	/*
	 * The data layer asks to the network if it can
	 */
	event uint16_t nextParent();

}

/*
 *
 *	AUTHOR: 	FABRIZIO ZENI
 *	STUDENT ID:	153465
 *	FILE:		DataToNetwork.nc
 *	DESCRIPTION:	Events signalled from data to network layer 
 *
 */

interface DataToNetwork {

	/*
	 * The data layer asks to the network if it can
	 */
	event uint16_t nextParent();
	/*
	 * The data layer asks to the network if the parent
	 * is still alive
	 */
	event void messageForwarded(uint16_t);
#ifdef REMOVEPARENT
	event void removeParent(uint16_t);
#endif
}

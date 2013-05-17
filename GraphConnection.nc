interface TreeConnection {

  /* Notifies the update of the parent or the availability of a new parent */
  event void parentUpdate(uint16_t parent);

}

#ifndef DATAMSG_H
#define DATAMSG_H

enum
{
  AM_DATAMSG = 22,
  APP_PERIOD = 1000,
};

typedef nx_struct DataMsg{
	nx_uint16_t data;
} DataMsg;

#endif

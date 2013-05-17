#ifndef GRAPHBUILDING_H
#define GRAPHBUILDING_H

enum
{
  AM_GRAPHBUILDING = 33,
  REFRESH_PERIOD = 1000,
};

typedef nx_struct GraphBuilding
{
  nx_uint16_t seq_no;
  nx_uint16_t metric;
} GraphBuilding;

#endif

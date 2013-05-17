#ifndef TREEBUILDING_H
#define TREEBUILDING_H

enum
{
  AM_TREEBUILDING = 33,
  REFRESH_PERIOD = 1000,
};

typedef nx_struct TreeBuilding
{
  nx_uint16_t seq_no;
  nx_uint16_t metric;
} TreeBuilding;

#endif

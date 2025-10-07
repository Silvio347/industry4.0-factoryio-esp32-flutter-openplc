#pragma once
#include <Arduino.h>

inline int toIntSafe(const char* s, size_t n) {
  char buf[24];
  n = min(n, sizeof(buf)-1);
  memcpy(buf, s, n);
  buf[n] = 0;
  return atoi(buf);
}

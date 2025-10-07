#pragma once
#include <Arduino.h>

bool mbEnsureConnected();
bool mbWriteCoil(uint16_t addr, bool v);
bool mbWriteHreg(uint16_t addr, uint16_t v);
bool mbReadCoil1(uint16_t addr, bool *outBit);
bool mbReadHreg(uint16_t addr, uint16_t *out);
bool mbReadIreg(uint16_t addr, uint16_t *out);
bool mbWriteHregF32(uint16_t addr, float v);
bool mbReadHregF32(uint16_t addr, float *out);

// INT32 two words (LO/HI)
bool mbWriteHregS32(uint16_t addr_lo, int32_t v);
bool mbReadHregS32(uint16_t addr_lo, int32_t *out);
bool mbReadIregS32(uint16_t addr_lo, int32_t *out);

// --- Helpers 1e4 scale ---
static inline int32_t f_to_s32_1e4(float f)
{
  double x = (double)f * 10000.0;
  if (x > 2147483647.0)
    x = 2147483647.0;
  if (x < -2147483648.0)
    x = -2147483648.0;
  long long r = llround(x);
  if (r > 2147483647LL)
    r = 2147483647LL;
  if (r < -2147483648LL)
    r = -2147483648LL;
  return (int32_t)r;
}

static inline float s32_to_f_1e4(int32_t v)
{
  return ((float)v) / 10000.0f;
}
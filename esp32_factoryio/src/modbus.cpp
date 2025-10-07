#include <ModbusTCPClient.h>
#include "config.hpp"
#include "state.hpp"
#include <modbus.hpp>

static WiFiClient s_mbNet;
static ModbusTCPClient s_mb(s_mbNet);

bool mbEnsureConnected()
{
  static uint32_t lastTry = 0;
  if (s_mb.connected())
    return true;
  if (millis() - lastTry < 1000)
    return false;
  lastTry = millis();

  if (s_mb.begin(CFG::PLC_IP, CFG::PLC_PORT))
  {
    Serial.println("[Modbus] Conectado");
    return true;
  }
  Serial.println("[Modbus] Falha conectar");
  return false;
}

bool mbWriteCoil(uint16_t addr, bool v)
{
  if (!mbEnsureConnected())
    return false;
  return s_mb.coilWrite(addr, v);
}

bool mbWriteHreg(uint16_t addr, uint16_t v)
{
  if (!mbEnsureConnected())
    return false;
  return s_mb.holdingRegisterWrite(addr, v);
}

bool mbReadCoil1(uint16_t addr, bool *out)
{
  if (!mbEnsureConnected())
    return false;
  int r = s_mb.coilRead(addr);
  if (r < 0)
    return false;
  *out = (r != 0);
  return true;
}

bool mbReadHreg(uint16_t addr, uint16_t *out)
{
  if (!mbEnsureConnected())
    return false;
  int r = s_mb.holdingRegisterRead(addr);
  if (r < 0)
    return false;
  *out = (uint16_t)r;
  return true;
}

bool mbReadIreg(uint16_t addr, uint16_t *out)
{
  if (!mbEnsureConnected())
    return false;
  int r = s_mb.inputRegisterRead(addr);
  if (r < 0)
    return false;
  *out = (uint16_t)r;
  return true;
}

// float (hi + lo)
static void f32_to_u16be(float f, uint16_t *hi, uint16_t *lo)
{
  union
  {
    float f;
    uint32_t u;
  } u;
  u.f = f;
  *hi = (uint16_t)((u.u >> 16) & 0xFFFF);
  *lo = (uint16_t)(u.u & 0xFFFF);
}

static float u16be_to_f32(uint16_t hi, uint16_t lo)
{
  union
  {
    float f;
    uint32_t u;
  } u;
  u.u = ((uint32_t)hi << 16) | (uint32_t)lo;
  return u.f;
}

static void f32_to_words_openplc(float f, uint16_t *lo, uint16_t *hi)
{
  union
  {
    float f;
    uint32_t u;
  } u;
  u.f = f;
  *lo = (uint16_t)(u.u & 0xFFFF);         // LOW word
  *hi = (uint16_t)((u.u >> 16) & 0xFFFF); // HIGH word
}

static float words_to_f32_openplc(uint16_t lo, uint16_t hi)
{
  union
  {
    float f;
    uint32_t u;
  } u;
  u.u = ((uint32_t)hi << 16) | (uint32_t)lo; // HI:LO
  return u.f;
}

bool mbWriteHregF32(uint16_t addr, float v)
{
  if (!mbEnsureConnected())
    return false;
  uint16_t lo, hi;
  f32_to_words_openplc(v, &lo, &hi);
  bool ok1 = s_mb.holdingRegisterWrite(addr, lo);     // LOW addr
  bool ok2 = s_mb.holdingRegisterWrite(addr + 1, hi); // HIGH addr+1
  return ok1 && ok2;
}

bool mbReadHregF32(uint16_t addr, float *out)
{
  if (!mbEnsureConnected())
    return false;
  int lo = s_mb.holdingRegisterRead(addr);     // LOW addr
  int hi = s_mb.holdingRegisterRead(addr + 1); // HIGH addr+1
  if (lo < 0 || hi < 0)
    return false;
  *out = words_to_f32_openplc((uint16_t)lo, (uint16_t)hi);
  return true;
}

// INT16 (convert to uint16_t for Modbus)
bool mbWriteHregI16(uint16_t addr, int16_t v)
{
  if (!mbEnsureConnected())
    return false;
  return s_mb.holdingRegisterWrite(addr, (uint16_t)v);
}

bool mbReadHregI16(uint16_t addr, int16_t *out)
{
  if (!mbEnsureConnected())
    return false;
  int r = s_mb.holdingRegisterRead(addr);
  if (r < 0)
    return false;
  *out = (int16_t)(uint16_t)r;
  return true;
}

// DINT (assigned) LO/HI
static inline void s32_to_words(int32_t v, uint16_t *lo, uint16_t *hi)
{
  uint32_t u = (uint32_t)v; // 2's complement
  *lo = (uint16_t)(u & 0xFFFF);
  *hi = (uint16_t)(u >> 16);
}
static inline int32_t words_to_s32(uint16_t lo, uint16_t hi)
{
  uint32_t u = ((uint32_t)hi << 16) | lo;
  return (int32_t)u;
}

bool mbWriteHregS32(uint16_t addr_lo, int32_t v)
{
  if (!mbEnsureConnected())
    return false;
  uint16_t lo, hi;
  s32_to_words(v, &lo, &hi);
  bool ok1 = s_mb.holdingRegisterWrite(addr_lo, lo);
  bool ok2 = s_mb.holdingRegisterWrite(addr_lo + 1, hi);
  return ok1 && ok2;
}

bool mbReadHregS32(uint16_t addr_lo, int32_t *out)
{
  if (!mbEnsureConnected())
    return false;
  int lo = s_mb.holdingRegisterRead(addr_lo);
  int hi = s_mb.holdingRegisterRead(addr_lo + 1);
  if (lo < 0 || hi < 0)
    return false;
  *out = words_to_s32((uint16_t)lo, (uint16_t)hi);
  return true;
}

bool mbReadIregS32(uint16_t addr_lo, int32_t *out)
{
  if (!mbEnsureConnected())
    return false;
  int lo = s_mb.inputRegisterRead(addr_lo);
  int hi = s_mb.inputRegisterRead(addr_lo + 1);
  if (lo < 0 || hi < 0)
    return false;
  *out = words_to_s32((uint16_t)lo, (uint16_t)hi);
  return true;
}

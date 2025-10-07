#pragma once
#include <Arduino.h>

struct deviceState {
  uint16_t pv_p100 = 0;
  uint16_t sp_p100 = 6000;
  uint16_t u_p100  = 0;
  uint16_t mode    = 1; // 0=Manual,1=Auto
  bool filling     = false;
  bool discharging = false;
  uint16_t display = 0;
  float kp, ki, kd;
};

extern deviceState g_state;

// commands to Modbus task
enum class MBWriteKind : uint8_t { COIL, HREG };
struct MBWriteCmd { MBWriteKind kind; uint16_t address; uint16_t value; };
extern QueueHandle_t g_qMbWrites;

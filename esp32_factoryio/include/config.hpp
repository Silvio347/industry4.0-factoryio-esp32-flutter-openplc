#pragma once
#include <Arduino.h>
#include <WiFi.h>

namespace CFG
{
  // WiFi
  inline constexpr char WIFI_SSID[] = "ssid";
  inline constexpr char WIFI_PASS[] = "pwd";

  // MQTT
  inline IPAddress MQTT_HOST(192, 168, 1, 23);
  inline constexpr uint16_t MQTT_PORT = 1883;
  inline constexpr uint16_t KEEPALIVE_S = 30;
  inline constexpr uint8_t MQTT_QOS = 1;
  inline const char *MQTT_USER = "";
  inline const char *MQTT_PASS = "";

  inline String BASE_TOPIC = "cell1";

  // PLC (Modbus TCP)
  inline IPAddress PLC_IP(192, 168, 1, 23);
  inline constexpr uint16_t PLC_PORT = 503;
  inline constexpr uint8_t PLC_UNIT_ID = 1;

  // Watchdog
  inline constexpr int WDT_TIMEOUT_S = 8;

  // Polling
  inline constexpr uint32_t POLL_MS = 1000;

  // COILS (%QX100.x)
  inline constexpr uint16_t COIL_HMI_FILL_CMD = 802;
  inline constexpr uint16_t COIL_HMI_DIS_CMD = 803;
  inline constexpr uint16_t COIL_Q_FILL = 804;      // %QX100.4  -> Filling
  inline constexpr uint16_t COIL_Q_DISCHARGE = 805; // %QX100.5  -> Discharging
  inline constexpr uint16_t COIL_MODE_AUTO = 806;   // %QX100.6  -> AutoMode

  inline constexpr uint16_t HR_KP_F32 = 200; // %QW200/201 (2 words)
  inline constexpr uint16_t HR_KI_F32 = 202; // %QW202/203
  inline constexpr uint16_t HR_KD_F32 = 204; // %QW204/205

  // INPUT REGISTERS (%IW…)
  inline constexpr uint16_t IR_DISPLAY_15B = 65535;
  inline constexpr uint16_t HR_SP_F32 = 65535;      // REAL %MD
  inline constexpr uint16_t HR_PV_F32 = 65535;      // idem

  // Gains (1e4 scale) two words LO/HI
  inline constexpr uint16_t HR_KP_LO = 200; // %QW200
  inline constexpr uint16_t HR_KP_HI = 201; // %QW201
  inline constexpr uint16_t HR_KI_LO = 202; // %QW202
  inline constexpr uint16_t HR_KI_HI = 203; // %QW203
  inline constexpr uint16_t HR_KD_LO = 204; // %QW204
  inline constexpr uint16_t HR_KD_HI = 205; // %QW205

  inline constexpr uint16_t HR_PV_LO = 206; // %QW206  (PV -> HMI)
  inline constexpr uint16_t HR_SP_LO = 208; // %QW208  (HMI -> SP)

  inline constexpr uint16_t IR_PV_P100 = 65535;
  inline constexpr uint16_t HR_SP_P100 = 65535;
}

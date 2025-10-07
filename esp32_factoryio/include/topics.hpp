#pragma once
#include <Arduino.h>
#include "config.hpp"

inline String tStateFill() { return CFG::BASE_TOPIC + "/state/Q_FillValve"; }
inline String tStateDischarge() { return CFG::BASE_TOPIC + "/state/Q_DischargeValve"; }
inline String tStateDisplay() { return CFG::BASE_TOPIC + "/state/Q_Display"; }
inline String tTelePV() { return CFG::BASE_TOPIC + "/tele/PV"; }
inline String tTeleSP() { return CFG::BASE_TOPIC + "/tele/SP"; }
inline String tTeleU() { return CFG::BASE_TOPIC + "/tele/U"; }
inline String tTeleKp() { return CFG::BASE_TOPIC + "/tele/PID/Kp"; }
inline String tTeleKi() { return CFG::BASE_TOPIC + "/tele/PID/Ki"; }
inline String tTeleKd() { return CFG::BASE_TOPIC + "/tele/PID/Kd"; }
inline String tTeleMode() { return CFG::BASE_TOPIC + "/tele/Mode"; }
inline String tTelePreset() { return CFG::BASE_TOPIC + "/tele/Preset"; }
inline String tEspStatus() { return CFG::BASE_TOPIC + "/status/esp"; }
inline String tTeleUptime() { return CFG::BASE_TOPIC + "/tele/uptime"; }
inline String tCmdSP() { return CFG::BASE_TOPIC + "/cmd/SP"; }
inline String tCmdMode() { return CFG::BASE_TOPIC + "/cmd/Mode"; }
inline String tCmdPreset() { return CFG::BASE_TOPIC + "/cmd/Preset"; }
inline String tCmdFillValve() { return CFG::BASE_TOPIC + "/cmd/Q_FillValve"; }
inline String tCmdDischargeValve() { return CFG::BASE_TOPIC + "/cmd/Q_DischargeValve"; }
inline String tCmdSync() { return CFG::BASE_TOPIC + "/cmd/Sync"; }
inline String tCmdKp() { return CFG::BASE_TOPIC + "/cmd/PID/Kp"; }
inline String tCmdKi() { return CFG::BASE_TOPIC + "/cmd/PID/Ki"; }
inline String tCmdKd() { return CFG::BASE_TOPIC + "/cmd/PID/Kd"; }

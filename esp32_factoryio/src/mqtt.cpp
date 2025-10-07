#include <WiFi.h>
#include <PubSubClient.h>
#include "config.hpp"
#include "topics.hpp"
#include "state.hpp"
#include "utils.hpp"
#include <mqtt.hpp>
#include "modbus.hpp"

static WiFiClient s_wifiClient;
static PubSubClient s_mqtt(s_wifiClient);

static void onMqttMessage(char *topic, byte *payload, unsigned int len);
static void mqttSubscribeAll();

// API pública
void mqttInit()
{
  s_mqtt.setServer(CFG::MQTT_HOST, CFG::MQTT_PORT);
  s_mqtt.setKeepAlive(CFG::KEEPALIVE_S);
  s_mqtt.setCallback(onMqttMessage);
}

bool mqttConnected() { return s_mqtt.connected(); }
void mqttLoop() { s_mqtt.loop(); }

void mqttPublishKV(const String &topic, const String &payload, bool retained)
{
  s_mqtt.publish(topic.c_str(), payload.c_str(), retained);
  // Serial.printf("[MQTT→] %s = %s (retained=%d)\n", topic.c_str(), payload.c_str(), retained);
}

void mqttPublishSnapshot(bool retained)
{
  extern deviceState g_state;
  mqttPublishKV(tTeleMode(), String(g_state.mode), retained);
  mqttPublishKV(tTeleSP(), String(g_state.sp_p100), retained);
  mqttPublishKV(tTeleU(), String(g_state.u_p100), false);
  mqttPublishKV(tStateFill(), g_state.filling ? "1" : "0", false);
  mqttPublishKV(tStateDischarge(), g_state.discharging ? "1" : "0", false);
  readPidFromPlcAndPublish();
}

void readPidFromPlcAndPublish()
{
  int32_t s32;
  if (mbEnsureConnected())
  {
    if (mbReadHregS32(CFG::HR_KP_LO, &s32))
    {
      g_state.kp = s32_to_f_1e4(s32);
      mqttPublishKV(tTeleKp(), String(g_state.kp, 4), true);
    }
    if (mbReadHregS32(CFG::HR_KI_LO, &s32))
    {
      g_state.ki = s32_to_f_1e4(s32);
      mqttPublishKV(tTeleKi(), String(g_state.ki, 4), true);
    }
    if (mbReadHregS32(CFG::HR_KD_LO, &s32))
    {
      g_state.kd = s32_to_f_1e4(s32);
      mqttPublishKV(tTeleKd(), String(g_state.kd, 4), true);
    }
  }
}

void mqttEnsureConnected()
{
  if (s_mqtt.connected())
    return;

  static uint32_t lastTry = 0;
  if (millis() - lastTry < 1500)
    return;
  lastTry = millis();

  String cid = "esp32_gateway_" + String((uint32_t)ESP.getEfuseMac(), HEX);
  const String willTopic = tEspStatus();
  const char *willMsg = "offline";

  bool ok;
  if (strlen(CFG::MQTT_USER) || strlen(CFG::MQTT_PASS))
  {
    ok = s_mqtt.connect(cid.c_str(), CFG::MQTT_USER, CFG::MQTT_PASS,
                        willTopic.c_str(), CFG::MQTT_QOS, true, willMsg);
  }
  else
  {
    ok = s_mqtt.connect(cid.c_str(),
                        willTopic.c_str(), CFG::MQTT_QOS, true, willMsg);
  }

  if (ok)
  {
    Serial.println("[MQTT] Conectado");
    mqttSubscribeAll();
    mqttPublishKV(tEspStatus(), "online", true);
    mqttPublishSnapshot(true);
  }
  else
  {
    Serial.printf("[MQTT] Falha. rc=%d\n", s_mqtt.state());
  }
}

static void mqttSubscribeAll()
{
  s_mqtt.subscribe(tCmdSP().c_str(), CFG::MQTT_QOS);
  s_mqtt.subscribe(tCmdMode().c_str(), CFG::MQTT_QOS);
  s_mqtt.subscribe(tCmdFillValve().c_str(), CFG::MQTT_QOS);
  s_mqtt.subscribe(tCmdDischargeValve().c_str(), CFG::MQTT_QOS);
  s_mqtt.subscribe(tCmdSync().c_str(), CFG::MQTT_QOS);
  s_mqtt.subscribe(tCmdKp().c_str(), CFG::MQTT_QOS);
  s_mqtt.subscribe(tCmdKi().c_str(), CFG::MQTT_QOS);
  s_mqtt.subscribe(tCmdKd().c_str(), CFG::MQTT_QOS);
}

static float atof_safe(const char *p, unsigned len, float defv)
{
  String s;
  s.reserve(len + 1);
  for (unsigned i = 0; i < len; i++)
    s += (char)p[i];
  float v = s.toFloat();
  return isfinite(v) ? v : defv;
}

static void onMqttMessage(char *topic, byte *payload, unsigned int len)
{
  extern QueueHandle_t g_qMbWrites;
  extern deviceState g_state;

  const String t = String(topic);
  const int val = toIntSafe((const char *)payload, len);

  auto qWrite = [&](MBWriteKind kind, uint16_t addr, uint16_t v)
  {
    if (addr == 65535)
      return;
    MBWriteCmd cmd{kind, addr, v};
    xQueueSend(g_qMbWrites, &cmd, 0);
  };

  if (t == tCmdSP())
  {
    // App send 0..100 (%) -> PLC 0..10000 (P100)
    int32_t s32 = constrain(val, 0, 10000);

    if (CFG::HR_SP_LO != 65535)
    {
      bool ok = mbWriteHregS32(CFG::HR_SP_LO, s32);
      Serial.printf("[MQTT←CMD] SP_P100=%d -> S32=%ld (LO/HI @HR%u/%u) ok=%d\n",
                    val, (long)s32, (unsigned)CFG::HR_SP_LO, (unsigned)(CFG::HR_SP_LO + 1), ok);
    }
    else if (CFG::HR_SP_P100 != 65535)
    {
      qWrite(MBWriteKind::HREG, CFG::HR_SP_P100, (uint16_t)s32);
    }
  }
  else if (t == tCmdMode())
  {
    const uint16_t m = (val != 0) ? 1 : 0;
    if (CFG::COIL_MODE_AUTO != 65535)
      qWrite(MBWriteKind::COIL, CFG::COIL_MODE_AUTO, m);
  }
  else if (t == tCmdFillValve())
  {
    qWrite(MBWriteKind::COIL, CFG::COIL_HMI_FILL_CMD, (uint16_t)(val != 0));
  }
  else if (t == tCmdDischargeValve())
  {
    qWrite(MBWriteKind::COIL, CFG::COIL_HMI_DIS_CMD, (uint16_t)(val != 0));
  }
  else if (t == tCmdSync())
  {
    mqttPublishSnapshot(true);
  }
  else if (t == tCmdKp())
  {
    const float f = atof_safe((const char *)payload, len, 0.0f);
    const int32_t s32 = f_to_s32_1e4(f);
    uint16_t lo = (uint16_t)((uint32_t)s32 & 0xFFFF);
    uint16_t hi = (uint16_t)(((uint32_t)s32 >> 16) & 0xFFFF);
    Serial.printf("[MQTT←CMD] Kp=%.4f | S32=%ld | LO=%u HI=%u @HR%u/%u\n",
                  f, (long)s32, lo, hi, (unsigned)CFG::HR_KP_LO, (unsigned)(CFG::HR_KP_LO + 1));
    bool ok = mbWriteHregS32(CFG::HR_KP_LO, s32);
    Serial.printf("[MODBUS→] write Kp ok=%d\n", ok);
  }
  else if (t == tCmdKi())
  {
    const float f = atof_safe((const char *)payload, len, 0.0f);
    const int32_t s32 = f_to_s32_1e4(f);
    uint16_t lo = (uint16_t)((uint32_t)s32 & 0xFFFF);
    uint16_t hi = (uint16_t)(((uint32_t)s32 >> 16) & 0xFFFF);
    Serial.printf("[MQTT←CMD] Ki=%.4f | S32=%ld | LO=%u HI=%u @HR%u/%u\n",
                  f, (long)s32, lo, hi, (unsigned)CFG::HR_KI_LO, (unsigned)(CFG::HR_KI_LO + 1));
    bool ok = mbWriteHregS32(CFG::HR_KI_LO, s32);
    Serial.printf("[MODBUS→] write Ki ok=%d\n", ok);
  }
  else if (t == tCmdKd())
  {
    const float f = atof_safe((const char *)payload, len, 0.0f);
    const int32_t s32 = f_to_s32_1e4(f);
    uint16_t lo = (uint16_t)((uint32_t)s32 & 0xFFFF);
    uint16_t hi = (uint16_t)(((uint32_t)s32 >> 16) & 0xFFFF);
    Serial.printf("[MQTT←CMD] Kd=%.4f | S32=%ld | LO=%u HI=%u @HR%u/%u\n",
                  f, (long)s32, lo, hi, (unsigned)CFG::HR_KD_LO, (unsigned)(CFG::HR_KD_LO + 1));
    bool ok = mbWriteHregS32(CFG::HR_KD_LO, s32);
    Serial.printf("[MODBUS→] write Kd ok=%d\n", ok);
  }
}
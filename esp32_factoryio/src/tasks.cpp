#include <esp_task_wdt.h>
#include "config.hpp"
#include "topics.hpp"
#include "state.hpp"
#include "mqtt.hpp"
#include "modbus.hpp"

void mqttInit();
void mqttEnsureConnected();
void mqttLoop();
bool mbEnsureConnected();
bool mbReadIreg(uint16_t addr, uint16_t *out);
bool mbReadHreg(uint16_t addr, uint16_t *out);
bool mbReadCoil1(uint16_t addr, bool *out);
void mqttPublishSnapshot(bool retained);

deviceState g_state;
QueueHandle_t g_qMbWrites = nullptr;

static void taskMQTT(void *)
{
  esp_task_wdt_add(NULL);
  for (;;)
  {
    mqttEnsureConnected();
    mqttLoop();

    // heartbeat
    static uint32_t lastBeat = 0;
    const uint32_t now = millis();
    if (now - lastBeat >= 5000)
    {
      lastBeat = now;
      extern void mqttPublishKV(const String &, const String &, bool);
      mqttPublishKV(tTeleUptime(), String(now / 1000), false);
    }

    esp_task_wdt_reset();
    vTaskDelay(pdMS_TO_TICKS(10));
  }
}

static void taskModbus(void *)
{
  esp_task_wdt_add(NULL);
  uint32_t lastPoll = 0;

  for (;;)
  {
    const uint32_t now = millis();

    MBWriteCmd cmd;
    while (xQueueReceive(g_qMbWrites, &cmd, 0) == pdTRUE)
    {
      if (!mbEnsureConnected())
        break;

      if (cmd.kind == MBWriteKind::COIL)
      {
        mbWriteCoil(cmd.address, cmd.value != 0);
      }
      else
      {
        mbWriteHreg(cmd.address, cmd.value);
      }
      vTaskDelay(pdMS_TO_TICKS(8));
    }

    // Periodic polling
    if (now - lastPoll >= CFG::POLL_MS)
    {
      lastPoll = now;

      if (mbEnsureConnected())
      {
        uint16_t tmp;
        bool btmp;

        // ---- PV (S32 LO/HI 1e4) ----
        if (CFG::HR_PV_LO != 65535) // <- CERTO
        // ---- PV (S32 LO/HI ×1e4) ----
        {
          int32_t pv_s32;
          if (mbReadHregS32(CFG::HR_PV_LO, &pv_s32))
          {
            uint16_t pv_p100 = (uint16_t)constrain(pv_s32, 0, 10000);
            if (pv_p100 != g_state.pv_p100)
            {
              g_state.pv_p100 = pv_p100;
              mqttPublishKV(tTelePV(), String(g_state.pv_p100), false);

              // update display (0..32767)
              uint32_t disp = ((uint32_t)g_state.pv_p100 * 32767UL) / 10000UL;
              if (disp > 32767UL)
                disp = 32767UL;
              if ((uint16_t)disp != g_state.display)
              {
                g_state.display = (uint16_t)disp;
                mqttPublishKV(tStateDisplay(), String(g_state.display), false);
              }
            }
          }
        }

        else if (CFG::IR_PV_P100 != 65535 && mbReadIreg(CFG::IR_PV_P100, &tmp))
        {
          // Fallback 16-bit
          if (tmp != g_state.pv_p100)
          {
            g_state.pv_p100 = tmp;
            mqttPublishKV(tTelePV(), String(g_state.pv_p100), false);
            uint32_t disp = ((uint32_t)g_state.pv_p100 * 32767UL) / 10000UL;
            if (disp > 32767UL)
              disp = 32767UL;
            if ((uint16_t)disp != g_state.display)
            {
              g_state.display = (uint16_t)disp;
              mqttPublishKV(tStateDisplay(), String(g_state.display), false);
            }
          }
        } // SP (S32 LO/HI ×1e4)
        {
          int32_t sp_s32;
          if (mbReadHregS32(CFG::HR_SP_LO, &sp_s32))
          {
            uint16_t sp_p100 = (uint16_t)constrain(sp_s32, 0, 10000);
            if (sp_p100 != g_state.sp_p100)
            {
              g_state.sp_p100 = sp_p100;
              mqttPublishKV(tTeleSP(), String(g_state.sp_p100), true); // retained
            }
          }
        }

        // Mode
        if (CFG::COIL_MODE_AUTO != 65535)
        {
          if (mbReadCoil1(CFG::COIL_MODE_AUTO, &btmp))
          {
            const uint16_t m = btmp ? 1 : 0;
            if (m != g_state.mode)
            {
              g_state.mode = m;
              mqttPublishKV(tTeleMode(), String(g_state.mode), true); // retained
            }
          }
        }
        
        // === PID gains (REAL 32 bits) ===
        int32_t raw32;
        if (mbReadHregS32(CFG::HR_KP_LO, &raw32))
        {
          float f = s32_to_f_1e4(raw32);
          if (f != g_state.kp)
          {
            g_state.kp = f;
            mqttPublishKV(tTeleKp(), String(f, 4), true);
          }
        }
        if (mbReadHregS32(CFG::HR_KI_LO, &raw32))
        {
          float f = s32_to_f_1e4(raw32);
          if (f != g_state.ki)
          {
            g_state.ki = f;
            mqttPublishKV(tTeleKi(), String(f, 4), true);
          }
        }
        if (mbReadHregS32(CFG::HR_KD_LO, &raw32))
        {
          float f = s32_to_f_1e4(raw32);
          if (f != g_state.kd)
          {
            g_state.kd = f;
            mqttPublishKV(tTeleKd(), String(f, 4), true);
          }
        }

        // Coils
        if (CFG::COIL_Q_FILL != 65535 && mbReadCoil1(CFG::COIL_Q_FILL, &btmp))
        {
          if (btmp != g_state.filling)
          {
            g_state.filling = btmp;
            mqttPublishKV(tStateFill(), g_state.filling ? "1" : "0", false);
          }
        }
        if (CFG::COIL_Q_DISCHARGE != 65535 && mbReadCoil1(CFG::COIL_Q_DISCHARGE, &btmp))
        {
          if (btmp != g_state.discharging)
          {
            g_state.discharging = btmp;
            mqttPublishKV(tStateDischarge(), g_state.discharging ? "1" : "0", false);
          }
        }
      }
    }

    esp_task_wdt_reset();
    vTaskDelay(pdMS_TO_TICKS(5));
  }
}

void tasksStart()
{
  g_qMbWrites = xQueueCreate(16, sizeof(MBWriteCmd)); // HMI -> Modbus task
  xTaskCreatePinnedToCore(taskMQTT, "taskMQTT", 4096, nullptr, 2, nullptr, 0);
  xTaskCreatePinnedToCore(taskModbus, "taskModbus", 6144, nullptr, 3, nullptr, 1);
}

#include <Arduino.h>
#include <WiFi.h>
#include "config.hpp"
#include <esp_task_wdt.h>
#include "tasks.hpp"

void mqttInit();

void setup()
{
  Serial.begin(115200);

  // WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(CFG::WIFI_SSID, CFG::WIFI_PASS);
  Serial.printf("[WiFi] Connected em %s ...\n", CFG::WIFI_SSID);
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(300);
    Serial.print(".");
  }
  Serial.printf("\n[WiFi] OK. IP: %s\n", WiFi.localIP().toString().c_str());

  // WDT
  esp_task_wdt_init(CFG::WDT_TIMEOUT_S, true);

  // MQTT init
  mqttInit();

  // Tasks
  tasksStart();

  Serial.println("[BOOT] OK");
}

void loop()
{
}

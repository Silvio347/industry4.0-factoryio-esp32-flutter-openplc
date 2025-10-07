#pragma once
#include <Arduino.h>

void mqttInit();
void mqttEnsureConnected();
bool mqttConnected();
void mqttLoop();
void mqttPublishSnapshot(bool retained = true);
void mqttPublishKV(const String& topic, const String& payload, bool retained = false);
void readPidFromPlcAndPublish();

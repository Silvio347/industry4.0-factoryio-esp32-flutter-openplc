# 🏭 Industry 4.0 with Factory I/O, ESP32, OpenPLC and Flutter

This project demonstrates a complete **supervision and control architecture** integrating **Flutter HMI**, **ESP32**, **OpenPLC**, and **Factory I/O**, simulating a typical **Industry 4.0** workflow.  

The main goal is to combine **control, communication, and simulation** in a didactic and reproducible way, allowing students and professionals to experiment with industrial automation and system integration concepts.

---

## 🚀 Overview

The HMI (built in Flutter) communicates via **MQTT** with the **ESP32**, which acts as a bridge between the **OpenPLC** (using **Modbus TCP**) and the **Factory I/O** simulator.  
This setup enables remote control, real-time monitoring, and parameter tuning (like PID gains) inside a fully simulated environment.

---

## 🎥 Demonstration

📺 Video: YouTube - Industry 4.0 with Flutter, ESP32 and Factory I/O

---

## ⚙️ System Architecture

**Main components:**
- **Flutter App (HMI):** Mobile/web/desktop interface for user interaction.  
- **MQTT Broker (Mosquitto):** Message broker between the app and the ESP32.  
- **ESP32:** Acts as a gateway between MQTT ↔ Modbus TCP.  
- **OpenPLC Runtime:** Executes the control logic written in *Structured Text (ST)*.  
- **Factory I/O:** Simulates the industrial plant, connected to OpenPLC through Modbus TCP.

📡 All components operate within the **same local network**.  
In this setup, **Mosquitto**, **OpenPLC**, and **Factory I/O** are hosted on the same computer.

---

## 🧩 Communication Flow


- The HMI sends commands and receives telemetry data via MQTT.  
- The ESP32 translates messages into Modbus commands and communicates with OpenPLC.  
- The OpenPLC executes the control (PID) and drives the Factory I/O simulation.

---

## 🧠 PID Control

The PID controller is implemented in **Structured Text (ST)** within OpenPLC.  
The user defines **Kp**, **Ki**, **Kd**, and the **Setpoint (SP)** directly from the HMI.  

To avoid float and endianness issues in Modbus communication, a **fixed-point format** was adopted (scale ×10000, type `S32`).

### Example of value reconstruction in OpenPLC:
```pascal
_loDW   := WORD_TO_DWORD(INT_TO_WORD(Kp_lo));
_hiDW   := SHL(WORD_TO_DWORD(INT_TO_WORD(Kp_hi)), 16);
_raw_dw := _loDW OR _hiDW;
_raw_di := DWORD_TO_DINT(_raw_dw);
Kp := DINT_TO_REAL(_raw_di) / 10000.0;

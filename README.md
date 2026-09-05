# FPGA-Based Traffic Light Controller with Priority System

## 📋 Project Overview

A sophisticated 4-way intersection traffic light controller implemented in Verilog with emergency vehicle priority override capabilities. The system intelligently manages traffic flow using vehicle detection sensors and provides immediate right-of-way to emergency vehicles.

---

## ✨ Features

| Feature | Description | Priority Level |
|---------|-------------|----------------|
| **Emergency Vehicle Detection** | Automatic detection of emergency vehicles on NS/EW roads | 🔴 Highest |
| **Vehicle Presence Sensing** | Smart traffic detection using sensors | 🟡 Medium |
| **State Machine Control** | 7-state FSM for robust traffic management | - |
| **Configurable Timing** | Adjustable green/yellow light durations | - |
| **Simulation Ready** | Complete ModelSim testbench with multiple scenarios | - |

---


### Module Interface

| Port Name | Direction | Width | Description |
|-----------|-----------|-------|-------------|
| `clk` | Input | 1 | System clock (50MHz/100MHz) |
| `reset` | Input | 1 | Active high reset |
| `emergency_ns` | Input | 1 | Emergency vehicle on North-South |
| `emergency_ew` | Input | 1 | Emergency vehicle on East-West |
| `sensor_ns` | Input | 1 | Vehicle detection North-South |
| `sensor_ew` | Input | 1 | Vehicle detection East-West |
| `north_light` | Output | 3 | {Red, Yellow, Green} |
| `south_light` | Output | 3 | {Red, Yellow, Green} |
| `east_light` | Output | 3 | {Red, Yellow, Green} |
| `west_light` | Output | 3 | {Red, Yellow, Green} |
| `current_state` | Output | 4 | Current FSM state (debug) |
| `emergency_mode` | Output | 1 | Emergency mode indicator |

---

### State Description

| State | Binary | Light Configuration | Duration | Description |
|-------|--------|---------------------|----------|-------------|
| `IDLE` | `0000` | All Red | Until sensor | No traffic detected |
| `NS_GREEN` | `0001` | NS: Green, EW: Red | 10 cycles | North-South traffic flow |
| `NS_YELLOW` | `0010` | NS: Yellow, EW: Red | 3 cycles | NS transition period |
| `EW_GREEN` | `0011` | EW: Green, NS: Red | 10 cycles | East-West traffic flow |
| `EW_YELLOW` | `0100` | EW: Yellow, NS: Red | 3 cycles | EW transition period |
| `EMERGENCY_NS` | `0101` | NS: Green, EW: Red | 10 cycles | Emergency NS priority |
| `EMERGENCY_EW` | `0110` | EW: Green, NS: Red | 10 cycles | Emergency EW priority |

---

## ⏱ Timing Parameters

### Simulation Timing
| Parameter | Value | Description |
|-----------|-------|-------------|
| `GREEN_TIME` | 10 clock cycles | Green light duration |
| `YELLOW_TIME` | 3 clock cycles | Yellow light duration |
| `Clock Period` | 10 ns | 100 MHz simulation clock |
| `Emergency Duration` | 10 clock cycles | Emergency override period |

### Hardware Timing (FPGA)
| Parameter | Value | Description |
|-----------|-------|-------------|
| `GREEN_TIME` | 30 seconds | Actual green light |
| `YELLOW_TIME` | 5 seconds | Actual yellow light |
| `Clock Frequency` | 50 MHz | FPGA board clock |
| `Clock Divider` | 25,000,000 | 50MHz → 1Hz division |

---
### Test Scenarios & Results
Test Cases Summary
Test #	Scenario	Input Conditions	Expected Result	Status
1	No Traffic	NS=0, EW=0	All Red (IDLE)	✅ PASS
2	NS Traffic Only	NS=1, EW=0	NS Green → Yellow → EW Green	✅ PASS
3	EW Emergency	NS=1, EW=0, Emg_EW=1	Immediate EW Green	✅ PASS
4	EW Traffic Only	NS=0, EW=1	EW Green → Yellow → NS Green	✅ PASS
5	NS Emergency	NS=0, EW=1, Emg_NS=1	Immediate NS Green	✅ PASS
6	Both Directions	NS=1, EW=1	Alternating Traffic	✅ PASS
7	Multiple Emergency	Emg_NS then Emg_EW	Sequential Priority	✅ PASS

###Detailed Test Results
###Test 1: No Traffic (IDLE State)

|_________|_____________________|____________________|______
Time=0    | State=IDLE          | All Lights RED     | EMG=0
Time=50   | State=IDLE          | All Lights RED     | EMG=0
Result: ✅ System correctly stays in IDLE with all red lights
###Test 2: NS Traffic Only
|_________|_____________________|____________________|______
Time=60   | State=NS_GREEN      | NS=GREEN, EW=RED   | EMG=0
Time=160  | State=NS_YELLOW     | NS=YELLOW, EW=RED  | EMG=0
Time=190  | State=EW_GREEN      | NS=RED, EW=GREEN   | EMG=0
Result: ✅ Proper NS → EW transition with yellow interval
###Test 3: Emergency Vehicle on EW
|_________|_____________________|____________________|______
Time=200  | State=NS_GREEN      | NS=GREEN, EW=RED   | EMG=0
Time=210  | Trigger: emergency_ew = 1
Time=220  | State=EMERGENCY_EW   | NS=RED, EW=GREEN   | EMG=1
Time=320  | State=IDLE          | All RED            | EMG=0
Result: ✅ Emergency override works immediately (within 2 cycles)
###Test 4: Both Directions Active

Cycle 1: NS_GREEN (10 cycles) → NS_YELLOW (3 cycles)
Cycle 2: EW_GREEN (10 cycles) → EW_YELLOW (3 cycles)
Result: ✅ Fair alternating traffic flow maintained


# Aex-442-locomoive
---
# AEXEL 2025 Rolling Stock 1 — DB442 (Talent 2 Inspired)

**AEXELRAIL442NGR**

---

*Note: This addon is not affiliated with Bombardier Transportation or the Deutsche Bahn Group in any way.*

---

## General Information

**Name:** AEXEL 2025 Rolling Stock 1_DB442 Talent 2 Inspired_AEXELRAIL442NGR
**Operator:** DB (Deutsche Bahn inspired)
**Connector Property:** NOT SRC‑TCP, Propriety AEX Connector
**Front Coupler System:** AEXEL CONNECT V1.1
**License:** Open Source – Free to use parts with credit
**Top Speed:** 140 km/h
**Performance Profile:** High–Medium efficiency power usage
**Battery Operation:** Low‑speed battery movement supported
**Future Systems Planned:** PZB, LZB, ETCS, SIFA

---

## Route Map

[Network Route Map](https://ngr.aexelgroup.app/routes/)
*Train data on the website may not perfectly match in‑game configuration.*

---

## ARN Project – Signals & Trackside Equipment

- Full integration with AEXEL Rail Network (ARN) planned
- Real‑time track monitoring & automated signal recognition
- Future onboard sync with ARN signal data

---

## Version Information

**Version:** v1.0
**Release Date:** February 2026
**Status:** Stable Public Release

---

## Performance & System Testing

### Singleplayer Performance

**Test Environment:**
- Intel i5‑12400F
- 16GB DDR4
- RTX 3060
- Windows 11
- VSync Off

**Results:**
- 144 FPS (VSync Off)
- ~62 Physics FPS at high speed
- Stable at 140 km/h
- No major stutters

### Multiplayer

- Fully multiplayer compatible
- Stable in multi‑car consists
- Recommended max consist: 3 cars

### Operating System Compatibility

**Windows:** Fully tested
**Linux:**
- Arch Linux – Works great
- Debian – Minor GPU artifacts

**GPU Fix Button:**
- Fixes NVIDIA/AMD Linux screen artifacts
- Screen flashes ~1 second

**macOS:** Untested

---

## Known Limitations

- Pantograph must be lowered before entering hangars
- Manual breaker activation required
- Emergency brake sensitive at -1.1
- GPU fix needed on some Linux setups
- Not compatible with SRC‑TCP rolling stock

---

## Safety Systems (Planned)

- Future: PZB, LZB, ETCS, SIFA
- Fire detection warnings already implemented
- Emergency brake partially integrated

---

# Formation & Dimensions

## Configuration

**3‑Car EMU (D–M–D)**

**Traction Layout:**
- Car 1: 4× Medium Motors
- Car 2: 2× Small In‑floor Motors
- Car 3: 4× Medium Motors

## Dimensions

- Car 1 & 3: 91 blocks (22.75 m)
- Passenger Car: 70 blocks (17.50 m)
- Total Length: ~252 blocks (~63 m)
- Width: 13 blocks (3.25 m)

---

# Exterior Features

## Coupler System

- Vertical stacked dual electric connectors
- Bottom: AEXEL MU-System (4 blocks above ground)
- Top: Auxiliary connector (5 blocks above ground)
- Transfers power + data

## Pantograph

- Hold up/down 3 seconds
- Provides traction power
- Must be lowered in hangars

---

# Driver Cab Features

**Language:** German
**Cab Doors:** 2 per side

## Master Key

- 0 – Off
- 1 – On
- 2 – Disconnect front connector

## Left Screen

Displays warnings, lights, brakes, power.
Supports dark mode & dial customization.

## Left Wall Panel

- Radio (20 km range)
- Signal switch
- S.M.A.R.T direction switch (4 km range)

[S.M.A.R.T Signals](https://steamcommunity.com/sharedfiles/filedetails/?id=2966862255)

## Desk Controls

**Throttle/Brake Lever:**
- Deadzone: -0.1 to 0.09
- Max Power: +1.1
- Service Brake: -1.0
- Emergency: -1.1

**Pantograph Control:** Hold 3 seconds
**Indirect Brake:** Right side of desk

## Right Wall Panel

- Cab lights
- Door controls (left/right/open/close)
- Interlock lever

## Front Display

- Speed (KMH/MPH)
- Dial + numeric
- Dark mode

## Reverser

- -1 Reverse
- 0 Neutral
- 1 Forward

## Right Display – Warning Panel

**Modes:** Dark mode, Purple mode
**Buttons:** Acknowledge, Silence, Diagnostics

**Warning Layout:**
- 1 Traction
- 2 Brake
- 3 Door Interlock
- 4 Line Power
- 5 Battery
- 6 Temperature
- 7 Emergency
- 8 General Warning

---

# Driver Equipment

- Hi‑vis wear
- Fishing rod
- Transponder tools
- Strobe light
- Radiation detector
- Hand radio
- RC controller
- Medical kits ×3
- Defibrillator
- Welding torch
- Compass
- Torch
- Binoculars + NV
- Fire extinguisher

---

# Engine Room

- Behind cab
- 2 sliding doors
- 10 breakers
- 4 motors per driving car
- Heavy rear door

---

# Passenger Cabin

- Lighting + speakers
- Large seating
- Open gangways
- Door beeps (slow/fast)
- Heating system
- Coupling cable access

## GPU Compatibility Button

- Fixes Linux GPU artifacts
- Screen flashes ~1 second

---

# Startup Procedure

1. Activate breakers in both driving cars
2. Check rear tail lights
3. Master Key → 1
4. Select signal mode
5. Enable passenger lights
6. Set headlights
7. Set cab lights
8. Check radio & pressures
9. Acknowledge warnings
10. Enable door interlock
11. Reverser → Forward
12. Exit hangar ≤ 10 km/h
13. Stop once clear
14. Raise pantograph
15. Proceed to first station

---

## Controls

- **A / D:** Headlights / Spitzensignal
- **W / S:** Combined Throttle/Brake Lever (Fahr‑/Bremssteller)
- **Up / Down Arrow:** Indirect Brake Lever (Indirekte Bremse)
- **Space:** Radio PTT
- **5:** GPU Fix (screen flashes ~1 second)
- **6:** Raise seat by 25cm

---

## Changelog

**v1.0 – February 2026**
- Initial public release

---

# Microcontrollers & Systems

[Modified Master‑Slave System (Sock)](https://steamcommunity.com/sharedfiles/filedetails/?id=2372762554)
[Headlight Controller (Robot Wizz)](https://steamcommunity.com/sharedfiles/filedetails/?id=3192572215)
[S.M.A.R.T Signals](https://steamcommunity.com/sharedfiles/filedetails/?id=2966862255)

**Additional AEXEL Systems:**
- AEX442 Track Switcher v1.1
- AEXEL Step Up/Down Switch
- AEX442 AEXEL Master v1.0
- AEX442 Driver Lights v1.3
- AEX442 Cabin Lights v1.3
- AEXEL Main Train System
- AEX442 Screens Controller
- AEXEL Pantograph Panel
- AEX442 Door Intervene v1.0
- AEXEL Train Door Slave Controller v1.7
- AEXEL Couple System

---

# Credits

**Base Model:** [Airlink Class 755 – TenPilots](https://steamcommunity.com/sharedfiles/filedetails/?id=3111365837)
**Master‑Slave System:** [Modified Master‑Slave System (Sock)](https://steamcommunity.com/sharedfiles/filedetails/?id=2372762554)
**Headlight Controller:** [Headlight Controller (Robot Wizz)](https://steamcommunity.com/sharedfiles/filedetails/?id=3192572215)
**S.M.A.R.T Signals:** [S.M.A.R.T Signals](https://steamcommunity.com/sharedfiles/filedetails/?id=2966862255)
**All AEXEL Integration & Systems:** AEXEL

---

*Note: This addon is not affiliated with Bombardier Transportation or the Deutsche Bahn Group in any way.*

<details>
<summary>Tags</summary>
Train, EMU, Electric Multiple Unit, Talent 2, DB, Deutsche Bahn, AEXEL, Rolling Stock, German, Rail Transport, Simulation, DB442, Bombardier Talent 2
</details>

---

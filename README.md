# SirenDetector 🚨🚦

**Autonomous Acoustic Emergency Vehicle Preemption System**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status](https://img.shields.io/badge/Status-Simulation_Validated-success)]()
[![Method](https://img.shields.io/badge/Method-Deterministic_DSP-blue)]()

## 📖 Overview
**SirenDetector** is a safety-critical embedded system project designed to detect emergency vehicle sirens (Police, Ambulance, Fire) from a distance of **1000 feet (300 meters)** and autonomously switch traffic signals to green.

Unlike modern "Smart City" solutions that rely on expensive 5G/4G networks, GPS, or "Black Box" AI models, SirenDetector uses **Deterministic Signal Processing**. It analyzes the physics of sound—specifically the spectral energy density of the "Wail" frequency sweep (600Hz–1500Hz)—to trigger traffic preemption with mathematical certainty.

**Key Features:**
* **No AI/ML:** Uses FFT/STFT physics-based logic (Audit-able & Transparent).
* **Offline Operation:** No internet, Wi-Fi, or Cloud dependency ("Air-Gapped").
* **High Noise Immunity:** Validated at -5.5 dB SNR (Traffic louder than siren).
* **Ultra-Low Latency:** Reaction time < 50ms.

## 📊 Performance Metrics (Simulation)
Verified via MATLAB simulation modeling a 1000ft distance with stochastic traffic noise.

| Metric | Result | Notes |
| :--- | :--- | :--- |
| **Detection Latency** | **16.00 ms** | Near-instantaneous reaction |
| **False Positives** | **0 Frames** | 100% stable in non-emergency traffic |
| **Signal-to-Noise Ratio** | **-5.50 dB** | Detects sirens buried in heavy noise |

## 🛠️ How It Works
The system avoids simple "loudness" detection (which fails with thunder or horns). Instead, it uses a multi-stage spectral algorithm:

1.  **Input:** Captures audio at 8kHz via MEMS microphone.
2.  **Transformation:** Applies **Short-Time Fourier Transform (STFT)** to visualize frequency energy.
3.  **Filtration:** Isolates the **600Hz – 1500Hz** band (Standard Emergency Siren Range).
4.  **Verification:** Checks for the characteristic "Wail" modulation rate (~4.5Hz cycle).
5.  **Actuation:** If energy > Threshold (0.65), the Traffic State Machine forces the light to **Emergency Green**.

## 📂 Repository Structure
```bash
SirenDetector/
├── simulation/
│   ├── SirenDetection_Final.m   # The Complete MATLAB Algorithm & Proof
│   └── fig1.png                 # Visualization of results
├── docs/
│   └── IEEE_Report_Draft.pdf    # Technical report and methodology
└── README.md

# 🚨 Destination Alarm

<p align="center">
  <img src="assets/icon/app_icon.png" width="120" alt="Destination Alarm Logo">
</p>

<h3 align="center">
  Never Miss Your Destination Again.
</h3>

<p align="center">
  A smart Android destination alert application designed for commuters,
  travelers, and bus/train passengers.
</p>

<p align="center">
  <a href="https://github.com/bhimratna/destination-alarm/releases/latest">
    <img src="https://img.shields.io/github/v/release/bhimratna/destination-alarm?style=for-the-badge&color=19C37D" alt="Latest Release">
  </a>
  <a href="https://github.com/bhimratna/destination-alarm">
    <img src="https://img.shields.io/github/stars/bhimratna/destination-alarm?style=for-the-badge" alt="GitHub Stars">
  </a>
  <a href="https://github.com/bhimratna/destination-alarm/issues">
    <img src="https://img.shields.io/github/issues/bhimratna/destination-alarm?style=for-the-badge" alt="Issues">
  </a>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
</p>

---

## 📱 Overview

**Destination Alarm** is an Android application built for commuters who want
to sleep, relax, or focus during a journey without worrying about missing
their destination.

The user selects a destination and defines an alert radius. The application
continuously monitors the device's location and calculates the distance
between the current position and the selected destination.

When the device enters the configured destination radius, the application
triggers a loud alarm with vibration and an on-screen destination alert.

### Example

If your bus journey is **38 km** and your destination alert radius is **1 km**:

```text
Start
  │
  │
  │        Live GPS Tracking
  │
  │───────────────►──────────────►
                                  │
                                  │ 1 km
                                  ▼
                            📍 Destination
                                  │
                                  ▼
                         🚨 ALARM TRIGGERED

---

## ✨ Key Features

### 📍 Smart Destination Detection

Set a destination and configure a custom alert radius.

Supported example radii:

- 500 m
- 1 km
- 2 km
- 3 km
- 5 km

### 🛰️ Continuous GPS Tracking

The application monitors the user's live location during an active journey
and calculates the distance to the selected destination.

### 🔔 Loud Destination Alarm

When the destination radius is reached:

- Alarm sound starts
- Device vibrates
- Full-screen alarm interface appears
- Destination notification is displayed
- Alarm continues until manually stopped

### 🌙 Background Journey Monitoring

Destination Alarm uses Android foreground-service functionality so location
tracking can continue while the application is not actively visible.

### 📱 Lock-Screen Alert

The destination alert is designed to bring the alarm to the user's attention
even when the device screen is locked.

### 🎨 Modern Dark UI

A modern dark interface with a premium green accent, designed for comfortable
mobile use.

---

## 🧠 How It Works

```text
┌───────────────────────┐
│  Select Destination   │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  Select Alert Radius  │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│    Start Journey      │
└───────────┬───────────┘
            │
            ▼
┌────────────────────────────┐
│   Foreground GPS Tracking  │
│                            │
│   Current Location         │
│          ↓                 │
│   Distance Calculation     │
└────────────┬───────────────┘
             │
             ▼
      Distance <= Radius?
          /          \
        NO            YES
        │              │
        │              ▼
        │       ┌──────────────┐
        │       │ Stop Tracking│
        │       └──────┬───────┘
        │              │
        │              ▼
        │       ┌──────────────┐
        │       │ 🚨 ALARM     │
        │       │   TRIGGERED  │
        │       └──────┬───────┘
        │              │
        │              ▼
        │       User Stops Alarm
        │
        └──────────────►

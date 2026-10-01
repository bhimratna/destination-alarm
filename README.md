# 🚨 Destination Alarm

<p align="center">
  <img src="assets/icon/app_icon.png" width="140" alt="Destination Alarm">
</p>

<h1 align="center">Destination Alarm</h1>

<p align="center">
  <strong>Never Miss Your Destination Again.</strong>
</p>

<p align="center">
  A smart Android destination-alert application for commuters,
  travelers, and passengers who want to be notified when they
  are approaching their destination.
</p>

<p align="center">

<a href="https://github.com/bhimratna/destination-alarm/releases/latest">
<img src="https://img.shields.io/github/v/release/bhimratna/destination-alarm?style=for-the-badge&color=19C37D&label=LATEST%20RELEASE">
</a>

<a href="https://github.com/bhimratna/destination-alarm">
<img src="https://img.shields.io/github/stars/bhimratna/destination-alarm?style=for-the-badge">
</a>

<a href="https://github.com/bhimratna/destination-alarm/issues">
<img src="https://img.shields.io/github/issues/bhimratna/destination-alarm?style=for-the-badge">
</a>

<img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white">

<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white">

</p>

---

# 📱 About The Project

**Destination Alarm** is an Android application designed to help commuters
avoid missing their destination during long journeys.

The user selects a destination and configures a destination alert radius.
During an active journey, the application monitors the device's GPS location
and continuously calculates the distance between the current location and
the selected destination.

When the user enters the configured destination radius, the application
automatically triggers a loud alarm with vibration and displays a dedicated
destination-alert interface.

The application is particularly useful for people who travel by bus or train
and may sleep or become distracted during long journeys.

---

# 🎯 Problem Statement

Long-distance commuters often face a simple but practical problem:

> **How can a passenger be reliably alerted when they are approaching their
> destination without constantly checking their phone or GPS application?**

Traditional map applications primarily provide navigation and route guidance.
They are not specifically designed around the simple requirement of waking or
alerting a sleeping passenger when they enter a predefined destination area.

Destination Alarm focuses specifically on this problem.

---

# 💡 Proposed Solution

Destination Alarm converts a smartphone into a **location-based destination
alarm system**.

The basic workflow is:

```text
Select Destination
        ↓
Select Alert Radius
        ↓
Start Journey
        ↓
Live GPS Monitoring
        ↓
Calculate Distance
        ↓
Compare Distance With Radius
        ↓
Destination Radius Reached?
        ↓
       YES
        ↓
Stop Journey Tracking
        ↓
🚨 Trigger Alarm
        ↓
User Stops Alarm

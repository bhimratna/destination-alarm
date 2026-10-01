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

✨ Key Features
📍 Destination-Based Alert
Users can define a destination and specify how close they want to be before
the alarm is triggered.
Example:
Destination Radius

500 m
1 km
2 km
3 km
5 km

🛰️ Live GPS Tracking
The application uses device location data to determine the user's current
position during an active journey.
The distance between the current position and destination is continuously
calculated.
📏 Distance-Based Trigger
The alarm is triggered when:
Current Distance <= Selected Radius

For example:
Current distance = 850 m
Selected radius = 1 km

850 m <= 1 km

→ Destination Alarm Triggered

🔔 Loud Alarm
When the destination condition is satisfied, the application triggers:
- Alarm sound
- Vibration
- Destination notification
- Full-screen alarm interface
The alarm continues until the user stops it.
🌙 Background Journey Monitoring
The application uses an Android foreground service for journey monitoring.
This allows the location-tracking process to continue while the application
is not actively being viewed.
Example:
Destination Alarm
       │
       ├── Screen ON
       │
       ├── Screen LOCKED
       │
       ├── Another App Open
       │
       └── Phone In Pocket
              │
              ▼
        Journey Tracking

📱 Lock-Screen Alert
The alarm interface is configured to bring the destination alert to the
user's attention even when the device is locked.
🎨 Modern Mobile UI
The application uses a dark interface with a premium green accent system.
The interface focuses on:
- Clear destination information
- Current distance
- Selected radius
- Journey state
- GPS status
- Alarm state
- Simple user actions
🧠 Core Technology
Destination Alarm combines several Android and Flutter technologies:
┌─────────────────────────────┐
│        Flutter UI           │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       Dart Application      │
│          Logic              │
└──────────────┬──────────────┘
               │
       ┌───────┴────────┐
       ▼                ▼
┌──────────────┐  ┌──────────────┐
│ Geolocator   │  │ Background   │
│              │  │ Service      │
└──────┬───────┘  └──────┬───────┘
       │                 │
       └────────┬────────┘
                ▼
       ┌──────────────────┐
       │ Distance Engine  │
       └────────┬─────────┘
                │
                ▼
       ┌──────────────────┐
       │ Radius Condition │
       └────────┬─────────┘
                │
              TRUE
                │
                ▼
       ┌──────────────────┐
       │ Alarm Package    │
       └────────┬─────────┘
                │
                ▼
          🚨 USER ALERT

🧮 Distance Calculation
The application uses geographical coordinates obtained from GPS.
Each location contains:
Latitude
Longitude

The application calculates the geographical distance between:
Current Location
        ↓
Destination Location

The resulting distance is used to determine whether the destination alert
radius has been reached.
Conceptually:
Distance = GPS(Current Location, Destination)

The trigger condition is:
if distance <= selectedRadius:
    triggerAlarm()

🏗️ System Architecture
                    ┌─────────────────────┐
                    │     Flutter UI      │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Journey Controller  │
                    └──────────┬──────────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
                ▼                             ▼
       ┌─────────────────┐          ┌──────────────────┐
       │   Geolocator    │          │ Background       │
       │ GPS Location    │          │ Service          │
       └────────┬────────┘          └────────┬─────────┘
                │                            │
                └──────────────┬─────────────┘
                               ▼
                    ┌─────────────────────┐
                    │ Distance Calculation│
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Radius Comparison    │
                    └──────────┬──────────┘
                               │
                         Radius Reached
                               │
                               ▼
                    ┌─────────────────────┐
                    │   Alarm Manager     │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ 🔔 Sound + Vibration│
                    │ 📱 Alarm Screen     │
                    │ 🔔 Notification      │
                    └─────────────────────┘

🛠️ Technology Stack
Frontend / Application
Technology	Purpose
Flutter	Mobile application framework
Dart	Application programming language
Material UI	Android application interface


Location & Background Processing
Technology	Purpose
Geolocator	GPS location access and distance calculation
Flutter Background Service	Background/foreground journey monitoring
Android Foreground Service	Persistent background execution


Alarm System
Technology	Purpose
Alarm	Alarm scheduling and ringing
Android Notifications	Destination notification
Android Full-Screen Intent	Full-screen destination alert
Android Wake Lock	Device wake support
Android Vibration	User alert


Development Tools
Tool	Purpose
VS Code	Development environment
Flutter SDK	Build and development
Android SDK	Android development
Gradle	Android build system
Git	Version control
GitHub	Source-code hosting and releases


📦 Main Flutter Packages
dependencies:
  flutter:
    sdk: flutter

  geolocator:
  flutter_background_service:
  alarm:
  http:

The exact package versions used by the project are defined in:
pubspec.yaml

and
pubspec.lock

📂 Project Structure
destination_alarm/
│
├── android/
│   ├── app/
│   │   └── src/
│   │       └── main/
│   │           ├── AndroidManifest.xml
│   │           ├── kotlin/
│   │           │   └── com/
│   │           │       └── example/
│   │           │           └── destination_alarm/
│   │           │               └── MainActivity.kt
│   │           └── res/
│   │
│   ├── build.gradle.kts
│   ├── gradle.properties
│   └── settings.gradle.kts
│
├── assets/
│   └── icon/
│       └── app_icon.png
│
├── lib/
│   ├── main.dart
│   ├── alarm_screen.dart
│   └── alarm_test.dart
│
├── test/
│
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── .gitignore
└── README.md

🔐 Android Permissions
Destination Alarm requires permissions related to location, background
execution, notifications and alarm behavior.
The Android application requests permissions including:
ACCESS_FINE_LOCATION
ACCESS_COARSE_LOCATION
ACCESS_BACKGROUND_LOCATION

FOREGROUND_SERVICE
FOREGROUND_SERVICE_LOCATION

POST_NOTIFICATIONS

WAKE_LOCK
VIBRATE

USE_FULL_SCREEN_INTENT
USE_EXACT_ALARM
SCHEDULE_EXACT_ALARM

These permissions support the application's location monitoring and alarm
functionality.
🚀 Getting Started
Prerequisites
Before running the project, install:
- Flutter SDK
- Dart SDK
- Android SDK
- Android Studio or Android SDK command-line tools
- Android device or emulator
Verify Flutter:
flutter doctor

📥 Installation
1. Clone the repository
git clone https://github.com/bhimratna/destination-alarm.git

2. Enter the project
cd destination-alarm

3. Install dependencies
flutter pub get

4. Connect an Android device
Verify:
flutter devices

5. Run the application
flutter run

📦 Build APK
To generate a release APK:
flutter build apk --release

The generated APK will normally be available at:
build/app/outputs/flutter-apk/app-release.apk

📥 Download Latest APK
<p align="center">

<a href="https://github.com/bhimratna/destination-alarm/releases/latest">
  <img src="https://img.shields.io/badge/VIEW%20LATEST%20RELEASE-19C37D?style=for-the-badge&logo=github&logoColor=white">
</a>

 
<a href="https://github.com/bhimratna/destination-alarm/releases/latest/download/destination-alarm.apk">
  <img src="https://img.shields.io/badge/⬇%20DOWNLOAD%20APK-19C37D?style=for-the-badge&logo=android&logoColor=white">
</a>

</p>

The direct APK button becomes active after an APK named
destination-alarm.apk is uploaded to a GitHub Release.

🧪 Testing
The application has been tested against the core destination-alarm workflow.
Tested Components
✓ Application startup
✓ GPS location acquisition
✓ Destination selection
✓ Radius configuration
✓ Distance calculation
✓ Journey start
✓ Background tracking
✓ Destination detection
✓ Alarm scheduling
✓ Alarm sound
✓ Alarm vibration
✓ Alarm notification
✓ Alarm screen
✓ Manual alarm stop

Example Test Scenario
Destination:
Current Location

Alert Radius:
1 km

GPS:
Active

Result:
🚨 Destination Alarm Triggered

🚌 Real-World Use Case
Consider a passenger travelling approximately 38 km by bus.
Home
 │
 │
 │
 │      Bus Journey
 │
 ├───────────────────────────────────┐
 │                                   │
 │                                   ▼
 │                              Destination
 │                               📍
 │                             ┌───────┐
 │                             │ 1 km  │
 │                             └───────┘
 │                                  │
 │                                  ▼
 │                         🚨 Alarm Trigger
 │
 └────────────── 38 km ────────────────►

The journey distance and alert radius are separate concepts.
Example:
Journey distance = 38 km
Alert radius     = 1 km

The alarm activates when the user's current location enters the configured
1 km destination radius.
⚡ Performance Considerations
Location-based applications must balance accuracy, responsiveness and
battery consumption.
Destination Alarm therefore uses:
- Background/foreground service architecture
- GPS location updates
- Distance-based triggering
- A configurable destination radius
- Alarm activation only when the destination condition is satisfied
Actual GPS accuracy can vary depending on:
- Indoor/outdoor environment
- Weather
- Device hardware
- GPS visibility
- Network-assisted positioning
- Android battery-management settings
⚠️ Limitations
The application depends on the device's location services.
Therefore, destination detection can be affected by:
- Poor GPS signal
- Indoor environments
- Location permission restrictions
- Android battery optimization
- Device-specific background execution policies
- Temporary location inaccuracies
Users should ensure that required permissions and location services are
enabled before starting a journey.
🔮 Future Development
Potential future improvements include:
- [ ] Google Maps integration
- [ ] Google Places destination search
- [ ] Saved destinations
- [ ] Recent destinations
- [ ] Multiple destination profiles
- [ ] Custom alarm sounds
- [ ] Custom alarm volume
- [ ] Snooze functionality
- [ ] Travel history
- [ ] Route-aware detection
- [ ] Improved battery optimization
- [ ] Improved GPS filtering
- [ ] Material 3 enhancements
- [ ] Play Store deployment
🧑‍💻 Author
<p align="center">

<img src="https://github.com/bhimratna.png" width="100" height="100"
     style="border-radius:50%;" alt="Bhimratna Sardar">
</p>

<h3 align="center">Bhimratna Sardar</h3>

<p align="center">
  Computer Engineering Student<br>
  B.S. Deore College of Engineering, Dhule<br>
  Dr. Babasaheb Ambedkar Technological University (DBATU)
</p>

<p align="center">

<a href="https://github.com/bhimratna">
  <img src="https://img.shields.io/badge/GitHub-Bhimratna%20Sardar-181717?style=for-the-badge&logo=github">
</a>

</p>

📊 Project Information
Information	Details
Project	Destination Alarm
Platform	Android
Framework	Flutter
Language	Dart
Primary Domain	Location-Based Mobile Application
GPS	Geolocation
Background Processing	Android Foreground Service
Alarm Engine	Flutter Alarm Package
Repository	github.com/bhimratna/destination-alarm
Developer	Bhimratna Sardar


🤝 Contributing
Contributions, suggestions and improvements are welcome.
Fork the repository
git fork

Create a feature branch
git checkout -b feature/your-feature

Commit changes
git add .
git commit -m "Add your feature"

Push your branch
git push origin feature/your-feature

Then open a Pull Request on GitHub.
🐛 Issues & Feature Requests
Found a bug or have an idea?
Open an issue:
https://github.com/bhimratna/destination-alarm/issues
Please include:
- Android version
- Device model
- Application version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Relevant logs or screenshots
⭐ Support The Project
If you find Destination Alarm useful:
⭐ Star the repository
🐛 Report bugs
💡 Suggest features
🔧 Contribute improvements

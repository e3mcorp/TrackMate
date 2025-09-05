<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# 🚗📡 **TrackMate - GPS Tracker Flutter App**

<div align="center">





**Professional GPS Tracker Management App for MV710G and Compatible Devices**

[Features](#-features) -  [Installation](#-installation) -  [Configuration](#-configuration) -  [Commands](#-commands) -  [Screenshots](#-screenshots) -  [Contributing](#-contributing)

</div>

***

## 📱 **Overview**

TrackMate is a comprehensive Flutter application designed to manage GPS trackers via SMS commands. Built specifically for **MiCODUS MV710G** 4G/LTE trackers, it provides real-time vehicle monitoring, advanced alarm management, and remote control capabilities.

### 🎯 **Key Capabilities**

- **Real-time GPS Tracking** - Monitor vehicle location and movement
- **SMS Command Interface** - Send and receive tracker commands
- **Advanced Alarm System** - Speed, power, vibration, and zone alerts
- **Remote Control** - Cut/resume fuel, arm/disarm, configure settings
- **Multi-tracker Support** - Manage multiple vehicles from one app
- **Offline Database** - SQLite storage for messages and positions
- **Material 3 Design** - Modern, responsive UI following Flutter guidelines

***

## ✨ **Features**

### 🚛 **Vehicle Management**

- Add unlimited trackers with custom names and colors
- Vehicle details (license plate, chassis number, model)
- Battery level monitoring and low voltage alerts
- Last known position and connectivity status


### 📡 **GPS Tracking**

- **Real-time positioning** with GPS+BDS+GLONASS support
- **Location history** with route playback
- **Interactive maps** powered by MapBox
- **Coordinate parsing** from SMS responses
- **Google Maps integration** for location sharing


### ⚙️ **Remote Configuration**

- **APN Settings** - Configure network connectivity
- **Server Setup** - Set tracking server and ports
- **Time Zone** - GMT and data timezone configuration
- **Update Intervals** - Custom upload frequency for moving/stopped
- **Heartbeat Settings** - Connection maintenance intervals


### 🚨 **Advanced Alarms**

- **Speed Monitoring** - Configurable overspeed alerts (1-255 km/h)
- **Power Alarms** - External power disconnect notifications
- **Vibration Detection** - Anti-theft motion sensing
- **Geo-fencing** - Shift distance alerts (100-9999m)
- **ACC Status** - Engine start/stop notifications
- **Door Monitoring** - Open door alarm system
- **Low Voltage** - Battery threshold alerts (9-95V)


### 🎛️ **Remote Control**

- **Fuel Management** - Cut off or resume fuel remotely
- **Arm/Disarm** - Security mode control
- **Factory Reset** - Complete device restoration
- **Restart Device** - Remote reboot functionality
- **SOS Numbers** - Emergency contact management (up to 3)
- **Admin Control** - Secure command authorization


### 💾 **Data Management**

- **SQLite Database** - Local storage for offline access
- **Message History** - Complete SMS conversation logs
- **Position Tracking** - Historical location data
- **Export Capabilities** - Data backup and sharing
- **Multi-device Sync** - Cloud backup ready architecture

***

## 🛠️ **Technical Specifications**

### **Supported Trackers**

- **MiCODUS MV710G** (Primary)
- **4G LTE + 2G GSM** compatible devices
- **SMS command-based** GPS trackers


### **Platform Support**

- **Android** 5.0+ (API 21)
- **iOS** 12.0+
- **Material 3** design system
- **Responsive layouts** for tablets and phones


### **Dependencies**

```yaml
flutter: ">=3.0.0"
sqflite: ^2.3.0           # Local database
another_telephony: ^2.0.0  # SMS handling  
mapbox_gl: ^0.16.0        # Maps integration
flutter_colorpicker: ^1.0.3
flutter_native_contact_picker_plus: ^1.0.0
salomon_bottom_bar: ^3.3.2
timezones_list: ^1.0.1
uuid: ^4.1.0
```


***

## 🚀 **Installation**

### **Prerequisites**

- Flutter SDK 3.0.0+
- Android Studio or VS Code
- Android/iOS device or emulator
- Active SIM card for tracker


### **Clone Repository**

```bash
git clone https://github.com/yourusername/trackmate-flutter.git
cd trackmate-flutter
```


### **Install Dependencies**

```bash
flutter pub get
```


### **Configure Permissions**

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.SEND_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to display tracker positions</string>
<key>NSContactsUsageDescription</key>
<string>Access contacts to select phone numbers for trackers</string>
```


### **Build and Run**

```bash
# Debug build
flutter run

# Release APK
flutter build apk --release

# iOS build
flutter build ios --release
```


***

## ⚙️ **Configuration**

### **1. Hardware Setup**

1. **SIM Card Installation**
    - Insert micro SIM with SMS and data enabled
    - Remove PIN code requirement
    - Ensure sufficient credit balance
2. **Power Connection**
    - Connect to 12V+ vehicle power supply
    - Wire ignition detection (ACC line)
    - Install in recommended location (unobstructed GPS view)

### **3. App Configuration**

1. **Add New Tracker**
    - Open TrackMate app
    - Tap "Add Tracker"
    - Enter tracker name and SIM phone number
    - Set PIN code (default: 123456)
2. **Network Setup**
    - Configure APN settings from your carrier
    - Set tracking server (optional)
    - Configure timezone for your region
3. **Test Connection**
    - Send "WHERE\#" command to request position
    - Verify SMS responses are received
    - Check tracker appears online in app

***

## 📟 **MV710G SMS Commands**

### **Basic Configuration**

```sms
APN,internet#                    # Set APN (no user/pass)
APN,internet,user,pass#          # Set APN with credentials
SERVER,1,domain.com,7700#        # Set server by domain
SERVER,0,192.168.1.1,7700#       # Set server by IP
CENTER,123456,A,+1234567890#     # Set admin number
GMT,E,8#                         # Set GMT+8 timezone
```


### **Information Requests**

```sms
WHERE#                           # Get current position
STATUS#                          # Get device status
PARAM#                           # Get all parameters
VERSION#                         # Get firmware version
IMEI#                           # Get device IMEI
```


### **Alarm Configuration**

```sms
SPEED,ON,120,1#                 # Enable speed alarm (120 km/h)
LVALM,ON,11.5,1#                # Low voltage alarm (11.5V)
ACCALM,ON,2,1#                  # ACC on/off alarm
PWRALM,ON,1#                    # Power disconnect alarm
SENALM,ON,1#                    # Vibration alarm
SHIFT,ON,500,1#                 # Geo-fence alarm (500m)
```


### **Remote Control**

```sms
RELAY,0#                        # Resume fuel
RELAY,1#                        # Cut fuel immediately  
RELAY,2#                        # Cut fuel safely
ARM#                            # Arm device
DISARM#                         # Disarm device
FACTORY#                        # Factory reset
RESTART#                        # Restart device
```


### **Advanced Settings**

```sms
TIMER,10,300#                   # Upload every 10s (moving), 300s (stopped)
HBT,5#                          # Heartbeat every 5 minutes
LEVEL,3#                        # Vibration sensitivity level 3
SOS,A,+1111,+2222,+3333#        # Set 3 SOS numbers
```


***

## 📊 **Database Schema**

### **Trackers Table**

```sql
CREATE TABLE tracker (
  uuid TEXT PRIMARY KEY,
  id TEXT,                  -- Device IMEI
  name TEXT,               -- Custom tracker name
  license_plate TEXT,      -- Vehicle license plate
  chassis_number TEXT,     -- Vehicle chassis number
  model TEXT,             -- Vehicle model
  color INTEGER,          -- Display color
  phone_number TEXT,      -- SIM card number
  admin_number TEXT,      -- Admin phone number
  sos_numbers TEXT,       -- Emergency contacts (CSV)
  pin TEXT,              -- Device PIN code
  speed_limit INTEGER,   -- Speed alarm threshold
  sleep_limit INTEGER,   -- Sleep mode timeout
  ignition_alarm INTEGER, -- ACC alarm enabled
  power_alarm_sms INTEGER, -- Power alarm SMS
  power_alarm_call INTEGER, -- Power alarm call
  battery INTEGER,        -- Last battery level
  apn TEXT,              -- Network APN
  iccid TEXT,            -- SIM card ICCID
  timestamp TEXT         -- Last update time
);
```


### **Messages Table**

```sql
CREATE TABLE tracker_message (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tracker_uuid TEXT,
  direction INTEGER,      -- 0=Received, 1=Sent
  content TEXT,          -- Message body
  timestamp TEXT,        -- Message time
  FOREIGN KEY (tracker_uuid) REFERENCES tracker(uuid)
);
```


### **Positions Table**

```sql
CREATE TABLE tracker_position (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tracker_uuid TEXT,
  latitude REAL,
  longitude REAL, 
  altitude REAL,
  speed REAL,
  course REAL,
  accuracy REAL,
  timestamp TEXT,
  FOREIGN KEY (tracker_uuid) REFERENCES tracker(uuid)
);
```


***

## 🎨 **Screenshots**

<div align="center">

### **Main Interface**
| Tracker List | Map View | Settings |
|:---:|:---:|:---:|
|  |  |  |

### **Tracker Management**
| Edit Tracker | Commands Menu | Message History |
|:---:|:---:|:---:|
|  |  |  |

</div>

***

## 🔧 **Development**

### **Project Structure**

```
lib/
├── data/              # Data models
│   ├── tracker.dart
│   ├── tracker_position.dart
│   └── tracker_message.dart
├── database/          # SQLite database
│   ├── database.dart
│   ├── tracker_db.dart
│   └── settings_db.dart
├── screens/           # UI screens
│   ├── tracker_list.dart
│   ├── tracker_edit.dart
│   ├── map.dart
│   └── settings.dart
├── utils/             # Utilities
│   ├── sms.dart
│   └── permissions.dart
├── widgets/           # Reusable widgets
│   └── modal.dart
├── locale/            # Internationalization
│   └── app_localizations.dart
└── main.dart         # App entry point
```


### **Build Configuration**

```yaml
# pubspec.yaml
name: trackmate
description: GPS Tracker Management App
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  another_telephony: ^2.0.0
  # ... other dependencies
```


***

## 🤝 **Contributing**

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### **Development Setup**

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and test thoroughly
4. Commit: `git commit -m 'Add amazing feature'`
5. Push: `git push origin feature/amazing-feature`
6. Open a Pull Request

### **Code Style**

- Follow [Flutter Style Guide](https://docs.flutter.dev/resources/effective-dart)
- Use meaningful variable and function names
- Add comments for complex logic
- Ensure null-safety compliance

***

## 📋 **Roadmap**

### **Version 1.1.0** (Upcoming)

- [ ] Real-time tracking server integration
- [ ] Push notifications for alarms
- [ ] Route optimization and analysis
- [ ] Fuel consumption tracking
- [ ] Driver behavior analytics


### **Version 1.2.0** (Future)

- [ ] Fleet management features
- [ ] Advanced reporting system
- [ ] Integration with third-party APIs
- [ ] Voice command support
- [ ] Wear OS companion app

***

## 🔒 **Privacy \& Security**

- **Local Data Storage** - All data stored locally on device
- **SMS Encryption** - Commands use PIN authentication
- **No Cloud Dependency** - Works completely offline
- **Permission Control** - Fine-grained app permissions
- **Open Source** - Full code transparency

***

## 🆘 **Support**

### **Troubleshooting**

- **No SMS Response**: Check SIM credit, signal strength, PIN code
- **GPS Not Fixed**: Ensure unobstructed sky view, check antenna
- **Commands Rejected**: Verify admin number is configured correctly
- **App Crashes**: Check device permissions, restart app


### **Get Help**

- 📧 **Email**: support@trackmate.com
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/trackmate-flutter/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/trackmate-flutter/discussions)
- 📖 **Wiki**: [Documentation](https://github.com/yourusername/trackmate-flutter/wiki)

***

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 TrackMate Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```


***

## 🙏 **Acknowledgments**

- **MiCODUS Technology** - For MV710G tracker documentation
- **Flutter Team** - For the amazing framework
- **MapBox** - For mapping services
- **Community Contributors** - For testing and feedback
- **Open Source Libraries** - Listed in `pubspec.yaml`

***

<div align="center">

**Made with ❤️ for the GPS tracking community**

[⭐ Star this project](https://github.com/yourusername/trackmate-flutter) -  [🍴 Fork](https://github.com/yourusername/trackmate-flutter/fork) -  [📝 Report Bug](https://github.com/yourusername/trackmate-flutter/issues)

</div>
<span style="display:none">[^1][^2][^3][^4][^5]</span>

<div style="text-align: center">⁂</div>

[^1]: mv710g-user-guide-xin-kuan-20.pdf

[^2]: tracker_db.dart

[^3]: tracker.dart

[^4]: menu.dart

[^5]: tracker_edit.dart


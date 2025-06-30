# SOSNow

SOSNow is an iOS application that allows users to send emergency alerts (General Emergency, Fire Alert, Flood Alert) via MQTT, including their current location and personal contact information. The alerts are received and displayed on a web-based map interface powered by a Python Flask server.

## Features

**iOS Application:**
- Send emergency alerts (General Emergency, Fire Alert, Flood Alert).
- Automatically includes current GPS location (latitude and longitude).
- User-configurable name and phone number sent with alerts.
- Real-time status display for MQTT connection and location acquisition.
- Interactive map displaying current user location.

**Python MQTT Server (Web Interface):**
- Subscribes to MQTT alerts from the iOS app.
- Displays active alerts on an interactive Leaflet.js map.
- Shows alert type, location, user name, and user number.
- Provides an "Acknowledge" button to clear alerts from the map and list.

## Setup and Running

### 1. MQTT Broker

Both the iOS app and the Python server are configured to use the public HiveMQ broker (`broker.hivemq.com` on port `1883`). You can change this in `SOSNow/SOSNow/MQTTManager.swift` and `MQTTServer/server.py` if you wish to use your own broker.

### 2. iOS Application Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/leo00000000000000000/SOSnow.git
    cd SOSnow
    ```
2.  **Open in Xcode:**
    Open the `SOSNow.xcodeproj` file in Xcode.
3.  **Add CocoaMQTT Dependency:**
    -   In Xcode, go to `File` > `Add Packages...`
    -   Enter the repository URL: `https://github.com/emqtt/CocoaMQTT.git`
    -   Choose `Up to Next Major Version` and click `Add Package`.
4.  **Location Permissions:**
    Ensure your project's `Info.plist` (which is synthesized from build settings in `project.pbxproj`) includes the `NSLocationWhenInUseUsageDescription` key. This has been added programmatically, but you can verify it in Xcode under your target's Build Settings -> Info.plist values.
5.  **Build and Run:**
    Build and run the app on a simulator or a physical device. Grant location permissions when prompted.
6.  **Configure User Information:**
    Tap the gear icon in the top-right corner of the app to enter your name and phone number. This information will be sent with your alerts.

### 3. Python MQTT Server Setup

1.  **Navigate to the server directory:**
    ```bash
    cd MQTTServer
    ```
2.  **Install dependencies:**
    It's recommended to use a virtual environment:
    ```bash
    python3 -m venv venv
    source venv/bin/activate  # On Windows, use `venv\Scripts\activate`
    pip install -r requirements.txt
    ```
3.  **Run the server:**
    ```bash
    python3 server.py
    ```
    The server will start on `http://127.0.0.1:5000`.

### 4. Viewing Alerts

Open your web browser and navigate to `http://127.0.0.1:5000`. As you send alerts from the iOS app, they will appear as markers on the map and entries in the sidebar. You can click the "Acknowledge" button to clear them.

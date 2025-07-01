import paho.mqtt.client as mqtt
from flask import Flask, render_template, request
from flask_socketio import SocketIO, emit
import json
import threading
import time
import uuid
from math import radians, sin, cos, sqrt, atan2
import requests # Import the requests library
import csv
from datetime import datetime

# CSV Logging Setup
CSV_FILE = 'alerts.csv'
CSV_HEADERS = ['timestamp', 'event_type', 'alert_id', 'type', 'userName', 'userNumber', 'latitude', 'longitude']

def initialize_csv():
    try:
        with open(CSV_FILE, 'x', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(CSV_HEADERS)
        print(f"Initialized new CSV file: {CSV_FILE}")
    except FileExistsError:
        print(f"CSV file already exists: {CSV_FILE}")
    except Exception as e:
        print(f"Error initializing CSV file: {e}")

def log_alert_to_csv(event_type, alert_data):
    try:
        with open(CSV_FILE, 'a', newline='') as file:
            writer = csv.writer(file)
            timestamp = datetime.now().isoformat()
            row = [
                timestamp,
                event_type,
                alert_data.get('alertId', ''),
                alert_data.get('type', ''),
                alert_data.get('userName', ''),
                alert_data.get('userNumber', ''),
                alert_data.get('latitude', ''),
                alert_data.get('longitude', '')
            ]
            writer.writerow(row)
        print(f"Logged {event_type} event to CSV for alert ID: {alert_data.get('alertId', '')}")
    except Exception as e:
        print(f"Error logging to CSV: {e}")

# Flask App Setup
app = Flask(__name__, static_folder='static', template_folder='static')
app.config['SECRET_KEY'] = 'your_secret_key' # Replace with a strong secret key
socketio = SocketIO(app, cors_allowed_origins="*")

# MQTT Broker Configuration
MQTT_BROKER = "broker.hivemq.com"
MQTT_PORT = 1883
MQTT_TOPIC = "sos/alert"

# Global list to store active alerts
active_alerts = {}

# Coverage settings (default values)
coverage_center = {'lat': 0.0, 'lng': 0.0} # Will be updated with server's location
coverage_radius = 1000.0 # Default radius in kilometers

# Function to get server's public IP
def get_public_ip():
    try:
        response = requests.get('https://api.ipify.org?format=json')
        response.raise_for_status() # Raise an exception for HTTP errors
        return response.json()['ip']
    except requests.exceptions.RequestException as e:
        print(f"Error getting public IP: {e}")
        return None

# Function to get geolocation from IP
def get_geolocation_from_ip(ip_address):
    try:
        response = requests.get(f'http://ip-api.com/json/{ip_address}')
        response.raise_for_status()
        data = response.json()
        if data and data['status'] == 'success':
            return {'lat': data['lat'], 'lng': data['lon']}
        else:
            print(f"Geolocation API error: {data.get('message', 'Unknown error')}")
            return None
    except requests.exceptions.RequestException as e:
        print(f"Error getting geolocation: {e}")
        return None

# Initialize coverage_center with server's location
public_ip = get_public_ip()
if public_ip:
    server_location = get_geolocation_from_ip(public_ip)
    if server_location:
        coverage_center = server_location
        print(f"Server's initial location set to: {coverage_center}")
    else:
        print("Could not determine server's geolocation. Using default (0,0).")
else:
    print("Could not determine server's public IP. Using default (0,0).")

# Haversine formula to calculate distance between two lat/lon points
def haversine_distance(lat1, lon1, lat2, lon2):
    R = 6371  # Radius of Earth in kilometers

    lat1_rad = radians(lat1)
    lon1_rad = radians(lon1)
    lat2_rad = radians(lat2)
    lon2_rad = radians(lon2)

    dlon = lon2_rad - lon1_rad
    dlat = lat2_rad - lat1_rad

    a = sin(dlat / 2)**2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    distance = R * c
    return distance

def is_within_coverage(alert_lat, alert_lon):
    if coverage_radius == 0: # If radius is 0, no alerts are within coverage
        return False
    distance = haversine_distance(coverage_center['lat'], coverage_center['lng'], alert_lat, alert_lon)
    return distance <= coverage_radius

# MQTT Client Callbacks
def on_connect(client, userdata, flags, rc):
    print(f"MQTT Connected with result code {rc}")
    client.subscribe(MQTT_TOPIC)

def on_message(client, userdata, msg):
    print(f"MQTT Message Received - Topic: {msg.topic} | Payload: {msg.payload.decode()}")
    try:
        payload_data = json.loads(msg.payload.decode())
        
        alert_lat = payload_data.get('latitude')
        alert_lon = payload_data.get('longitude')

        # Only process and store if location data is valid and within current coverage
        if isinstance(alert_lat, (int, float)) and isinstance(alert_lon, (int, float)):
            if is_within_coverage(alert_lat, alert_lon):
                # Generate a unique ID for the alert
                alert_id = str(uuid.uuid4())
                
                alert_info = {
                    'alertId': alert_id,
                    'type': payload_data.get('type', 'N/A'),
                    'userName': payload_data.get('userName', 'N/A'),
                    'userNumber': payload_data.get('userNumber', 'N/A'),
                    'latitude': alert_lat,
                    'longitude': alert_lon
                }
                active_alerts[alert_id] = alert_info

                log_alert_to_csv('received', alert_info)

                # Emit the message to all connected WebSocket clients
                socketio.emit('mqtt_message', alert_info)
                print(f"Emitted new alert with ID: {alert_id} (within coverage)")
            else:
                print(f"Alert at ({alert_lat}, {alert_lon}) is outside coverage range. Ignoring.")
        else:
            print("Invalid location data in MQTT payload. Ignoring.")

    except Exception as e:
        print(f"Error processing MQTT message or emitting to WebSocket: {e}")

# MQTT Client Thread
def mqtt_thread():
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    while True:
        try:
            print(f"Attempting to connect to MQTT broker at {MQTT_BROKER}:{MQTT_PORT}...")
            client.connect(MQTT_BROKER, MQTT_PORT, 60)
            client.loop_forever()
        except Exception as e:
            print(f"MQTT connection error: {e}. Retrying in 5 seconds...")
            time.sleep(5)

# Flask Routes
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/favicon.ico')
def favicon():
    return app.send_static_file('favicon.ico')

# WebSocket Events
@socketio.on('connect')
def test_connect():
    print('Client connected')
    # Send current coverage settings and filtered active alerts to the newly connected client
    filtered_alerts = []
    for alert_id, alert_info in list(active_alerts.items()): # Use list() to avoid RuntimeError during iteration if active_alerts changes
        payload_data = json.loads(alert_info['payload'])
        alert_lat = payload_data.get('latitude')
        alert_lon = payload_data.get('longitude')
        if isinstance(alert_lat, (int, float)) and isinstance(alert_lon, (int, float)) and is_within_coverage(alert_lat, alert_lon):
            filtered_alerts.append(alert_info)
        else:
            # If an alert is no longer in coverage, remove it for this client
            # This handles cases where coverage changes while client is connected
            del active_alerts[alert_id] # Remove from global list if out of coverage
            socketio.emit('remove_alert', alert_id) # Tell other clients to remove it

    emit('initial_data', {
        'coverage_center': coverage_center,
        'coverage_radius': coverage_radius,
        'active_alerts': filtered_alerts
    })

@socketio.on('acknowledge_alert')
def acknowledge_alert(alert_id):
    print(f"Received acknowledgment for alert ID: {alert_id}")
    if alert_id in active_alerts:
        alert_info = active_alerts[alert_id]
        del active_alerts[alert_id]
        log_alert_to_csv('acknowledged', alert_info)
        # Broadcast to all clients to remove this alert
        socketio.emit('remove_alert', alert_id)
        print(f"Alert {alert_id} acknowledged and removed.")
    else:
        print(f"Alert {alert_id} not found for acknowledgment.")

@socketio.on('update_coverage_settings')
def update_coverage_settings(data):
    global coverage_center, coverage_radius
    new_center = data.get('center')
    new_radius = data.get('radius')

    if new_center and isinstance(new_center.get('lat'), (int, float)) and isinstance(new_center.get('lng'), (int, float)):
        coverage_center = new_center
    if isinstance(new_radius, (int, float)):
        coverage_radius = new_radius

    print(f"Coverage settings updated: Center={coverage_center}, Radius={coverage_radius} km")

    # Re-evaluate all active alerts against the new coverage
    alerts_to_remove = []
    for alert_id, alert_info in list(active_alerts.items()):
        payload_data = json.loads(alert_info['payload'])
        alert_lat = payload_data.get('latitude')
        alert_lon = payload_data.get('longitude')

        if isinstance(alert_lat, (int, float)) and isinstance(alert_lon, (int, float)):
            if not is_within_coverage(alert_lat, alert_lon):
                alerts_to_remove.append(alert_id)
        else:
            alerts_to_remove.append(alert_id)

    for alert_id in alerts_to_remove:
        if alert_id in active_alerts:
            del active_alerts[alert_id]
            socketio.emit('remove_alert', alert_id)
            print(f"Removed alert {alert_id} (out of coverage).")


@socketio.on('disconnect')
def test_disconnect():
    print('Client disconnected')

if __name__ == '__main__':
    initialize_csv()
    # Start MQTT client in a separate thread
    mqtt_client_thread = threading.Thread(target=mqtt_thread)
    mqtt_client_thread.daemon = True # Allow the thread to exit when the main program exits
    mqtt_client_thread.start()

    # Start Flask-SocketIO server
    print("Starting Flask-SocketIO server on http://127.0.0.1:5000")
    socketio.run(app, debug=True, allow_unsafe_werkzeug=True)
import paho.mqtt.client as mqtt
from flask import Flask, render_template, request
from flask_socketio import SocketIO, emit
import json
import threading
import time
import uuid

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

# MQTT Client Callbacks
def on_connect(client, userdata, flags, rc):
    print(f"MQTT Connected with result code {rc}")
    client.subscribe(MQTT_TOPIC)

def on_message(client, userdata, msg):
    print(f"MQTT Message Received - Topic: {msg.topic} | Payload: {msg.payload.decode()}")
    try:
        payload_data = json.loads(msg.payload.decode())
        
        # Generate a unique ID for the alert
        alert_id = str(uuid.uuid4())
        
        # Add alert to active_alerts dictionary
        alert_info = {
            'alertId': alert_id,
            'topic': msg.topic,
            'payload': msg.payload.decode(),
            'userName': payload_data.get('userName', 'N/A'),
            'userNumber': payload_data.get('userNumber', 'N/A')
        }
        active_alerts[alert_id] = alert_info

        # Emit the message to all connected WebSocket clients
        socketio.emit('mqtt_message', alert_info)
        print(f"Emitted new alert with ID: {alert_id}")

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

# WebSocket Events
@socketio.on('connect')
def test_connect():
    print('Client connected')
    # Send current active alerts to the newly connected client
    emit('current_alerts', list(active_alerts.values()))

@socketio.on('acknowledge_alert')
def acknowledge_alert(alert_id):
    print(f"Received acknowledgment for alert ID: {alert_id}")
    if alert_id in active_alerts:
        del active_alerts[alert_id]
        # Broadcast to all clients to remove this alert
        socketio.emit('remove_alert', alert_id)
        print(f"Alert {alert_id} acknowledged and removed.")
    else:
        print(f"Alert {alert_id} not found for acknowledgment.")

@socketio.on('disconnect')
def test_disconnect():
    print('Client disconnected')

if __name__ == '__main__':
    # Start MQTT client in a separate thread
    mqtt_client_thread = threading.Thread(target=mqtt_thread)
    mqtt_client_thread.daemon = True # Allow the thread to exit when the main program exits
    mqtt_client_thread.start()

    # Start Flask-SocketIO server
    print("Starting Flask-SocketIO server on http://127.0.0.1:5000")
    socketio.run(app, debug=True, allow_unsafe_werkzeug=True)
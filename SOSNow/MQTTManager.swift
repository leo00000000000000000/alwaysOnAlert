//
//  MQTTManager.swift
//  SOSNow
//
//  Created by Leo Ricaborda on 6/30/25.
//

import Foundation
import
CocoaMQTT

class MQTTManager: NSObject, ObservableObject {
    private var mqtt: CocoaMQTT!
    @Published var isConnected = false

    // MARK: - Configuration
    private let mqttHost = "broker.hivemq.com"
    private let mqttPort: UInt16 = 1883
    private let mqttTopic = "sos/alert"

    override init() {
        super.init()
        setupMQTT()
    }

    private func setupMQTT() {
        let clientID = "CocoaMQTT-\(UUID().uuidString)"
        mqtt = CocoaMQTT(clientID: clientID, host: mqttHost, port: mqttPort)
        mqtt.keepAlive = 60
        mqtt.delegate = self
        print("MQTT Manager initialized with host: \(mqttHost) and port: \(mqttPort)")
    }

    func connect() {
        print("Attempting to connect to MQTT broker...")
        mqtt.connect()
    }

    func disconnect() {
        print("Disconnecting from MQTT broker...")
        mqtt.disconnect()
    }

    func publish(message: String) {
        if isConnected {
            mqtt.publish(mqttTopic, withString: message, qos: .qos1, retained: false)
            print("Published message: \(message) to topic: \(mqttTopic)")
        } else {
            print("MQTT not connected. Cannot publish message.")
        }
    }
}

extension MQTTManager: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            isConnected = true
            print("MQTT Connected! ACK: \(ack.rawValue)")
        } else {
            isConnected = false
            print("MQTT Connection Failed! ACK: \(ack.rawValue)")
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("Message published: \(message.string ?? "")")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("Message published acked: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        print("Message received: \(message.string ?? "") on topic \(message.topic)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        print("Subscribed topics: \(success), failed: \(failed)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        print("Unsubscribed topics: \(topics)")
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("MQTT Ping")
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("MQTT Pong")
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        isConnected = false
        if let error = err {
            print("MQTT Disconnected with error: \(error.localizedDescription)")
        } else {
            print("MQTT Disconnected!")
        }
    }
}

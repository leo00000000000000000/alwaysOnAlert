//
//  ContentView.swift
//  SOSNow
//
//  Created by Leo Ricaborda on 6/30/25.
//

import SwiftUI

import CoreLocation
import MapKit // Import MapKit for the Map view

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var locationManager = LocationManager()
    @StateObject private var mqttManager = MQTTManager()
    @State private var confirmationMessage: String? = nil

    private var isReadyToSend: Bool {
        mqttManager.isConnected && locationManager.location != nil
    }

    private var statusText: String {
        if mqttManager.isConnected {
            return String(localized: "online")
        } else {
            return String(localized: "offline")
        }
    }

    private var statusColor: Color {
        return mqttManager.isConnected ? .green : .red
    }

    var body: some View {
        NavigationView { // Wrap with NavigationView
            GeometryReader { geometry in // GeometryReader starts here
                VStack(spacing: 20) {
                    HStack {
                        Text("SOSNow")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(statusText)
                            .font(.headline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(statusColor.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .onTapGesture {
                                if !mqttManager.isConnected {
                                    mqttManager.connect()
                                }
                            }
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        
                    }
                    .padding(.bottom, 20)

                    if let message = confirmationMessage {
                        Text(message)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(10)
                            .transition(.opacity)
                    }

                    // Map View
                    Map {
                        UserAnnotation()
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .mapControlVisibility(.automatic)
                        .frame(height: geometry.size.height * 0.4)
                        .cornerRadius(15)
                        .shadow(radius: 5)

                    Spacer()

                    Button(action: {
                        sendAlert(type: "general_emergency")
                    }) {
                        Label("general_emergency", systemImage: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.9))
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    .disabled(!isReadyToSend)
                    .opacity(isReadyToSend ? 1.0 : 0.5)

                    Button(action: {
                        sendAlert(type: "fire_alert")
                    }) {
                        Label("fire_alert", systemImage: "flame.fill")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.9))
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    .disabled(!isReadyToSend)
                    .opacity(isReadyToSend ? 1.0 : 0.5)

                    // New Flood Alert Button
                    Button(action: {
                        sendAlert(type: "flood_alert")
                    }) {
                        Label("flood_alert", systemImage: "cloud.heavyrain.fill")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple.opacity(0.9))
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    .disabled(!isReadyToSend)
                    .opacity(isReadyToSend ? 1.0 : 0.5)

                    Spacer()
                }
                // Map and other UI elements
        }
    }
}

    private func setup() {
        locationManager.requestPermission()
        mqttManager.connect()
    }

    private func sendAlert(type: String) {
        guard let location = locationManager.location else {
            print("Error: Location not available when trying to send alert.")
            confirmationMessage = String(localized: "location_not_available")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.confirmationMessage = nil
            }
            return
        }

        var payload: [String: Any] = [
            "type": type,
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude
        ]

        if !appState.userName.isEmpty {
            payload["userName"] = appState.userName
        }
        if !appState.userNumber.isEmpty {
            payload["userNumber"] = appState.userNumber
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                mqttManager.publish(message: jsonString)
                let localizedAlertType = NSLocalizedString(type, comment: "")
                confirmationMessage = String(format: NSLocalizedString("sos_sent", comment: ""), localizedAlertType)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.confirmationMessage = nil
                }
            }
        } catch {
            print("Error encoding JSON: \(error.localizedDescription)")
            confirmationMessage = String(localized: "error_sending_sos")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.confirmationMessage = nil
            }
        }
    }
}

#Preview {
    ContentView()
}
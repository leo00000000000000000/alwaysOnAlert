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
    @StateObject private var locationManager = LocationManager()
    @StateObject private var mqttManager = MQTTManager()
    @State private var confirmationMessage: String? = nil

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userNumber") private var userNumber: String = ""

    private var isReadyToSend: Bool {
        mqttManager.isConnected && locationManager.location != nil
    }

    private var statusText: String {
        if !mqttManager.isConnected {
            return "Not Connected to MQTT"
        } else if locationManager.authorizationStatus == .notDetermined {
            return "Location permission not determined."
        } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
            return "Location access denied. Please enable in Settings."
        } else if locationManager.location == nil {
            return "Acquiring Location..."
        } else {
            return "ONLINE"
        }
    }

    private var statusColor: Color {
        if isReadyToSend {
            return .green
        } else if mqttManager.isConnected && locationManager.location == nil {
            return .orange
        } else {
            return .red
        }
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
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), showsUserLocation: true, userTrackingMode: .constant(.follow))
                        .frame(height: geometry.size.height * 0.4)
                        .cornerRadius(15)
                        .shadow(radius: 5)

                    Spacer()

                    Button(action: {
                        sendAlert(type: "general_emergency")
                    }) {
                        Label("General Emergency", systemImage: "exclamationmark.triangle.fill")
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
                        Label("Fire Alert", systemImage: "flame.fill")
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
                        Label("Flood Alert", systemImage: "cloud.heavyrain.fill")
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
                .padding()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear(perform: setup)
                .navigationBarHidden(true) // Hide default navigation bar
            } // GeometryReader ends here
        }
    }

    private func setup() {
        locationManager.requestPermission()
        mqttManager.connect()
    }

    private func sendAlert(type: String) {
        guard let location = locationManager.location else {
            print("Error: Location not available when trying to send alert.")
            confirmationMessage = "Error: Location not available!"
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

        if !userName.isEmpty {
            payload["userName"] = userName
        }
        if !userNumber.isEmpty {
            payload["userNumber"] = userNumber
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                mqttManager.publish(message: jsonString)
                confirmationMessage = "SOS Sent: \(type.replacingOccurrences(of: "_", with: " ").capitalized)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.confirmationMessage = nil
                }
            }
        } catch {
            print("Error encoding JSON: \(error.localizedDescription)")
            confirmationMessage = "Error sending SOS!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.confirmationMessage = nil
            }
        }
    }
}

#Preview {
    ContentView()
}
//
//  SettingsView.swift
//  SOSNow
//
//  Created by Leo Ricaborda on 6/30/25.
//

import SwiftUI
import Foundation


struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("userName") private var userName: String = ""
    
    @State private var isPhoneNumberValid: Bool = false
    @State private var isShowingOTPView = false
    @State private var isShowingIDVerificationView = false

    var body: some View {
        Form {
            Section(header: Text("User Information")) {
                HStack {
                    TextField("Your Name", text: $userName)
                    Spacer()
                    Button(action: {
                        isShowingIDVerificationView = true
                    }) {
                        Image(systemName: "person.text.rectangle")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle()) // Remove default button styling
                }
                HStack {
                    NavigationLink(destination: CountryPickerView().environmentObject(appState)) {
                        HStack {
                            Text("\(appState.selectedCountry.flag()) \(appState.selectedCountry.dialCode)")
                            Spacer()
                        }
                    }
                    .listRowSeparator(.hidden)

                    PhoneNumberInputView(
                        phoneNumber: $appState.userNumber,
                        isValidNumber: $isPhoneNumberValid,
                        placeholder: "Your Phone Number"
                    )
                    
                    Button(action: {
                        // Trigger OTP verification
                        print("SettingsView - Verify button tapped. Current national phoneNumber: \(appState.userNumber)")
                        isShowingOTPView = true
                    }) {
                        Text("Verify")
                    }
                    .disabled(!isPhoneNumberValid)
                }
            }
            
            Section(header: Text("Language")) {
                Picker("Language", selection: $appState.language) {
                    ForEach(supportedLanguages) {
                        language in
                        Text(language.name).tag(language.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            Text("This information will be sent with your SOS alerts.")
                .font(.footnote)
                .foregroundColor(.gray)

            Section(header: Text("App Version")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A")
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A")
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $isShowingOTPView) {
            OTPView(phoneNumber: $appState.userNumber, isShowingOTPView: $isShowingOTPView)
                .environmentObject(appState)
        }
        .sheet(isPresented: $isShowingIDVerificationView) {
            IDVerificationView()
        }
        .onAppear {
            print("SettingsView - onAppear: appState.userNumber = \(appState.userNumber)")
        }
        .onDisappear {
            print("SettingsView - onDisappear: appState.userNumber = \(appState.userNumber)")
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(AppState())
    }
}

//
//  SettingsView.swift
//  SOSNow
//
//  Created by Leo Ricaborda on 6/30/25.
//

import SwiftUI

struct Language: Identifiable, Hashable {
    let id: String
    let name: String
}

let supportedLanguages: [Language] = [
    Language(id: "en", name: "English"),
    Language(id: "tl", name: "Tagalog"),
    Language(id: "ceb", name: "Bisaya"),
    Language(id: "zh", name: "Chinese"),
    Language(id: "ko", name: "Korean")
]

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userNumber") private var userNumber: String = ""

    var body: some View {
        Form {
            Section(header: Text("User Information")) {
                TextField("Your Name", text: $userName)
                    .autocapitalization(.words)
                TextField("Your Phone Number", text: $userNumber)
                    .keyboardType(.phonePad)
            }
            
            Section(header: Text("Language")) {
                Picker("Language", selection: $appState.language) {
                    ForEach(supportedLanguages) { language in
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
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}

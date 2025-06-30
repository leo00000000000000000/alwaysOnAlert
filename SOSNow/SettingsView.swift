//
//  SettingsView.swift
//  SOSNow
//
//  Created by Leo Ricaborda on 6/30/25.
//

import SwiftUI

struct SettingsView: View {
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
            Text("This information will be sent with your SOS alerts.")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}

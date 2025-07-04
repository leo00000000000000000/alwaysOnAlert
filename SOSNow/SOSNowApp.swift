//
//  SOSNowApp.swift
//  SOSNow
//
//  Created by Leo Ricaborda on 6/30/25.
//

import SwiftUI


@main
struct SOSNowApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environment(\.locale, .init(identifier: appState.language))
                .id(appState.language)
        }
    }
}

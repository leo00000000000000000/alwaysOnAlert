
import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var language: String = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en" {
        didSet {
            UserDefaults.standard.set(language, forKey: "selectedLanguage")
        }
    }
}

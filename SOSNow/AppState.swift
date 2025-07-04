
import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var language: String = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en" {
        didSet {
            UserDefaults.standard.set(language, forKey: "selectedLanguage")
        }
    }

    @Published var idImage: Data? = UserDefaults.standard.data(forKey: "idImage") {
        didSet {
            UserDefaults.standard.set(idImage, forKey: "idImage")
        }
    }

    @Published var idVerificationStatus: String = UserDefaults.standard.string(forKey: "idVerificationStatus") ?? "Not Verified" {
        didSet {
            UserDefaults.standard.set(idVerificationStatus, forKey: "idVerificationStatus")
        }
    }

    @Published var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "" {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }

    @Published var userNumber: String = UserDefaults.standard.string(forKey: "userNumber") ?? "" {
        didSet {
            UserDefaults.standard.set(userNumber, forKey: "userNumber")
        }
    }

    @Published var selectedCountryId: String = UserDefaults.standard.string(forKey: "selectedCountryId") ?? "US" {
        didSet {
            UserDefaults.standard.set(selectedCountryId, forKey: "selectedCountryId")
        }
    }

    var selectedCountry: Country {
        get {
            allCountries.first(where: { $0.id == selectedCountryId }) ?? allCountries[0]
        }
        set {
            selectedCountryId = newValue.id
        }
    }
}

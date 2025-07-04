
//
//  Models.swift
//  SOSNow
//
//  Created by Leo Ricaborda on 7/3/25.
//

import Foundation

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

struct Country: Identifiable, Hashable {
    let id: String // ISO country code (e.g., "US", "PH")
    let name: String
    let dialCode: String
}

// A simplified list of countries for demonstration. In a real app, this would be more comprehensive.
let allCountries: [Country] = [
    Country(id: "US", name: "United States", dialCode: "+1"),
    Country(id: "PH", name: "Philippines", dialCode: "+63"),
    Country(id: "CA", name: "Canada", dialCode: "+1"),
    Country(id: "GB", name: "United Kingdom", dialCode: "+44"),
    Country(id: "AU", name: "Australia", dialCode: "+61"),
    Country(id: "SG", name: "Singapore", dialCode: "+65"),
    Country(id: "JP", name: "Japan", dialCode: "+81"),
    Country(id: "KR", name: "South Korea", dialCode: "+82"),
    Country(id: "CN", name: "China", dialCode: "+86"),
    Country(id: "DE", name: "Germany", dialCode: "+49"),
    Country(id: "FR", name: "France", dialCode: "+33"),
    Country(id: "IN", name: "India", dialCode: "+91")
].sorted { $0.name < $1.name }

extension Country {
    func flag() -> String {
        let base: UInt32 = 0x1F1E6
        guard id.count == 2 else { return "" }
        return String(UnicodeScalar(base + id.uppercased().unicodeScalars.first!.value - 0x41)!) + String(UnicodeScalar(base + id.uppercased().unicodeScalars.last!.value - 0x41)!)
    }
}

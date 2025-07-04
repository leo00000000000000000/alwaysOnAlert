

//
//  CountryPickerView.swift
//  SOSNow
//
//  Created by Leo Ricaborda on 7/3/25.
//

import SwiftUI
import Foundation


struct CountryPickerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationView {
            List(allCountries) { country in
                Button(action: {
                    appState.selectedCountry = country
                }) {
                    HStack {
                        Text("\(country.flag()) \(country.name) (\(country.dialCode))")
                        Spacer()
                        if country.id == appState.selectedCountry.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("Select Country")
        }
    }
}

struct CountryPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CountryPickerView()
            .environmentObject(AppState())
    }
}


//
//  SettingsView.swift
//  smAIrtColorizer
//
//  Created by Fakhrul Fauzi on 22/04/2025.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Configuration")) {
                    NavigationLink(destination: URLInputView()) {
                        HStack {
                            Text("Configure URL")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

//
//  SettingsView.swift
//  smAIrtColorizer
//
//  Created by Fakhrul Fauzi on 22/04/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("backendURL") private var backendURL: String = ""
    @State private var showAboutSection = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        List {
            // Header Section
            Section {
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "8D9FFF"), Color(hex: "BC82F3")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: .black.opacity(0.1), radius: 5)
                        
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("smAIrtColorizer")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Version 1.0.0")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                .listRowBackground(
                    colorScheme == .dark ? 
                        Color(.systemGray6) : Color(.systemGray6).opacity(0.3)
                )
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

            // Server Configuration Section
            Section {
                NavigationLink(destination: URLInputView()) {
                    HStack {
                        Image(systemName: "server.rack")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "8D9FFF"), Color(hex: "BC82F3")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Server Configuration")
                                .font(.system(size: 16, weight: .medium))
                            
                            if backendURL.isEmpty {
                                Text("Not configured")
                                    .font(.system(size: 13))
                                    .foregroundColor(.red)
                            } else {
                                Text(backendURL)
                                    .font(.system(size: 13))
                                    .foregroundColor(.green)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        
                        Spacer()
                        
                        
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Configuration")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "BC82F3"))
                    .textCase(nil)
            }
            
            // Theme Section
            Section {
                HStack {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FF6778"), Color(hex: "FFBA71")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                    
                    Text("App Theme")
                        .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                    
                    Text("System")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Appearance")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "FF6778"))
                    .textCase(nil)
            }
            
            // About Section
            Section {
                DisclosureGroup(
                    isExpanded: $showAboutSection,
                    content: {
                        VStack(alignment: .leading, spacing: 15) {
                            // Description
                            Text("smAIrtColorizer is an advanced image and video colorization app powered by AI technology. Turn your black and white memories into vibrant colored masterpieces.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.top, 5)
                            
                            // Developer Info
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color(hex: "BC82F3"))
                                Text("Developed by Fakhrul Fauzi")
                                    .font(.system(size: 14))
                            }
                            
                            // Website
                            Button(action: {
                                // Open website if needed
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(Color(hex: "BC82F3"))
                                    Text("Visit Website")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // Privacy Policy
                            Button(action: {
                                // Open privacy policy if needed
                            }) {
                                HStack {
                                    Image(systemName: "hand.raised.fill")
                                        .foregroundColor(Color(hex: "BC82F3"))
                                    Text("Privacy Policy")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    },
                    label: {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "C686FF"), Color(hex: "F5B9EA")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(8)
                            
                            Text("About")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .padding(.vertical, 4)
                    }
                )
            } header: {
                Text("Information")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "C686FF"))
                    .textCase(nil)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Settings")
        .background(Color(.systemBackground))
    }
}

// Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}

import SwiftUI
import Network

struct MainView: View {
    @State private var animateGradient = false
    @AppStorage("backendURL") private var backendURL: String = "" // Save URL persistently
    @State private var isConnected = true // Network connection status
    @State private var displayedText = "" // Text for typewriter animation
    private let fullText = "smAIrtColorizer" // Full text to display
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var body: some View {
        TabView {
            // Main Tab
            NavigationStack {
                ZStack {
                    VStack(spacing: 30) {
                        // Network Status Indicator
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: isConnected ? "network" : "network.slash")
                                    .foregroundColor(.white)
                                Text(isConnected ? "Connected" : "No Connection")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isConnected ? Color.green : Color.red)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                            Spacer()
                        }
                        .padding(.top, 20)

                        Spacer()

                        // App Icon
                        Image(systemName: "theatermask.and.paintbrush.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Typewriter Animated Title
                        Text(displayedText)
                            .font(.system(size: 40, weight: .heavy, design: .default))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .onAppear {
                                startTypewriterAnimation()
                            }

                        Spacer()

                        // Buttons Section
                        VStack(spacing: 20) {
                            // "Let's Colorize" Button
                            ZStack {
                                if !backendURL.isEmpty {
                                    GlowEffect(size: CGSize(width: 280, height: 50)) // Custom size for the glow effect
                                }

                                NavigationLink(destination: ContentView(backendURL: backendURL)) {
                                    Label("Let's Colorize", systemImage: "paintbrush")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .frame(maxWidth: 250)
                                        .padding()
                                        .background(.white)
                                        .foregroundColor(Color.accentColor)
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                                }
                                .disabled(backendURL.isEmpty)
                                .opacity(backendURL.isEmpty ? 0.5 : 1.0)
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }
                .onAppear {
                    startNetworkMonitoring()
                }
                .onDisappear {
                    stopNetworkMonitoring()
                }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            .tabItem {
                Label("History", systemImage: "clock")
            }

            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }

    // Start monitoring network status
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    private func stopNetworkMonitoring() {
        monitor.cancel()
    }

    // Typewriter Animation
    private func startTypewriterAnimation() {
        displayedText = ""
        var currentIndex = 0

        func updateText() {
            if currentIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
                displayedText.append(fullText[index])
                currentIndex += 1

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    updateText()
                }
            }
        }

        updateText()
    }
}

// Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

import SwiftUI
import Network

// Main Page
struct MainView: View {
    @State private var animateGradient = false
    @AppStorage("backendURL") private var backendURL: String = "" // Save URL persistently
    @State private var isConnected = true // Network connection status
    @State private var displayedText = "" // Text for typewriter animation
    private let fullText = "smAIrtColorizer" // Full text to display
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var body: some View {
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
                        NavigationLink(destination: ContentView(backendURL: backendURL)) {
                            Label("Let's Colorize", systemImage: "paintbrush")
                                .font(.headline)
                                .fontWeight(.medium)
                                .frame(maxWidth: 250)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                        }
                        .disabled(backendURL.isEmpty) // Disable if URL is not set
                        .opacity(backendURL.isEmpty ? 0.5 : 1.0)

                        // "Configure URL" Button
                        NavigationLink(destination: URLInputView()) {
                            Label("Configure URL", systemImage: "gear")
                                .font(.headline)
                                .fontWeight(.regular)
                                .frame(maxWidth: 250)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.accentColor, lineWidth: 2)
                                )
                                .foregroundColor(.accentColor)
                        }
                    }

                    Spacer()

                    // Footer
                    Text("Version 1.0.0")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                }
                .padding()
            }
            .onAppear {
                startNetworkMonitoring()
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

    // Typewriter Animation
    private func startTypewriterAnimation() {
        displayedText = ""
        var currentIndex = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if currentIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
                displayedText.append(fullText[index])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

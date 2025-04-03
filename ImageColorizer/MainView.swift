import SwiftUI
import Network

// Main Page
struct MainView: View {
    @State private var animateGradient = false
    @AppStorage("backendURL") private var backendURL: String = "" // Save URL persistently
    @State private var isConnected = true // Network connection status
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var body: some View {
        NavigationStack {
            ZStack {
                // Network Status Indicator
                VStack {
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
                    .padding(.top, 10)
                    Spacer()
                }

                // Main Content
                VStack(spacing: 10) {
                    Spacer()

                    // Icon
                    Image(systemName: "theatermask.and.paintbrush.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Animated Title
                    Text("smAIrtColorizer")
                        .font(.system(size: 36, weight: .heavy, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: animateGradient ? .topLeading : .bottomLeading,
                                endPoint: animateGradient ? .bottomTrailing : .topTrailing
                            )
                        )
                        .hueRotation(.degrees(animateGradient ? 45 : 0))
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5)) {
                                animateGradient.toggle()
                            }
                        }

                    Spacer()

                    // Buttons
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
                        .padding(.horizontal, 20)
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
                        .padding(.horizontal, 20)
                    }

                    Spacer()
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

}

// Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

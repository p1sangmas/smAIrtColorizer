import SwiftUI
import Network

struct MainView: View {
    @State private var animateGradient = false
    @AppStorage("backendURL") private var backendURL: String = "" // Save URL persistently
    @State private var isConnected = true // Network connection status
    @State private var displayedText = "" // Text for typewriter animation
    @State private var showConnectionToast = false // Animation for connection status
    private let fullText = "smAIrtColorizer" // Full text to display
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // Color theme
    private let primaryGradient = LinearGradient(
        colors: [Color(hex: "8D9FFF"), Color(hex: "BC82F3")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        TabView {
            // Main Tab
            NavigationStack {
                ZStack {
                    // Background
                    backgroundView
                    
                    // Content
                    VStack(spacing: 30) {
                        // Network Status Indicator
                        networkStatusView
                        
                        Spacer()
                        
                        // Logo and App Title Area
                        appTitleView
                        
                        Spacer()
                        
                        // Buttons Section
                        buttonSectionView
                        
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
                Label("Home", systemImage: "house.fill")
            }
            
            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .tint(Color(hex: "BC82F3")) // Apply the accent color to the whole TabView
    }
    
    // MARK: - Extracted Views
    
    private var backgroundView: some View {
        Image("background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .blur(radius: 30)
            .opacity(0.7)
    }
    
    private var networkStatusView: some View {
        HStack {
            Spacer()
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showConnectionToast.toggle()
                }
            }) {
                networkStatusIcon
            }
            .overlay(connectionToastView)
        }
        .padding(.top, 20)
        .padding(.trailing)
    }
    
    private var networkStatusIcon: some View {
        Image(systemName: isConnected ? "wifi" : "wifi.slash")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isConnected ? .green : .red)
            .padding(8)
            .background(Color(.systemBackground).opacity(0.8))
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var connectionToastView: some View {
        if showConnectionToast {
            Text(isConnected ? "Connected" : "No Connection")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isConnected ? Color.green : Color.red)
                .cornerRadius(20)
                .offset(x: -60)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0, anchor: .trailing).combined(with: .opacity),
                    removal: .scale(scale: 0, anchor: .trailing).combined(with: .opacity)
                ))
        }
    }
    
    private var appTitleView: some View {
        VStack(spacing: 24) {
            // App Icon with animated glow
            appIconView
                .padding(.bottom, 10)
            
            // Typewriter Animated Title
            titleTextView
            
            // Tagline
            Text("Transform your memories with AI")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.top, -15)
        }
        .padding(.bottom, 50)
    }
    
    private var appIconView: some View {
        ZStack {
            Circle()
                .fill(Color(.systemBackground).opacity(0.8))
                .frame(width: 110, height: 110)
                .shadow(color: Color.black.opacity(0.1), radius: 10)
            
            GlowEffect(size: CGSize(width: 110, height: 110))
                .clipShape(Circle())
            
            appIconSymbol
        }
    }
    
    private var appIconSymbol: some View {
        Image(systemName: "wand.and.stars")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 50)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "BC82F3"), Color(hex: "FF6778")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private var titleTextView: some View {
        Text(displayedText)
            .font(.system(size: 38, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "8D9FFF"), Color(hex: "BC82F3"), Color(hex: "FF6778")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            .onAppear {
                startTypewriterAnimation()
            }
    }
    
    private var buttonSectionView: some View {
        VStack(spacing: 20) {
            // "Let's Colorize" Button
            colorizeButtonView
                .padding(.bottom, 30)
            
            if backendURL.isEmpty {
                setupHintView
            }
        }
    }
    
    private var colorizeButtonView: some View {
        ZStack {
            if !backendURL.isEmpty {
                GlowEffect(size: CGSize(width: 280, height: 60))
            }
            
            NavigationLink(destination: ContentView(backendURL: backendURL)) {
                colorizeButtonContent
            }
            .disabled(backendURL.isEmpty)
            .opacity(backendURL.isEmpty ? 0.5 : 1.0)
        }
    }
    
    private var colorizeButtonContent: some View {
        HStack {
            Image(systemName: "wand.and.stars.inverse")
                .font(.system(size: 20, weight: .medium))
            Text("Let's Colorize")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: 280, minHeight: 60)
        .background(colorizeButtonBackground)
        .foregroundColor(backendURL.isEmpty ? .gray : .white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var colorizeButtonBackground: some View {
        Group {
            if backendURL.isEmpty {
                Color(.systemGray3)
            } else {
                LinearGradient(
                    colors: [Color(hex: "8D9FFF").opacity(0.8), Color(hex: "BC82F3").opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }
    
    private var setupHintView: some View {
        VStack {
            Text("Configure server URL in Settings")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "arrow.turn.down.right")
                    .foregroundColor(.secondary)
                Image(systemName: "gear")
                    .foregroundColor(.secondary)
            }
            .padding(.top, 5)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 20)
        .background(Color(.systemGray6).opacity(0.8))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    // MARK: - Helper Functions
    
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

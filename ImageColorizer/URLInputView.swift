import SwiftUI

struct URLInputView: View {
    @AppStorage("backendURL") private var backendURL: String = "" // Persistently store the URL
    @State private var urlString: String = ""
    @State private var isURLValid: Bool = false
    @State private var showAlert: Bool = false
    @State private var isConnecting: Bool = false
    @State private var connectionSuccess: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    // Animation properties
    @State private var showCheckmark: Bool = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "8D9FFF").opacity(0.1), Color(hex: "BC82F3").opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header illustration
                    serverIllustration
                        .padding(.top, 20)
                    
                    // URL Input Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Backend URL")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(isURLValid ? Color(hex: "BC82F3") : .secondary)
                                .padding(.leading, 12)
                            
                            TextField("Enter Flask Backend URL", text: $urlString)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                                .onChange(of: urlString) { _, newValue in
                                    isURLValid = URL(string: newValue) != nil
                                    if !isURLValid {
                                        showCheckmark = false
                                    }
                                }
                                .overlay(
                                    HStack {
                                        Spacer()
                                        
                                        if !urlString.isEmpty {
                                            Button(action: {
                                                urlString = ""
                                                isURLValid = false
                                                showCheckmark = false
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.secondary)
                                                    .padding(.trailing, 8)
                                            }
                                            .transition(.opacity)
                                        }
                                    }
                                )
                            
                            if isURLValid && showCheckmark {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "BC82F3"))
                                    .padding(.trailing, 12)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(height: 50)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isURLValid ? Color(hex: "BC82F3") : Color(.systemGray4),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // URL format hint
                        Text("Example: http://192.168.1.100:5000 or http://localhost:5000")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Connection Test Section
                    if isURLValid && !urlString.isEmpty {
                        VStack {
                            Button(action: {
                                testConnection()
                            }) {
                                HStack {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                    Text("Test Connection")
                                }
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .frame(height: 40)
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: "8D9FFF"))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                            }
                            
                            if isConnecting {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Testing connection...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 10)
                            }
                            
                            if connectionSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Connection successful!")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 10)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Save button
                    Button(action: {
                        saveURL()
                    }) {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                isURLValid
                                    ? LinearGradient(
                                        colors: [Color(hex: "8D9FFF"), Color(hex: "BC82F3")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color(.systemGray4), Color(.systemGray3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                            .cornerRadius(12)
                            .shadow(
                                color: isURLValid ? Color(hex: "BC82F3").opacity(0.3) : Color.clear,
                                radius: 10,
                                x: 0,
                                y: 5
                            )
                    }
                    .disabled(!isURLValid)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .padding(.vertical)
                .frame(minHeight: UIScreen.main.bounds.height - 100)
            }
        }
        .onAppear {
            urlString = backendURL // Load the saved URL when the view appears
            isURLValid = URL(string: urlString) != nil
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Invalid URL"),
                message: Text("Please enter a valid URL starting with http:// or https://"),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle("Configure URL")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !urlString.isEmpty && urlString != backendURL {
                    Button("Reset") {
                        urlString = backendURL
                        isURLValid = URL(string: backendURL) != nil
                        showCheckmark = false
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "BC82F3"))
                }
            }
        }
    }
    
    // Server illustration view
    private var serverIllustration: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color(hex: "BC82F3").opacity(0.1))
                    .frame(width: 150, height: 150)
                
                Image(systemName: "externaldrive.connected.to.line.below")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60)
                    .foregroundColor(Color(hex: "BC82F3"))
                    .offset(y: -5)
            }
            
            Text("Connect to Server")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color.primary)
                .padding(.top, 10)
            
            Text("Enter the URL of your Flask server\nto enable image and video colorization")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
                .padding(.horizontal, 20)
        }
    }
    
    // Test connection to server
    private func testConnection() {
        guard var urlComponents = URLComponents(string: urlString) else { return }
        
        // Try to connect to a known endpoint like "/colorize" or fall back to root path
        let testPath = "/colorize"
        urlComponents.path = testPath
        
        guard let testURL = urlComponents.url else { return }
        
        isConnecting = true
        connectionSuccess = false
        
        // Create a URL request
        var request = URLRequest(url: testURL)
        request.timeoutInterval = 10
        request.httpMethod = "GET"
        
        print("Testing connection to: \(testURL.absoluteString)")
        
        // Create and execute the networking task
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Connection error: \(error.localizedDescription)")
                    
                    // If the specific path fails, try connecting to the root URL
                    if urlComponents.path != "/" {
                        urlComponents.path = "/"
                        if let rootURL = urlComponents.url {
                            self.fallbackConnectionTest(url: rootURL)
                            return
                        }
                    }
                    
                    self.isConnecting = false
                    self.connectionSuccess = false
                    self.showAlert = true
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Response status code: \(httpResponse.statusCode)")
                    
                    // Any response (even 404) indicates the server is reachable
                    self.isConnecting = false
                    self.connectionSuccess = true
                    
                    withAnimation {
                        self.showCheckmark = true
                    }
                } else {
                    self.isConnecting = false
                    self.connectionSuccess = false
                    self.showAlert = true
                }
            }
        }
        
        task.resume()
    }
    
    // Fallback connection test to the root URL
    private func fallbackConnectionTest(url: URL) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "GET"
        
        print("Fallback test connecting to: \(url.absoluteString)")
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Fallback connection error: \(error.localizedDescription)")
                    self.isConnecting = false
                    self.connectionSuccess = false
                    self.showAlert = true
                    return
                }
                
                // Any response indicates the server exists
                self.isConnecting = false
                self.connectionSuccess = true
                
                withAnimation {
                    self.showCheckmark = true
                }
            }
        }
        
        task.resume()
    }
    
    // Save the URL and dismiss the view
    private func saveURL() {
        if isURLValid {
            backendURL = urlString
            presentationMode.wrappedValue.dismiss()
        } else {
            showAlert = true
        }
    }
}

// Color extension for hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

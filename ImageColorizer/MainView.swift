import SwiftUI

// Main Page
struct MainView: View {
    @State private var animateGradient = false
    @AppStorage("backendURL") private var backendURL: String = "" // Save URL persistently

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Image
                Image("background") // Replace with the name of your image file
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all) // Make the image cover the entire screen

                // Main Content
                VStack(spacing: 40) {
                    
                    Spacer()
                    // Title
                    Text("smAIrtColorizer")
                        .font(.system(size: 40, weight: .heavy, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: animateGradient ? .topLeading : .bottomLeading,
                                endPoint: animateGradient ? .bottomTrailing : .topTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                        .hueRotation(.degrees(animateGradient ? 45 : 0))
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                animateGradient.toggle()
                            }
                        }

                    Spacer() // Pushes content to the center vertically

                    // Buttons
                    VStack(spacing: 20) {
                        
                        // "Let's Colorize" Button
                        NavigationLink(destination: ContentView(backendURL: backendURL)) {
                            Text("Let's Colorize")
                                .font(.title2)
                                .fontWeight(.medium)
                                .padding()
                                .frame(maxWidth: 250)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(25)
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 10)
                        }
                        .disabled(backendURL.isEmpty) // Disable if URL is not set
                        // "Configure URL" Button
                        NavigationLink(destination: URLInputView(backendURL: $backendURL)) {
                            Text("Configure URL")
                                .font(.title2)
                                .fontWeight(.regular)
                                .padding()
                                .frame(maxWidth: 250)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.blue, .pink],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 2 // Adjust the border width as needed
                                        )
                                )
                                .foregroundColor(.white) // Change the text color to match your design
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 10)
                        }.padding()

                    }
                }
                .padding() // Add padding to the main content
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

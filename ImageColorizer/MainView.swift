import SwiftUI

// Main Page
struct MainView: View {
    @State private var animateGradient = false
    @AppStorage("backendURL") private var backendURL: String = "" // Save URL persistently

    var body: some View {
        NavigationStack {
            ZStack {
                

                // Main Content
                VStack(spacing: 40) {
                    // Rainbow Title
                    Text("smAIrtColorizer")
                    .font(.system(size: 46, weight: .bold, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow, .cyan, .blue, .pink],
                            startPoint: animateGradient ? .topLeading : .trailing,
                            endPoint: animateGradient ? .bottomTrailing : .leading
                        )
                    )
                    .hueRotation(.degrees(animateGradient ? 45 : 0))
                    .ignoresSafeArea()
                    .opacity(0.9)
                    
                    

                    // "Configure URL" Button
                    NavigationLink(destination: URLInputView(backendURL: $backendURL)) {
                        Text("Configure URL")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                    
                    // "Let's Colorize" Button
                    NavigationLink(destination: ContentView(backendURL: backendURL)) {
                        Text("Let's Colorize")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                    .disabled(backendURL.isEmpty) // Disable if URL is not set
                }
                .padding()
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

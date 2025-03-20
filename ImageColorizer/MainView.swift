import SwiftUI

// Main Page
struct MainView: View {
    @State private var animateGradient = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(colors: [.cyan, .yellow, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .hueRotation(.degrees(animateGradient ? 45 : 0))
                    .ignoresSafeArea()
                    .opacity(0.8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                            animateGradient.toggle()
                        }
                    }

                // Main Content
                VStack(spacing: 40) {
                    // Rainbow Title
                    Text("smAIrtColorizer")
                        .font(.system(size: 40, weight: .bold, design: .default))
                        .foregroundStyle(Color.white)
                        

                    // "Let's Colorize" Button
                    NavigationLink(destination: URLInputView()) {
                        Text("Let's Colorize")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: 250)
                            .background(Color.white.opacity(0.8))
                            .foregroundColor(.black)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
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

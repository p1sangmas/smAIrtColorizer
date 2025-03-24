import SwiftUI

struct URLInputView: View {
    @Binding var backendURL: String // Binding to update the URL
    @State private var urlString: String = ""
    @State private var isURLValid: Bool = false
    @State private var showAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State private var animateGradient = false // For gradient animation
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Image
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Title
                    Text("Configure URL")
                        .font(.system(size: 36, weight: .medium, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: animateGradient ? .topLeading : .bottomLeading,
                                endPoint: animateGradient ? .bottomTrailing : .topTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                animateGradient.toggle()
                            }
                        }
                    
                    // URL Input Field
                    TextField("Enter Flask Backend URL", text: $urlString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 350)
                        .padding()
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .onChange(of: urlString) { _, newValue in
                            isURLValid = URL(string: newValue) != nil
                        }
                    
                    // Save Button
                    Button(action: {
                        if isURLValid {
                            backendURL = urlString // Save the URL
                            presentationMode.wrappedValue.dismiss() // Dismiss the view
                        } else {
                            showAlert = true
                        }
                    }) {
                        Text("Save")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: 250)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.blue, .purple, .pink],
                                            startPoint: animateGradient ? .topLeading : .bottomLeading,
                                            endPoint: animateGradient ? .bottomTrailing : .topTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                    .disabled(!isURLValid)
                    .padding(.horizontal)
                }
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Invalid URL"),
                        message: Text("Please enter a valid URL."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
}


// Preview
struct URLInputView_Previews: PreviewProvider {
    static var previews: some View {
        // Use a State variable to simulate the backendURL binding
        StatefulPreviewWrapper("") { backendURL in
            URLInputView(backendURL: backendURL)
        }
    }
}

// Helper struct to simulate a State variable in previews
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

import SwiftUI

struct URLInputView: View {
    @Binding var backendURL: String // Binding to update the URL
    @State private var urlString: String = ""
    @State private var isURLValid: Bool = false
    @State private var showAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode // Use presentationMode to dismiss the view

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                Text("Configure URL")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                // URL Input Field
                TextField("Enter Flask Backend URL", text: $urlString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
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
                        .frame(maxWidth: .infinity)
                        .background(isURLValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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

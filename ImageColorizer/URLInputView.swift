import SwiftUI

struct URLInputView: View {
    @AppStorage("backendURL") private var backendURL: String = "" // Persistently store the URL
    @State private var urlString: String = ""
    @State private var isURLValid: Bool = false
    @State private var showAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // URL Input Field
                VStack(alignment: .leading, spacing: 10) {
                    Text("Backend URL")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    TextField("Enter Flask Backend URL", text: $urlString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .onChange(of: urlString) { _, newValue in
                            isURLValid = URL(string: newValue) != nil
                        }
                }
                .frame(maxWidth: 350)

                // Save Button
                Button(action: {
                    if isURLValid {
                        backendURL = urlString // Save the URL persistently
                        presentationMode.wrappedValue.dismiss() // Dismiss the view
                    } else {
                        showAlert = true
                    }
                }) {
                    Text("Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isURLValid ? Color.accentColor : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                }
                .frame(maxWidth: 250)
                .disabled(!isURLValid)

                Spacer()
            }
            .padding()
            .onAppear {
                urlString = backendURL // Load the saved URL when the view appears
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Invalid URL"),
                    message: Text("Please enter a valid URL."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationTitle("Configure URL")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Preview
struct URLInputView_Previews: PreviewProvider {
    static var previews: some View {
        URLInputView()
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

import SwiftUI

struct URLInputView: View {
    @State private var urlString: String = ""
    @State private var isURLValid: Bool = false
    @State private var showAlert: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // URL Input Field
                TextField("Enter Flask Backend URL", text: $urlString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .onChange(of: urlString) { _, newValue in
                        isURLValid = URL(string: newValue) != nil
                    }

                // Proceed Button
                NavigationLink(destination: ContentView(backendURL: urlString)) {
                    Text("Proceed")
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
            .navigationTitle("Enter Backend URL")
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
        URLInputView()
    }
}

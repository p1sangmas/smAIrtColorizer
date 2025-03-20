import SwiftUI
import UIKit

struct ContentView: View {
    @State private var inputImage: UIImage?
    @State private var outputImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isLoading = false
    @State private var showSaveSuccessAlert = false
    var backendURL: String

    var body: some View {
        VStack(spacing: 20) {
            // Original Image Section
            if let inputImage = inputImage {
                VStack(spacing: 10) {
                    Text("Original Image")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Image(uiImage: inputImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            } else {
                Text("Select an image to colorize")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding()
                    .multilineTextAlignment(.center)
            }

            // Colorized Image Section
            if isLoading {
                ProgressView()
                    .padding()
            } else if let outputImage = outputImage {
                VStack(spacing: 10) {
                    Text("Colorized Image")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Image(uiImage: outputImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }

            // Buttons (Side by Side)
            HStack(spacing: 20) {
                Button(action: {
                    showingImagePicker = true
                }) {
                    Text("Select Image")
                        .font(.headline)
                        .padding()
                        .frame(width: 180, height: 60)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }

                if inputImage != nil && !isLoading {
                    Button(action: {
                        colorizeImage()
                    }) {
                        Text("Colorize Image")
                            .font(.headline)
                            .padding()
                            .frame(width: 180, height: 60)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
                
                // Save to Gallery Button
                if outputImage != nil {
                    Button(action: {
                        saveImageToGallery(outputImage!)
                    }) {
                        Text("Save to Gallery")
                            .font(.headline)
                            .padding()
                            .frame(width: 180, height: 60)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
        .animation(.easeInOut, value: isLoading)
        .alert(isPresented: $showSaveSuccessAlert) {
            Alert(
                title: Text("Saved!"),
                message: Text("The colorized image has been saved to your gallery."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func loadImage() {
        // This function is called after the user selects an image
    }

    func colorizeImage() {
        guard let inputImage = inputImage else { return }

        isLoading = true

        // Convert the image to JPEG data
        guard let imageData = inputImage.jpegData(compressionQuality: 1.0) else {
            isLoading = false
            return
        }

        // Use the backend URL provided by the user
        guard let url = URL(string: backendURL) else {
            isLoading = false
            return
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Set the content type
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Create the body of the request
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        // Send the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                if let data = data, let image = UIImage(data: data) {
                    outputImage = image
                }
            }
        }.resume()
    }

    // Save the colorized image to the gallery
    func saveImageToGallery(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showSaveSuccessAlert = true
    }
}

    
    
    struct ImagePicker: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        
        func makeUIViewController(context: Context) -> some UIViewController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: ImagePicker
            
            init(_ parent: ImagePicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.image = image
                }
                picker.dismiss(animated: true)
            }
        }
    }
    
    // Preview
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView(backendURL: "http://example.com/colorize")
        }
    }
    

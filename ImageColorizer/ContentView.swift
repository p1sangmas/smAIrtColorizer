import SwiftUI
import UIKit
import AVKit
import Photos

struct ContentView: View {
    @State private var inputImage: UIImage?
    @State private var outputImage: UIImage?
    @State private var inputVideoURL: URL?
    @State private var outputVideoURL: URL?
    @State private var showingImagePicker = false
    @State private var showingVideoPicker = false
    @State private var isLoading = false
    @State private var showSaveSuccessAlert = false
    @State private var alertMessage = ""
    var backendURL: String

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    // Image Section
                    if let inputImage = inputImage {
                        VStack(spacing: 10) {
                            Text("Original Image")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Image(uiImage: inputImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: min(geometry.size.width * 0.8, 300), maxHeight: 300)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                    } else {
                        Text("Select an image or video to colorize")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding()
                            .multilineTextAlignment(.center)
                    }

                    if let outputImage = outputImage {
                        VStack(spacing: 10) {
                            Text("Colorized Image")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Image(uiImage: outputImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: min(geometry.size.width * 0.8, 300), maxHeight: 300)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                    }

                    // Video Section
                    if let inputVideoURL = inputVideoURL {
                        VStack(spacing: 10) {
                            Text("Original Video")
                                .font(.headline)
                                .foregroundColor(.primary)
                            VideoPlayer(player: AVPlayer(url: inputVideoURL))
                                .frame(height: 300)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                    }

                    if let outputVideoURL = outputVideoURL {
                        VStack(spacing: 10) {
                            Text("Colorized Video")
                                .font(.headline)
                                .foregroundColor(.primary)
                            VideoPlayer(player: AVPlayer(url: outputVideoURL))
                                .frame(height: 300)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                    }

                    // Loading Indicator
                    if isLoading {
                        ProgressView()
                            .padding()
                    }

                    // Buttons (Adaptive Layout)
                    if geometry.size.width > 600 {
                        // Horizontal Layout for Wide Screens
                        HStack(spacing: 10) {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Text("Select Image")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }

                            Button(action: {
                                showingVideoPicker = true
                            }) {
                                Text("Select Video")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Vertical Layout for Narrow Screens
                        VStack(spacing: 10) {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Text("Select Image")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }

                            Button(action: {
                                showingVideoPicker = true
                            }) {
                                Text("Select Video")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Colorize Buttons
                    if inputImage != nil && !isLoading {
                        Button(action: {
                            colorizeImage()
                        }) {
                            Text("Colorize Image")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal)
                    }

                    if inputVideoURL != nil && !isLoading {
                        Button(action: {
                            colorizeVideo()
                        }) {
                            Text("Colorize Video")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal)
                    }

                    // Save Buttons
                    if outputImage != nil {
                        Button(action: {
                            saveImageToGallery(outputImage!)
                        }) {
                            Text("Save Image to Gallery")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal)
                    }

                    if outputVideoURL != nil {
                        Button(action: {
                            saveVideoToGallery(outputVideoURL!)
                        }) {
                            Text("Save Video to Gallery")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
        .sheet(isPresented: $showingVideoPicker, onDismiss: loadVideo) {
            VideoPicker(videoURL: $inputVideoURL)
        }
        .alert(isPresented: $showSaveSuccessAlert) {
            Alert(
                title: Text("Saved!"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func loadImage() {
        outputImage = nil
    }

    func loadVideo() {
        outputVideoURL = nil
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
        guard let url = URL(string: "\(backendURL)/colorize") else {
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

    func colorizeVideo() {
        guard let inputVideoURL = inputVideoURL else { return }
        isLoading = true

        uploadVideoToBackend(inputVideoURL) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let outputURL):
                    outputVideoURL = outputURL
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }


    func uploadVideoToBackend(_ videoURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let backendEndpoint = URL(string: "\(backendURL)/colorize-video")!

        var request = URLRequest(url: backendEndpoint)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add video file
        let videoData = try? Data(contentsOf: videoURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(videoData!)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // Send the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Log the raw response for debugging
            if let data = data, let rawResponse = String(data: data, encoding: .utf8) {
                print("Backend Response: \(rawResponse)")
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "InvalidResponse", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Parse the JSON response
            do {
                let videoResponse = try JSONDecoder().decode(VideoResponse.self, from: data)
                let outputURL = videoResponse.outputURL
                
                // Download the colorized video
                if let videoFileURL = URL(string: outputURL) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("colorized_video.mp4")
                    let videoData = try Data(contentsOf: videoFileURL)
                    try videoData.write(to: tempURL)
                    completion(.success(tempURL))
                } else {
                    completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid output URL"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }



    func saveImageToGallery(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        alertMessage = "The colorized image has been saved to your gallery."
        showSaveSuccessAlert = true
    }

    func saveVideoToGallery(_ videoURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    alertMessage = "The colorized video has been saved to your gallery."
                    showSaveSuccessAlert = true
                } else if let error = error {
                    print("Error saving video to gallery: \(error.localizedDescription)")
                }
            }
        }
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

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?

    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIImagePickerController()
        picker.mediaTypes = ["public.movie"]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.videoURL = videoURL
            }
            picker.dismiss(animated: true)
        }
    }
}

struct VideoResponse: Codable {
    let outputURL: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(backendURL: "http://example.com/colorize")
    }
}

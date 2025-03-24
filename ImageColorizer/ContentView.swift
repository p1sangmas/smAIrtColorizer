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
    @State private var animateGradient = false
    var backendURL: String

    var body: some View {
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

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
                                    .frame(maxWidth: 300, maxHeight: 300)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                        } else {
                            //Text and Buttons
                            Spacer(minLength: 100)

                            VStack(spacing: 20) {
                                Text("Select an image or video to colorize")
                                    .font(.system(size: 36, weight: .medium, design: .default))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple, .pink],
                                            startPoint: animateGradient ? .topLeading : .bottomLeading,
                                            endPoint: animateGradient ? .bottomTrailing : .topTrailing
                                        )
                                    )
                                    .padding()
                                    .frame(maxWidth: 350)
                                    .multilineTextAlignment(.center)

                                if inputVideoURL == nil {
                                    GradientOutlinedButton(action: {
                                        showingImagePicker = true
                                    }, text: "Select Image")
                                }

                                if inputImage == nil {
                                    GradientOutlinedButton(action: {
                                        showingVideoPicker = true
                                    }, text: "Select Video")
                                }
                            }

                            Spacer()
                        }

                        if let outputImage = outputImage {
                            VStack(spacing: 10) {
                                Text("Colorized Image")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Image(uiImage: outputImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 300, maxHeight: 300)
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
                                    .foregroundColor(.white)
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

                        // Colorize Buttons
                        if inputImage != nil && !isLoading {
                            GradientOutlinedButton(action: {
                                colorizeImage()
                            }, text: "Colorize Image")
                            .padding(.horizontal)
                        }

                        if inputVideoURL != nil && !isLoading {
                            GradientOutlinedButton(action: {
                                colorizeVideo()
                            }, text: "Colorize Video")
                            .padding(.horizontal)
                        }

                        // Save Buttons
                        if outputImage != nil {
                            GradientOutlinedButton(action: {
                                saveImageToGallery(outputImage!)
                            }, text: "Save Image to Gallery")
                            .padding(.horizontal)
                        }

                        if outputVideoURL != nil {
                            GradientOutlinedButton(action: {
                                saveVideoToGallery(outputVideoURL!)
                            }, text: "Save Video to Gallery")
                            .padding(.horizontal)
                        }
                    }
                    .padding()
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
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
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

struct GradientOutlinedButton: View {
    var action: () -> Void
    var text: String

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.headline)
                .padding()
                .frame(maxWidth: 250)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                )
                .foregroundColor(.white)
                .shadow(radius: 5)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(backendURL: "http://example.com/colorize")
    }
}

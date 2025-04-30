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
    @State private var loadingProgress: Float = 0
    @State private var showSaveSuccessAlert = false
    @State private var alertMessage = ""
    @State private var selectedTab = 0
    @State private var showConfetti = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var historyManager: HistoryManager
    var backendURL: String
    
    // Timer for simulated progress
    @State private var progressTimer: Timer?

    var body: some View {
        ZStack {
            // Background pattern
            backgroundPattern
            
            VStack(spacing: 0) {
                // Custom segmented picker
                customSegmentedPicker
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // Main content area
                ScrollView {
                    VStack(spacing: 25) {
                        if selectedTab == 0 {
                            imageColorization
                        } else {
                            videoColorization
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .navigationTitle("Colorize")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showSaveSuccessAlert) {
            Alert(
                title: Text("Success!"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onDisappear {
            progressTimer?.invalidate()
            progressTimer = nil
        }
    }
    
    // MARK: - Background Pattern
    
    var backgroundPattern: some View {
        ZStack {
            Color(colorScheme == .dark ? .black : .white)
                .opacity(0.95)
                .ignoresSafeArea()
            
            VStack {
                ForEach(0..<20) { row in
                    HStack(spacing: 20) {
                        ForEach(0..<10) { col in
                            Circle()
                                .fill(
                                    [Color(hex: "8D9FFF"), Color(hex: "BC82F3"), Color(hex: "F5B9EA"), Color(hex: "FF6778")]
                                        .randomElement()!
                                )
                                .frame(width: 4, height: 4)
                                .opacity(0.2)
                        }
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Custom Segmented Control
    
    var customSegmentedPicker: some View {
        HStack(spacing: 0) {
            Button(action: { selectedTab = 0 }) {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 18, weight: selectedTab == 0 ? .semibold : .regular))
                    Text("Images")
                        .font(.system(size: 12, weight: selectedTab == 0 ? .semibold : .regular))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(selectedTab == 0 ? Color(hex: "BC82F3") : .secondary)
                .background(
                    ZStack {
                        if selectedTab == 0 {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "BC82F3").opacity(0.15))
                        }
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { selectedTab = 1 }) {
                VStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.system(size: 18, weight: selectedTab == 1 ? .semibold : .regular))
                    Text("Videos")
                        .font(.system(size: 12, weight: selectedTab == 1 ? .semibold : .regular))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(selectedTab == 1 ? Color(hex: "BC82F3") : .secondary)
                .background(
                    ZStack {
                        if selectedTab == 1 {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "BC82F3").opacity(0.15))
                        }
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Image Colorization
    
    var imageColorization: some View {
        VStack(spacing: 30) {
            // Image Preview
            if let inputImage = inputImage {
                VStack(spacing: 25) {
                    // Title
                    Text("Preview")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 15)
                    
                    // Image carousel
                    TabView {
                        // Original Image
                        imageDisplayCard(
                            image: inputImage,
                            title: "Original",
                            isPrimary: false
                        )
                        
                        // Colorized Image (if exists)
                        if let outputImage = outputImage {
                            imageDisplayCard(
                                image: outputImage,
                                title: "Colorized",
                                isPrimary: true
                            )
                        }
                    }
                    .frame(height: 350)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    
                    // Loading indicator
                    if isLoading {
                        VStack(spacing: 12) {
                            ZStack {
                                // Track
                                Circle()
                                    .stroke(lineWidth: 6)
                                    .opacity(0.1)
                                    .foregroundColor(Color(hex: "BC82F3"))
                                
                                // Progress
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(min(loadingProgress, 1.0)))
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: "8D9FFF"), Color(hex: "BC82F3")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                                    )
                                    .rotationEffect(Angle(degrees: 270))
                                    .animation(.easeInOut, value: loadingProgress)
                                
                                // Percentage
                                Text("\(Int(loadingProgress * 100))%")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "BC82F3"))
                            }
                            .frame(width: 60, height: 60)
                            
                            Text("Adding color to your image...")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    
                    // Action buttons
                    if !isLoading {
                        if outputImage == nil {
                            modernButton(
                                title: "Colorize Image",
                                icon: "wand.and.stars",
                                color: Color(hex: "BC82F3"),
                                action: colorizeImage
                            )
                        } else {
                            modernButton(
                                title: "Save to Gallery",
                                icon: "square.and.arrow.down",
                                color: Color(hex: "FF6778"),
                                action: {
                                    if let outputImage = outputImage {
                                        saveImageToGallery(outputImage)
                                    }
                                }
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                // Empty state / Upload prompt
                VStack(spacing: 25) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "BC82F3").opacity(0.1))
                            .frame(width: 160, height: 160)
                        
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color(hex: "BC82F3").opacity(0.7))
                    }
                    
                    VStack(spacing: 10) {
                        Text("Upload an Image")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Select a black and white image to colorize")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Select Image")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "8D9FFF"), Color(hex: "BC82F3")],
                                startPoint: .leading, 
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "BC82F3").opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            }
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
    }
    
    // MARK: - Video Colorization
    
    var videoColorization: some View {
        VStack(spacing: 30) {
            // Video Preview
            if let inputVideoURL = inputVideoURL {
                VStack(spacing: 25) {  // Increased spacing from 15 to 25
                    // Title
                    Text("Preview")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 15)  // Added padding to increase the gap
                    
                    // Video carousel
                    TabView {
                        // Original Video
                        videoPlayerCard(
                            url: inputVideoURL,
                            title: "Original",
                            isPrimary: false
                        )
                        
                        // Colorized Video (if exists)
                        if let outputVideoURL = outputVideoURL {
                            videoPlayerCard(
                                url: outputVideoURL,
                                title: "Colorized",
                                isPrimary: true
                            )
                        }
                    }
                    .frame(height: 350)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    
                    // Loading indicator
                    if isLoading {
                        VStack(spacing: 12) {
                            ZStack {
                                // Track
                                Circle()
                                    .stroke(lineWidth: 6)
                                    .opacity(0.1)
                                    .foregroundColor(Color(hex: "BC82F3"))
                                
                                // Progress
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(min(loadingProgress, 1.0)))
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: "8D9FFF"), Color(hex: "BC82F3")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                                    )
                                    .rotationEffect(Angle(degrees: 270))
                                    .animation(.easeInOut, value: loadingProgress)
                                
                                // Percentage
                                Text("\(Int(loadingProgress * 100))%")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "BC82F3"))
                            }
                            .frame(width: 60, height: 60)
                            
                            Text("Adding color to your video...")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    
                    // Action buttons
                    if !isLoading {
                        if outputVideoURL == nil {
                            modernButton(
                                title: "Colorize Video",
                                icon: "wand.and.stars",
                                color: Color(hex: "BC82F3"),
                                action: colorizeVideo
                            )
                        } else {
                            modernButton(
                                title: "Save to Gallery",
                                icon: "square.and.arrow.down",
                                color: Color(hex: "FF6778"),
                                action: {
                                    if let outputVideoURL = outputVideoURL {
                                        saveVideoToGallery(outputVideoURL)
                                    }
                                }
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                // Empty state / Upload prompt
                VStack(spacing: 25) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "BC82F3").opacity(0.1))
                            .frame(width: 160, height: 160)
                        
                        Image(systemName: "film")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color(hex: "BC82F3").opacity(0.7))
                    }
                    
                    VStack(spacing: 10) {
                        Text("Upload a Video")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Select a black and white video to colorize")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        showingVideoPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Select Video")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "8D9FFF"), Color(hex: "BC82F3")],
                                startPoint: .leading, 
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "BC82F3").opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            }
        }
        .sheet(isPresented: $showingVideoPicker, onDismiss: loadVideo) {
            VideoPicker(videoURL: $inputVideoURL)
        }
    }
    
    // MARK: - Helper Views
    
    func imageDisplayCard(image: UIImage, title: String, isPrimary: Bool) -> some View {
        VStack(spacing: 12) {
            // Title
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(isPrimary ? Color(hex: "BC82F3") : .secondary)
            
            // Image with border
            ZStack {
                // Base image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Conditional border
                if isPrimary {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "8D9FFF"), Color(hex: "BC82F3")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .allowsHitTesting(false)
                }
            }
            .background(GeometryReader { geo in
                Color.clear.preference(key: ImageSizePreferenceKey.self, value: geo.size)
            })
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 15)
    }
    
    func videoPlayerCard(url: URL, title: String, isPrimary: Bool) -> some View {
        VStack(spacing: 12) {
            // Title
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(isPrimary ? Color(hex: "BC82F3") : .secondary)
            
            // Video player with border
            ZStack {
                // Base video player
                VideoPlayer(player: AVPlayer(url: url))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Conditional border
                if isPrimary {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "8D9FFF"), Color(hex: "BC82F3")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 280)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 15)
    }
    
    func modernButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.9), color],
                    startPoint: .leading, 
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Functions
    
    func loadImage() {
        outputImage = nil
        isLoading = false
        loadingProgress = 0
        progressTimer?.invalidate()
        progressTimer = nil
    }

    func loadVideo() {
        outputVideoURL = nil
        isLoading = false
        loadingProgress = 0
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func colorizeImage() {
        guard let inputImage = inputImage else { return }
        isLoading = true
        loadingProgress = 0

        // Start simulated progress
        startProgressTimer()

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
            // Stop the progress timer
            DispatchQueue.main.async {
                self.progressTimer?.invalidate()
                self.progressTimer = nil
                
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }

                // Complete the progress animation
                withAnimation(.easeOut(duration: 0.5)) {
                    self.loadingProgress = 1.0
                }
                
                // Process response
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isLoading = false
                    
                    if let data = data, let image = UIImage(data: data) {
                        self.outputImage = image
                        
                        // Add to history
                        self.historyManager.addImageHistory(image: image)
                        
                        // Show confetti animation
                        withAnimation {
                            self.showConfetti = true
                        }
                        
                        // Hide confetti after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                self.showConfetti = false
                            }
                        }
                    }
                }
            }
        }.resume()
    }

    func colorizeVideo() {
        guard let inputVideoURL = inputVideoURL else { return }
        isLoading = true
        loadingProgress = 0
        
        // Start simulated progress
        startProgressTimer()
        
        uploadVideoToBackend(inputVideoURL) { result in
            // Stop the progress timer
            DispatchQueue.main.async {
                self.progressTimer?.invalidate()
                self.progressTimer = nil
                
                // Complete the progress animation
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.loadingProgress = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let outputURL):
                        self.outputVideoURL = outputURL
                        
                        // Generate thumbnail and add to history
                        let thumbnail = self.historyManager.generateThumbnail(from: outputURL)
                        self.historyManager.addVideoHistory(videoURL: outputURL, thumbnail: thumbnail)
                        
                        // Show confetti animation
                        withAnimation {
                            self.showConfetti = true
                        }
                        
                        // Hide confetti after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                self.showConfetti = false
                            }
                        }
                        
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Timer to simulate progress for better UX
    func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation {
                if self.loadingProgress < 0.95 {
                    // Simulate progress up to 95%
                    let increment = Float.random(in: 0.003...0.007)
                    self.loadingProgress = min(self.loadingProgress + increment, 0.95)
                }
            }
        }
    }

    func uploadVideoToBackend(_ videoURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let backendEndpoint = URL(string: "\(backendURL)/colorize-video") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid backend URL configuration"])))
            return
        }

        // Create a configuration with extended timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300  // 5 minutes
        config.timeoutIntervalForResource = 3600 // 1 hour for large videos
        let session = URLSession(configuration: config)

        var request = URLRequest(url: backendEndpoint)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add video file
        let videoData: Data
        do {
            videoData = try Data(contentsOf: videoURL)
        } catch {
            print("Error reading video data: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        // Print video size for debugging
        print("Video size: \(ByteCountFormatter.string(fromByteCount: Int64(videoData.count), countStyle: .file))")
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(videoData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // Send the request
        print("Starting video upload to \(backendEndpoint)")
        let task = session.dataTask(with: request) { data, response, error in
            // Check HTTP response code
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response: \(httpResponse.statusCode)")
            }
            
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
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
                // First try to decode as a task response (for async processing)
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Check if this is a task ID response (backend is processing asynchronously)
                    if let taskID = jsonObject["task_id"] as? String {
                        print("Received task ID: \(taskID). Starting polling...")
                        self.pollForVideoResult(taskID: taskID, completion: completion)
                        return
                    }
                }
                
                // Try direct video response (synchronous processing)
                let videoResponse = try JSONDecoder().decode(VideoResponse.self, from: data)
                let outputURL = videoResponse.outputURL
                
                print("Downloading colorized video from: \(outputURL)")
                
                // Download the colorized video
                self.downloadColorizedVideo(from: outputURL, completion: completion)
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // Poll for async video processing result
    func pollForVideoResult(taskID: String, pollCount: Int = 0, completion: @escaping (Result<URL, Error>) -> Void) {
        // Max polling attempts (10 minute timeout at 5s intervals)
        let maxPolls = 120
        
        if pollCount >= maxPolls {
            completion(.failure(NSError(domain: "Timeout", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video processing timed out"])))
            return
        }
        
        // Create status check URL
        guard let statusURL = URL(string: "\(backendURL)/status/\(taskID)") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid status URL"])))
            return
        }
        
        print("Polling for status: \(statusURL)")
        
        URLSession.shared.dataTask(with: statusURL) { data, response, error in
            if let error = error {
                print("Polling error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let responseStr = String(data: data, encoding: .utf8) {
                print("Status response: \(responseStr)")
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Check the status
                    if let status = jsonResponse["status"] as? String {
                        switch status {
                        case "completed":
                            // Processing is complete
                            if let outputURL = jsonResponse["output_url"] as? String {
                                print("Video processing completed. Downloading from: \(outputURL)")
                                self.downloadColorizedVideo(from: outputURL, completion: completion)
                            } else {
                                completion(.failure(NSError(domain: "NoURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "No output URL in response"])))
                            }
                            
                        case "processing":
                            // Still processing, wait and poll again
                            print("Video still processing (attempt \(pollCount + 1)/\(maxPolls))...")
                            
                            // Update progress if available
                            if let progress = jsonResponse["progress"] as? Double {
                                DispatchQueue.main.async {
                                    self.loadingProgress = Float(progress)
                                }
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                self.pollForVideoResult(taskID: taskID, pollCount: pollCount + 1, completion: completion)
                            }
                            
                        case "error":
                            // Processing failed
                            if let errorMsg = jsonResponse["error"] as? String {
                                completion(.failure(NSError(domain: "ProcessingError", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                            } else {
                                completion(.failure(NSError(domain: "ProcessingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video processing failed"])))
                            }
                            
                        default:
                            // Unknown status
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                self.pollForVideoResult(taskID: taskID, pollCount: pollCount + 1, completion: completion)
                            }
                        }
                    } else {
                        // No status field, wait and retry
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            self.pollForVideoResult(taskID: taskID, pollCount: pollCount + 1, completion: completion)
                        }
                    }
                }
            } catch {
                print("Error parsing status response: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Download the colorized video 
    func downloadColorizedVideo(from urlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let videoFileURL = URL(string: urlString) else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid output URL"])))
            return
        }
        
        // Create a configuration with extended timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 300 // 5 minutes for download
        let session = URLSession(configuration: config)
        
        print("Starting video download from: \(urlString)")
        
        let downloadTask = session.dataTask(with: videoFileURL) { data, response, error in
            if let error = error {
                print("Download error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoVideoData", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video data received"])))
                return
            }
            
            print("Video data received: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
            
            do {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("colorized_video_\(UUID().uuidString).mp4")
                try data.write(to: tempURL)
                print("Video saved to: \(tempURL)")
                completion(.success(tempURL))
            } catch {
                print("Error writing video to disk: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        downloadTask.resume()
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

// MARK: - Helper Structs

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

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // Set up emitter
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.frame.size.width / 2, y: -50)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.frame.size.width, height: 1)
        
        // Create cells
        var cells = [CAEmitterCell]()
        let colors = ["8D9FFF", "BC82F3", "F5B9EA", "FF6778", "FFBA71"]
        
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 5
            cell.lifetime = 10
            cell.velocity = 150
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3
            cell.spinRange = 3
            cell.scale = 0.5
            cell.scaleRange = 0.3
            cell.color = UIColor(hex: color)?.cgColor
            
            // Custom shape
            let shape = CAShapeLayer()
            shape.fillColor = UIColor.white.cgColor
            
            // Choose between different shapes
            let shapeType = Int.random(in: 0...2)
            if shapeType == 0 {
                // Circle
                shape.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 10, height: 10)).cgPath
            } else if shapeType == 1 {
                // Star
                let starPath = UIBezierPath()
                let center = CGPoint(x: 5, y: 5)
                let numberOfPoints = 5
                let radius: CGFloat = 5
                let inset: CGFloat = 2
                
                for i in 0..<numberOfPoints * 2 {
                    let angle = CGFloat(i) * .pi / CGFloat(numberOfPoints)
                    let r = i % 2 == 0 ? radius : radius * inset / radius
                    let x = center.x + r * cos(angle)
                    let y = center.y + r * sin(angle)
                    
                    if i == 0 {
                        starPath.move(to: CGPoint(x: x, y: y))
                    } else {
                        starPath.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                starPath.close()
                shape.path = starPath.cgPath
            } else {
                // Square
                shape.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 8, height: 8)).cgPath
            }
            
            // Convert shape to image
            let shapeImage = createImageFromLayer(shape, size: CGSize(width: 20, height: 20))
            cell.contents = shapeImage.cgImage
            
            cells.append(cell)
        }
        
        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)
        
        // Start animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emitter.beginTime = CACurrentMediaTime()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    private func createImageFromLayer(_ layer: CALayer, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

struct VideoResponse: Codable {
    let outputURL: String
}

// MARK: - Extensions

extension UIColor {
    convenience init?(hex: String) {
        let r, g, b: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: 1.0)
                    return
                }
            }
        }
        
        return nil
    }
}

struct ImageSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView(backendURL: "http://example.com/colorize")
        }
    }
}

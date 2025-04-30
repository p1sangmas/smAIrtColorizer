import Foundation
import UIKit
import SwiftUI
import AVKit

// Media type enum to track what kind of media was colorized
enum MediaType: String, Codable {
    case image = "Image"
    case video = "Video"
}

// Main data structure for history items
struct HistoryItem: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let mediaType: MediaType
    let thumbnailData: Data? // Stored as thumbnail to conserve space
    let fileURL: URL? // For videos or large images
    
    // For Codable support with URL
    enum CodingKeys: String, CodingKey {
        case id, date, mediaType, thumbnailData, fileURLString
    }
    
    init(date: Date, mediaType: MediaType, thumbnailData: Data?, fileURL: URL?) {
        self.date = date
        self.mediaType = mediaType
        self.thumbnailData = thumbnailData
        self.fileURL = fileURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        thumbnailData = try container.decodeIfPresent(Data.self, forKey: .thumbnailData)
        
        // Handle URL decoding
        if let urlString = try container.decodeIfPresent(String.self, forKey: .fileURLString) {
            fileURL = URL(string: urlString)
        } else {
            fileURL = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(mediaType, forKey: .mediaType)
        try container.encodeIfPresent(thumbnailData, forKey: .thumbnailData)
        
        // Handle URL encoding
        if let url = fileURL {
            try container.encode(url.absoluteString, forKey: .fileURLString)
        }
    }
    
    // Computed properties
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    var formattedDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var thumbnail: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
}

// Manager class to handle all history operations
class HistoryManager: ObservableObject {
    @Published var historyItems: [HistoryItem] = []
    private let historyKey = "colorization_history"
    
    init() {
        loadHistory()
    }
    
    // Load history from UserDefaults
    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey) {
            do {
                historyItems = try JSONDecoder().decode([HistoryItem].self, from: data)
            } catch {
                print("Error loading history: \(error.localizedDescription)")
                historyItems = []
            }
        }
    }
    
    // Save history to UserDefaults
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(historyItems)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Error saving history: \(error.localizedDescription)")
        }
    }
    
    // Add a new history item for an image
    func addImageHistory(image: UIImage) {
        // Create thumbnail to save space
        let thumbnailSize = CGSize(width: 300, height: 300)
        
        // Fix: Using prepareThumbnail with completion handler
        if #available(iOS 15.0, *) {
            image.prepareThumbnail(of: thumbnailSize) { thumbnail in
                if let thumbnailImage = thumbnail, let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.7) {
                    let newItem = HistoryItem(
                        date: Date(),
                        mediaType: .image,
                        thumbnailData: thumbnailData,
                        fileURL: nil
                    )
                    
                    DispatchQueue.main.async {
                        self.historyItems.insert(newItem, at: 0) // Add to beginning of array
                        
                        // Limit history items to prevent excessive storage use
                        if self.historyItems.count > 100 {
                            self.historyItems = Array(self.historyItems.prefix(100))
                        }
                        
                        self.saveHistory()
                    }
                }
            }
        } else {
            // Fallback for older iOS versions
            let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
            let thumbnailImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
            }
            
            if let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.7) {
                let newItem = HistoryItem(
                    date: Date(),
                    mediaType: .image,
                    thumbnailData: thumbnailData,
                    fileURL: nil
                )
                
                self.historyItems.insert(newItem, at: 0) // Add to beginning of array
                
                // Limit history items to prevent excessive storage use
                if self.historyItems.count > 100 {
                    self.historyItems = Array(self.historyItems.prefix(100))
                }
                
                self.saveHistory()
            }
        }
    }
    
    // Add a new history item for a video
    func addVideoHistory(videoURL: URL, thumbnail: UIImage?) {
        // Create a thumbnail if none provided
        let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.7)
        
        let newItem = HistoryItem(
            date: Date(),
            mediaType: .video,
            thumbnailData: thumbnailData,
            fileURL: videoURL
        )
        
        historyItems.insert(newItem, at: 0) // Add to beginning of array
        
        // Limit history items to prevent excessive storage use
        if historyItems.count > 100 {
            historyItems = Array(historyItems.prefix(100))
        }
        
        saveHistory()
    }
    
    // Group history items by date for better display
    func groupedHistoryItems() -> [String: [HistoryItem]] {
        Dictionary(grouping: historyItems) { item in
            item.formattedDay
        }
    }
    
    // Remove a specific history item
    func removeItem(_ item: HistoryItem) {
        historyItems.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    // Clear all history
    func clearAllHistory() {
        historyItems.removeAll()
        saveHistory()
    }
}

// Helper extension to generate thumbnail from a video URL
extension HistoryManager {
    func generateThumbnail(from url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Get thumbnail at 1 second mark
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}
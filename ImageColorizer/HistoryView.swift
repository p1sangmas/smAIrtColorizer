import SwiftUI
import AVKit

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager()
    @State private var selectedItem: HistoryItem?
    @State private var showingDetailView = false
    @State private var showDeleteConfirmation = false
    @State private var showClearAllAlert = false
    
    var body: some View {
        ZStack {
            // Background layer
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            // Content
            if historyManager.historyItems.isEmpty {
                emptyHistoryView
            } else {
                historyListView
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !historyManager.historyItems.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showClearAllAlert = true
                    } label: {
                        Text("Clear")
                            .foregroundColor(Color(hex: "FF6778"))
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetailView) {
            if let item = selectedItem {
                HistoryDetailView(item: item)
            }
        }
        .alert("Clear All History", isPresented: $showClearAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                withAnimation {
                    historyManager.clearAllHistory()
                }
            }
        } message: {
            Text("Are you sure you want to clear all colorization history? This action cannot be undone.")
        }
        .onAppear {
            historyManager.loadHistory()
        }
    }
    
    // Empty state view
    private var emptyHistoryView: some View {
        VStack {
            Spacer()
            
            Image(systemName: "clock.badge")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color(hex: "8D9FFF").opacity(0.5))
            
            Text("No history yet")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.top, 10)
            
            Text("Your colorized images and videos will appear here")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 5)
            
            Spacer()
        }
    }
    
    // History list with sections by date
    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(historyManager.groupedHistoryItems().keys.sorted().reversed()), id: \.self) { day in
                    if let items = historyManager.groupedHistoryItems()[day] {
                        Section(header: sectionHeader(day)) {
                            ForEach(items) { item in
                                HistoryItemRow(item: item)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedItem = item
                                        showingDetailView = true
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                historyManager.removeItem(item)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }
    
    // Section header for date groups
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(UIColor.systemBackground).opacity(0.95))
    }
}

// Individual history item row
struct HistoryItemRow: View {
    let item: HistoryItem
    
    var body: some View {
        HStack(spacing: 15) {
            // Thumbnail
            ZStack {
                if let thumbnail = item.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color(hex: "BC82F3").opacity(0.1))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: item.mediaType == .video ? "film" : "photo")
                                .foregroundColor(Color(hex: "BC82F3"))
                        )
                }
                
                // Video indicator badge
                if item.mediaType == .video {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color(hex: "BC82F3"))
                                .clipShape(Circle())
                        }
                    }
                    .padding(4)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.mediaType.rawValue)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                
                Text(item.formattedTime)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Arrow indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .opacity(0.7)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
        .cornerRadius(10)
    }
}

// Detail view for a history item
struct HistoryDetailView: View {
    let item: HistoryItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Media preview
                    mediaPreview
                    
                    // Details
                    VStack(alignment: .leading, spacing: 15) {
                        detailRow(title: "Type", value: item.mediaType.rawValue)
                        detailRow(title: "Date", value: item.formattedDate)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("History Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Media preview (image or video)
    private var mediaPreview: some View {
        Group {
            if item.mediaType == .image, let thumbnail = item.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
            } else if item.mediaType == .video, let url = item.fileURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 250)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
            } else {
                Text("Preview not available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
            }
        }
    }
    
    // Detail row helper
    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(size: 15))
            
            Spacer()
        }
    }
}

// Preview for HistoryView
#Preview {
    NavigationStack {
        HistoryView()
            .environmentObject(createPreviewHistoryManager())
    }
}

#Preview("Empty History") {
    NavigationStack {
        HistoryView()
    }
}

#Preview("History Detail") {
    HistoryDetailView(item: createSampleHistoryItem())
}

// Helper functions for previews
func createPreviewHistoryManager() -> HistoryManager {
    let manager = HistoryManager()
    
    // Add some sample items
    if let image = UIImage(systemName: "photo") {
        manager.addImageHistory(image: image)
    }
    
    // Add more items with different dates for testing grouping
    if let image = UIImage(systemName: "star") {
        let item = HistoryItem(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            mediaType: .image,
            thumbnailData: image.jpegData(compressionQuality: 0.7),
            fileURL: nil
        )
        manager.historyItems.append(item)
    }
    
    if let image = UIImage(systemName: "video") {
        let item = HistoryItem(
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            mediaType: .video,
            thumbnailData: image.jpegData(compressionQuality: 0.7),
            fileURL: nil
        )
        manager.historyItems.append(item)
    }
    
    return manager
}

func createSampleHistoryItem() -> HistoryItem {
    let image = UIImage(systemName: "photo") ?? UIImage()
    return HistoryItem(
        date: Date(),
        mediaType: .image,
        thumbnailData: image.jpegData(compressionQuality: 0.7),
        fileURL: nil
    )
}
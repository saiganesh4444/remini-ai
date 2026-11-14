import Foundation
import UIKit

/// Represents a completed photo edit saved to local activity history
struct ActivityItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let mode: EnhancementMode
    let engine: EngineType
    let strength: Float
    let originalPixelWidth: Int
    let originalPixelHeight: Int
    let outputPixelWidth: Int
    let outputPixelHeight: Int
    let thumbnailFileName: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var dimensionsText: String {
        "\(outputPixelWidth) × \(outputPixelHeight)"
    }
}

final class ActivityHistoryManager {
    static let shared = ActivityHistoryManager()
    
    private let historyFileName = "activity_history.json"
    private let thumbnailsDirectoryName = "activity_thumbnails"
    
    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(historyFileName)
    }
    
    private var thumbnailsDirectoryURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(thumbnailsDirectoryName, isDirectory: true)
    }
    
    private init() {
        createThumbnailsDirectoryIfNeeded()
    }
    
    private func createThumbnailsDirectoryIfNeeded() {
        let path = thumbnailsDirectoryURL.path
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(at: thumbnailsDirectoryURL, withIntermediateDirectories: true)
        }
    }
    
    func loadHistory() -> [ActivityItem] {
        guard let data = try? Data(contentsOf: fileURL),
              let items = try? JSONDecoder().decode([ActivityItem].self, from: data) else {
            return []
        }
        return items.sorted(by: { $0.date > $1.date })
    }
    
    func recordActivity(
        image: UIImage,
        mode: EnhancementMode,
        engine: EngineType,
        strength: Float,
        originalSize: CGSize,
        outputSize: CGSize
    ) -> ActivityItem {
        let id = UUID()
        let thumbnailName = "\(id.uuidString).jpg"
        let thumbURL = thumbnailsDirectoryURL.appendingPathComponent(thumbnailName)
        
        // Generate small thumbnail (~200px max)
        let maxDim: CGFloat = 200
        let aspect = image.size.width / max(image.size.height, 1)
        let thumbSize = aspect >= 1
            ? CGSize(width: maxDim, height: maxDim / aspect)
            : CGSize(width: maxDim * aspect, height: maxDim)
        
        let renderer = UIGraphicsImageRenderer(size: thumbSize)
        let thumbImg = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: thumbSize))
        }
        if let jpeg = thumbImg.jpegData(compressionQuality: 0.75) {
            try? jpeg.write(to: thumbURL)
        }
        
        let item = ActivityItem(
            id: id,
            date: Date(),
            mode: mode,
            engine: engine,
            strength: strength,
            originalPixelWidth: Int(originalSize.width),
            originalPixelHeight: Int(originalSize.height),
            outputPixelWidth: Int(outputSize.width),
            outputPixelHeight: Int(outputSize.height),
            thumbnailFileName: thumbnailName
        )
        
        var current = loadHistory()
        current.insert(item, at: 0)
        // Keep up to 50 recent items
        if current.count > 50 {
            current = Array(current.prefix(50))
        }
        saveHistory(current)
        return item
    }
    
    func loadThumbnail(for item: ActivityItem) -> UIImage? {
        let url = thumbnailsDirectoryURL.appendingPathComponent(item.thumbnailFileName)
        return UIImage(contentsOfFile: url.path)
    }
    
    func clearHistory() {
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: thumbnailsDirectoryURL)
        createThumbnailsDirectoryIfNeeded()
    }
    
    private func saveHistory(_ items: [ActivityItem]) {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: fileURL)
        }
    }
}

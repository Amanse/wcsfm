import AppKit
import SwiftData
import SwiftUI

@MainActor
class ClipboardMonitor {
    private let modelContext: ModelContext
    private var lastChangeCount: Int = 0
    private var timer: Timer?

    @AppStorage("keepImages") private var keepImages: Bool = true
    @AppStorage("retentionPolicy") private var retentionPolicy: Int = 1 // e.g., days

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { @MainActor [weak self] _ in
            self?.checkForChanges()
        }
    }

    private func checkForChanges() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Clean up old history first
        cleanupOldHistory()

        if let stringContent = pasteboard.string(forType: .string) {
            // Trim trailing newlines and spaces
            var content = stringContent
            while content.hasSuffix("\n") || content.hasSuffix("\r") || content.hasSuffix(" ") {
                content.removeLast()
            }
            
            // Check if identical text already exists
            let fetchDescriptor = FetchDescriptor<ClipboardItem>()
            if let items = try? modelContext.fetch(fetchDescriptor) {
                if let existingItem = items.first(where: { $0.type == "text" && $0.content == content }) {
                    // Update timestamp to move it to the top
                    existingItem.timestamp = Date()
                    try? modelContext.save()
                    return
                }
            }
            
            let newItem = ClipboardItem(type: "text", content: content)
            modelContext.insert(newItem)
            
        } else if keepImages, let imageContent = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            let newItem = ClipboardItem(type: "image", imageData: imageContent)
            modelContext.insert(newItem)
        }
    }

    private func fetchLatestItem() -> ClipboardItem? {
        let fetchDescriptor = FetchDescriptor<ClipboardItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        return try? modelContext.fetch(fetchDescriptor).first
    }

    private func cleanupOldHistory() {
        guard retentionPolicy > 0 else { return } // 0 means never delete

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionPolicy, to: Date())!
        
        // Fetch all items older than cutoffDate
        let fetchDescriptor = FetchDescriptor<ClipboardItem>()
        do {
            let items = try modelContext.fetch(fetchDescriptor)
            for item in items {
                if item.timestamp < cutoffDate {
                    modelContext.delete(item)
                }
            }
            try modelContext.save()
        } catch {
            print("Failed to clean up history: \(error)")
        }
    }
}

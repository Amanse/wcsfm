import Foundation
import SwiftData
import AppKit

@Model
final class ClipboardItem {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var type: String // "text" or "image"
    var content: String?
    @Attribute(.externalStorage) var imageData: Data?
    
    init(id: UUID = UUID(), timestamp: Date = Date(), type: String, content: String? = nil, imageData: Data? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.content = content
        self.imageData = imageData
    }
}

import AppKit
import SwiftData

@Model
final class PromptHistoryItem {
    var id: UUID
    var createdAt: Date
    var title: String
    var prompt: String
    var templateName: String
    var thumbnailData: Data?

    init(title: String, prompt: String, templateName: String, imageData: Data?) {
        self.id = UUID()
        self.createdAt = .now
        self.title = title
        self.prompt = prompt
        self.templateName = templateName
        self.thumbnailData = imageData.flatMap { NSImage(data: $0)?.resizedJPEGData(maxDimension: 160) }
    }
}

enum PromptTemplate: String, CaseIterable, Identifiable {
    case generic = "Generic"
    case hero = "Hero Section"
    case features = "Features Section"
    case pricing = "Pricing Section"
    case cta = "CTA Section"
    case footer = "Footer Section"
    case product = "Product Page"
    case landing = "Landing Page"
    case industry = "Industry Page"
    case bento = "Bento Grid"
    case dashboard = "Dashboard Showcase"

    var id: String { rawValue }
}

extension NSImage {
    func resizedJPEGData(maxDimension: CGFloat) -> Data? {
        let scale = min(1, maxDimension / max(size.width, size.height))
        let targetSize = NSSize(width: size.width * scale, height: size.height * scale)
        let output = NSImage(size: targetSize)
        output.lockFocus()
        draw(in: NSRect(origin: .zero, size: targetSize))
        output.unlockFocus()
        return output.tiffRepresentation.flatMap { NSBitmapImageRep(data: $0)?.representation(using: .jpeg, properties: [.compressionFactor: 0.75]) }
    }
}

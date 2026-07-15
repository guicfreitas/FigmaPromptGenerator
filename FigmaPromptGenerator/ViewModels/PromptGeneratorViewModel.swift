import AppKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
final class PromptGeneratorViewModel: ObservableObject {
    @Published var imageData: Data?
    @Published var image: NSImage?
    @Published var imageMimeType = "image/png"
    @Published var css = ""
    @Published var notes = ""
    @Published var selectedTemplate: PromptTemplate = .generic
    @Published var prompt = ""
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @AppStorage("model") var model = "gpt-5"
    @AppStorage("temperature") var temperature = 0.3
    @AppStorage("maxTokens") var maxTokens = 4000

    func importImage(from url: URL) {
        guard let data = try? Data(contentsOf: url), let image = NSImage(data: data) else {
            errorMessage = "That file is not a readable image."
            return
        }
        imageData = data
        self.image = image
        imageMimeType = mimeType(for: url.pathExtension)
    }

    func pasteImage() {
        let board = NSPasteboard.general
        guard let image = NSImage(pasteboard: board),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            errorMessage = "The clipboard image could not be converted to PNG."
            return
        }
        imageData = pngData
        self.image = image
        imageMimeType = "image/png"
    }

    func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .webP]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { importImage(from: url) }
    }

    func generate(using modelContext: ModelContext) async {
        guard let imageData else {
            errorMessage = "Add a Figma screenshot before generating."
            return
        }
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }
        do {
            let output = try await OpenAIService().generate(
                apiKey: KeychainService.readAPIKey(),
                model: model,
                imageData: imageData,
                mimeType: imageMimeType,
                css: css,
                notes: notes,
                template: selectedTemplate,
                temperature: temperature,
                maxTokens: maxTokens
            )
            prompt = output
            let item = PromptHistoryItem(
                title: output.titleLine(fallback: selectedTemplate.rawValue),
                prompt: output,
                templateName: selectedTemplate.rawValue,
                imageData: imageData
            )
            modelContext.insert(item)
            try? modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func copyPrompt() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
    }

    func exportPrompt(asMarkdown: Bool) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [asMarkdown ? .init(filenameExtension: "md")! : .plainText]
        panel.nameFieldStringValue = "figma-implementation-prompt.\(asMarkdown ? "md" : "txt")"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? prompt.write(to: url, atomically: true, encoding: .utf8)
    }

    private func mimeType(for extension: String) -> String {
        switch `extension`.lowercased() {
        case "jpg", "jpeg": "image/jpeg"
        case "webp": "image/webp"
        default: "image/png"
        }
    }
}

private extension String {
    func titleLine(fallback: String) -> String {
        let title = split(separator: "\n").first(where: { $0.contains("#") || $0.count > 8 })
            .map { $0.replacing("#", with: "").trimmingCharacters(in: .whitespaces) }
        return title?.isEmpty == false ? String(title!.prefix(80)) : fallback
    }
}

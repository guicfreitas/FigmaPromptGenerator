import SwiftUI
import UniformTypeIdentifiers

enum AppTheme {
    static let background = Color(red: 0/255, green: 40/255, blue: 14/255)
    static let deepGreen = Color(red: 3/255, green: 30/255, blue: 12/255)
    static let card = Color(red: 5/255, green: 46/255, blue: 17/255)
    static let accent = Color(red: 156/255, green: 167/255, blue: 3/255)
    static let cream = Color(red: 250/255, green: 249/255, blue: 240/255)
}

struct ImageDropZone: View {
    @ObservedObject var viewModel: PromptGeneratorViewModel
    @State private var isTargeted = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isTargeted ? AppTheme.accent : AppTheme.cream.opacity(0.22), style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [7]))
                .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.card.opacity(0.7)))
            if let image = viewModel.image {
                HStack(spacing: 14) {
                    Image(nsImage: image).resizable().scaledToFill().frame(width: 110, height: 84).clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading) {
                        Text("Reference ready").font(.headline)
                        Text("Drop another image to replace it.").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Remove") { viewModel.image = nil; viewModel.imageData = nil }
                }.padding()
            } else {
                VStack(spacing: 9) {
                    Image(systemName: "photo.badge.plus").font(.title2).foregroundStyle(AppTheme.accent)
                    Text("Drop your Figma screenshot here").font(.headline)
                    Text("PNG, JPG, JPEG, or WEBP").font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("Choose Image") { viewModel.chooseImage() }
                        Button("Paste Image") { viewModel.pasteImage() }
                    }.padding(.top, 2)
                }
            }
        }
        .frame(minHeight: 150)
        .dropDestination(
            for: URL.self,
            action: { urls, _ in
                guard let url = urls.first else { return false }
                viewModel.importImage(from: url)
                return true
            },
            isTargeted: { isTargeted = $0 }
        )
    }
}

struct LabeledEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var font: Font = .body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder).foregroundStyle(.tertiary).padding(.horizontal, 9).padding(.vertical, 12)
                }
                TextEditor(text: $text).font(font).scrollContentBackground(.hidden).padding(5)
            }
            .frame(minHeight: 125)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.card))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.cream.opacity(0.15)))
        }
    }
}

struct SidebarButtonStyle: ButtonStyle {
    let selected: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.padding(.horizontal, 10).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(selected ? AppTheme.accent.opacity(0.18) : .clear))
            .foregroundStyle(selected ? AppTheme.cream : .secondary)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct GenerateButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.accent.opacity(configuration.isPressed ? 0.7 : 1)))
            .foregroundStyle(AppTheme.deepGreen)
            .fontWeight(.bold)
    }
}

struct MarkdownPrompt: View {
    let text: String
    var body: some View {
        let attributed = (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .full))) ?? AttributedString(text)
        Text(attributed).font(.body)
    }
}

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = PromptGeneratorViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PromptHistoryItem.createdAt, order: .reverse) private var history: [PromptHistoryItem]
    @State private var screen: Screen = .generator

    enum Screen: String, CaseIterable, Identifiable {
        case generator = "Generator", history = "History", settings = "Settings"
        var id: String { rawValue }
        var icon: String {
            switch self { case .generator: "sparkles"; case .history: "clock"; case .settings: "gearshape" }
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 18) {
                Label("Prompt Forge", systemImage: "wand.and.stars")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.cream)
                    .padding(.bottom, 10)
                ForEach(Screen.allCases) { item in
                    Button { screen = item } label: {
                        Label(item.rawValue, systemImage: item.icon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(SidebarButtonStyle(selected: screen == item))
                }
                Divider().overlay(AppTheme.cream.opacity(0.15))
                Text("TEMPLATE").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                Picker("Prompt template", selection: $viewModel.selectedTemplate) {
                    ForEach(PromptTemplate.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                Spacer()
                Text("Built for Figma → code").font(.caption).foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(minWidth: 210)
            .background(AppTheme.deepGreen)
        } detail: {
            Group {
                switch screen {
                case .generator: GeneratorView(viewModel: viewModel, modelContext: modelContext)
                case .history: HistoryView(history: history, viewModel: viewModel, screen: $screen)
                case .settings: SettingsView()
                }
            }
            .background(AppTheme.background)
        }
        .preferredColorScheme(.dark)
        .alert("Something needs attention", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) { Button("OK", role: .cancel) {} } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct GeneratorView: View {
    @ObservedObject var viewModel: PromptGeneratorViewModel
    let modelContext: ModelContext
    @State private var rawText = false

    var body: some View {
        HSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    ImageDropZone(viewModel: viewModel)
                    LabeledEditor(title: "Figma Inspect CSS", placeholder: "Paste CSS, design tokens, or inspection output…", text: $viewModel.css, font: .system(.body, design: .monospaced))
                    LabeledEditor(title: "Notes", placeholder: "Add context, interactions, component reuse guidance…", text: $viewModel.notes)
                    Button {
                        Task { await viewModel.generate(using: modelContext) }
                    } label: {
                        Label(viewModel.isGenerating ? "Generating…" : "Generate Prompt", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GenerateButtonStyle())
                    .disabled(viewModel.isGenerating)
                }
                .padding(28)
            }
            .frame(minWidth: 470)
            promptPanel(rawText: $rawText)
                .frame(minWidth: 450)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Create implementation prompts").font(.system(size: 26, weight: .bold))
            Text("Turn a Figma reference into a detailed, production-ready brief for your coding agent.")
                .foregroundStyle(.secondary)
        }
    }

    private func promptPanel(rawText: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Generated Prompt").font(.title3.weight(.semibold))
                    Text(viewModel.selectedTemplate.rawValue).font(.caption).foregroundStyle(AppTheme.accent)
                }
                Spacer()
                Picker("View", selection: rawText) {
                    Text("Preview").tag(false); Text("Raw").tag(true)
                }
                .pickerStyle(.segmented).frame(width: 150)
            }
            Group {
                if viewModel.prompt.isEmpty {
                    ContentUnavailableView("Your prompt will appear here", systemImage: "text.document",
                        description: Text("Add a screenshot, optional CSS and notes, then generate."))
                } else if rawText.wrappedValue {
                    TextEditor(text: $viewModel.prompt).font(.body)
                } else {
                    ScrollView {
                        MarkdownPrompt(text: viewModel.prompt)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.trailing, 8)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            HStack {
                Button("Copy Prompt", systemImage: "doc.on.doc") { viewModel.copyPrompt() }
                Spacer()
                Menu("Export", systemImage: "square.and.arrow.up") {
                    Button("Markdown (.md)") { viewModel.exportPrompt(asMarkdown: true) }
                    Button("Plain Text (.txt)") { viewModel.exportPrompt(asMarkdown: false) }
                }
            }
        }
        .padding(28)
        .background(AppTheme.card)
    }
}

private struct HistoryView: View {
    let history: [PromptHistoryItem]
    @ObservedObject var viewModel: PromptGeneratorViewModel
    @Binding var screen: ContentView.Screen

    var body: some View {
        List {
            Section("Recent prompts") {
                ForEach(history) { item in
                    Button {
                        viewModel.prompt = item.prompt
                        viewModel.selectedTemplate = PromptTemplate(rawValue: item.templateName) ?? .generic
                        screen = .generator
                    } label: {
                        HStack {
                            if let data = item.thumbnailData, let image = NSImage(data: data) {
                                Image(nsImage: image).resizable().scaledToFill().frame(width: 56, height: 40).clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            VStack(alignment: .leading) {
                                Text(item.title).lineLimit(1)
                                Text(item.createdAt, style: .date).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }.buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("History")
    }
}

private struct SettingsView: View {
    @State private var apiKey = KeychainService.readAPIKey()
    @AppStorage("model") private var model = "gpt-5"
    @AppStorage("temperature") private var temperature = 0.3
    @AppStorage("maxTokens") private var maxTokens = 4000
    @State private var saved = false

    var body: some View {
        Form {
            Section("OpenAI") {
                SecureField("API key", text: $apiKey)
                Picker("Default model", selection: $model) {
                    Text("GPT-5").tag("gpt-5"); Text("GPT-5 Mini").tag("gpt-5-mini")
                }
                Button(saved ? "Saved to Keychain" : "Save API Key") {
                    try? KeychainService.saveAPIKey(apiKey); saved = true
                }
            }
            Section("Generation") {
                Slider(value: $temperature, in: 0...1, step: 0.1) { Text("Temperature") }
                Text("\(temperature, specifier: "%.1f")").foregroundStyle(.secondary)
                Stepper("Max tokens: \(maxTokens)", value: $maxTokens, in: 500...16_000, step: 500)
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Settings")
    }
}

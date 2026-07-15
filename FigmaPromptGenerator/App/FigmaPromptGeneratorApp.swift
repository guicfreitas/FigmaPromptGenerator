import SwiftUI
import SwiftData

@main
struct FigmaPromptGeneratorApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([PromptHistoryItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 820, minHeight: 640)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

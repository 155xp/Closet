import SwiftUI
import SwiftData

@main
struct ClosetApp: App {
    @AppStorage("appearance") private var appearance = Appearance.system
    private let container: ModelContainer

    init() {
        let ephemeral = ProcessInfo.processInfo.arguments.contains("--empty-closet")
            || ProcessInfo.processInfo.arguments.contains("--preview-wardrobe")
        do {
            container = try ModelContainer(for: ClothingItem.self, ImportedGarment.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: ephemeral))
        } catch {
            fatalError("Couldn't open the closet: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ClosetView()
                .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(container)
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum ClosetStyle {
    static let background = Color(uiColor: .init { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.075, green: 0.075, blue: 0.08, alpha: 1)
            : UIColor(red: 0.985, green: 0.983, blue: 0.979, alpha: 1)
    })
}

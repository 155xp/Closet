import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance") private var appearance = Appearance.system
    @Query private var items: [ClothingItem]

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("appearancePicker")
                }
                Section {
                    LabeledContent("Pieces", value: "\(items.count)")
                    LabeledContent("Storage", value: "On this iPhone")
                } header: {
                    Text("Your closet")
                } footer: {
                    Text("Your photos stay in the app. No account needed.")
                }
                Section {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1")
                }
            }
            .scrollContentBackground(.hidden)
            .background(ClosetStyle.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("doneSettingsButton")
                }
            }
        }
        .preferredColorScheme(appearance.colorScheme)
    }
}

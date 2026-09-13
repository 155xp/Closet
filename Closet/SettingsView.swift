import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance") private var appearance = Appearance.system
    @Query private var items: [ClothingItem]
    @State private var selectedIcon = AppIconChoice.automatic
    @State private var changingIcon = false
    @State private var iconChangeFailed = false

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
                    ForEach(AppIconChoice.allCases) { option in
                        Button {
                            changeIcon(to: option)
                        } label: {
                            HStack(spacing: 14) {
                                Group {
                                    if let iconName = option.alternateName {
                                        Image("\(iconName)Preview")
                                            .resizable()
                                            .scaledToFit()
                                    } else {
                                        Image(systemName: "circle.lefthalf.filled")
                                            .font(.title2)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .background(.quaternary)
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(.rect(cornerRadius: 12))
                                .accessibilityHidden(true)
                                Text(option.title)
                                Spacer()
                                if selectedIcon == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .accessibilityHidden(true)
                                }
                            }
                            .foregroundStyle(.primary)
                            .padding(.vertical, 3)
                            .contentShape(Rectangle())
                        }
                        .disabled(changingIcon || !UIApplication.shared.supportsAlternateIcons)
                        .accessibilityIdentifier("appIcon_\(option.rawValue)")
                        .accessibilityValue(selectedIcon == option ? "Selected" : "")
                    }
                } header: {
                    Text("App icon")
                } footer: {
                    Text("Automatic follows your iPhone's icon appearance. Light and Dark keep the icon you choose.")
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
            .onAppear { selectedIcon = AppIconChoice.current }
            .alert("Couldn't change the app icon", isPresented: $iconChangeFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your previous icon is still selected. Please try again.")
            }
        }
        .preferredColorScheme(appearance.colorScheme)
    }

    private func changeIcon(to option: AppIconChoice) {
        guard option != selectedIcon, !changingIcon else { return }
        changingIcon = true
        Task { @MainActor in
            defer { changingIcon = false }
            do {
                try await UIApplication.shared.setAlternateIconName(option.alternateName)
                selectedIcon = option
            } catch {
                selectedIcon = AppIconChoice.current
                iconChangeFailed = true
            }
        }
    }
}

private enum AppIconChoice: String, CaseIterable, Identifiable {
    case automatic, light, dark

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var alternateName: String? {
        switch self {
        case .automatic: nil
        case .light: "AppIconLight"
        case .dark: "AppIconDark"
        }
    }

    @MainActor static var current: AppIconChoice {
        allCases.first { $0.alternateName == UIApplication.shared.alternateIconName } ?? .automatic
    }
}

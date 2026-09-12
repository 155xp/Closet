import SwiftUI
import SwiftData
import PhotosUI
import ImageIO
import UniformTypeIdentifiers
import AVFoundation

struct AddPieceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var category: ClothingCategory
    @State private var name = ""
    @State private var selection: PhotosPickerItem?
    @State private var photo: Data?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCamera = false
    @State private var cameraAccessDenied = false
    @State private var needsWashing = false

    init(initialCategory: ClothingCategory) {
        _category = State(initialValue: initialCategory)
    }

    var body: some View {
        let preview = photo.flatMap(UIImage.init(data:))
        let loading = isLoading
        let selectedCategory = category

        return NavigationStack {
            Form {
                Section {
                    VStack(spacing: 20) {
                        if loading {
                            ProgressView("Loading photo…").frame(height: 180)
                        } else if let image = preview {
                            Image(uiImage: image)
                                .resizable().scaledToFit().frame(height: 210)
                                .accessibilityLabel("Selected clothing photo")
                        } else {
                            HangerView(category: selectedCategory)
                                .frame(width: 145)
                                .padding(.top, 24)
                        }
                        HStack(spacing: 12) {
                            Button { Task { await openCamera() } } label: {
                                Label("Take photo", systemImage: "camera")
                                    .frame(maxWidth: .infinity).padding(.vertical, 5)
                            }
                            .buttonStyle(.glass)
                            .accessibilityIdentifier("takePhotoButton")
                            PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                                Label("Photos", systemImage: "photo")
                                    .frame(maxWidth: .infinity).padding(.vertical, 5)
                            }
                            .buttonStyle(.glass)
                            .accessibilityIdentifier("choosePhotoButton")
                        }
                        .font(.subheadline.weight(.medium))
                        .tint(.primary)
                        .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isLoading)
                } footer: {
                    Text("Capture one piece at a time, with the whole garment in the frame.")
                }

                Section {
                    TextField("Name, like Everyday tee", text: $name)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityIdentifier("pieceNameField")
                    Picker("Category", selection: $category) {
                        ForEach(ClothingCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    .accessibilityIdentifier("pieceCategoryPicker")
                    Toggle("Needs washing", isOn: $needsWashing)
                        .accessibilityIdentifier("newPieceNeedsWashing")
                } footer: {
                    Text("Photos are saved in the app on this iPhone.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(ClosetStyle.background)
            .navigationTitle("Add a piece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.accessibilityIdentifier("cancelAddButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: save)
                        .disabled(photo == nil || isLoading)
                        .accessibilityIdentifier("savePieceButton")
                }
            }
            .task(id: selection) { await loadPhoto() }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    showingCamera = false
                    guard let data = image.jpegData(compressionQuality: 0.92) else {
                        errorMessage = "That photo couldn't be opened. Please take another."
                        return
                    }
                    Task { await preparePhoto(data) }
                } onCancel: {
                    showingCamera = false
                }
                .ignoresSafeArea()
            }
            .alert("Allow camera access", isPresented: $cameraAccessDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Allow Closet to use the camera in Settings, or choose an existing photo.")
            }
            .alert("Couldn't add this piece", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "Please try again.") }
        }
    }

    private func loadPhoto() async {
        guard let selection else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            guard let data = try await selection.loadTransferable(type: Data.self) else {
                throw PhotoPreparation.PhotoError.unreadable
            }
            await preparePhoto(data)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "That photo couldn't be opened. Try another image."
        }
    }

    private func preparePhoto(_ data: Data) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let prepared = try await Task.detached(priority: .userInitiated) {
                try PhotoPreparation.prepare(data)
            }.value
            try Task.checkCancellation()
            photo = prepared
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "That photo couldn't be opened. Try another image."
        }
    }

    private func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            errorMessage = "The camera isn't available on this device. You can choose an existing photo instead."
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            if await AVCaptureDevice.requestAccess(for: .video) { showingCamera = true }
            else { cameraAccessDenied = true }
        default:
            cameraAccessDenied = true
        }
    }

    private func save() {
        guard let photo else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = ClothingItem(name: trimmed.isEmpty ? "Untitled \(category.singular)" : trimmed,
                                category: category, photo: photo)
        item.needsWashing = needsWashing
        context.insert(item)
        do {
            try context.save()
            dismiss()
        } catch {
            context.rollback()
            errorMessage = "Your piece couldn't be saved. Please try again."
        }
    }
}

enum PhotoPreparation {
    enum PhotoError: Error { case unreadable }

    /// Downsampling before decoding bounds memory use and preserves cutout transparency.
    nonisolated static func prepare(_ data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1600,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw PhotoError.unreadable }

        let result = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(result, UTType.png.identifier as CFString, 1, nil)
        else { throw PhotoError.unreadable }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw PhotoError.unreadable }
        return result as Data
    }
}

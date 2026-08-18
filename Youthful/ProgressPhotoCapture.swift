import SwiftUI
import SwiftData
import PhotosUI
import UIKit

// MARK: - Progress photo capture and management

struct ProgressPhotoCaptureView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]

    @State private var selectedItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingDeleteConfirmation = false
    @State private var photoToDelete: ProgressPhoto?
    @State private var selectedLabel = "Front"
    @State private var pendingImageData: Data?
    @State private var showingLabelPicker = false

    private let labels = ["Front", "Left", "Right", "Other"]

    var body: some View {
        ZStack {
            PremiumBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    captureButtons
                    if !photos.isEmpty {
                        photoList
                    } else {
                        PremiumCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "camera.fill").font(.title2).foregroundStyle(PremiumTheme.warm)
                                Text("No progress photos yet").font(.headline)
                                Text("Add a photo from your library or take one with the camera. Photos stay inside Youthful until you delete them.")
                                    .font(.subheadline).foregroundStyle(PremiumTheme.muted)
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 30)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { dismiss() }
            }
        }
        .confirmationDialog("Delete progress photo?", isPresented: Binding(get: { photoToDelete != nil }, set: { if !$0 { photoToDelete = nil } }), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deletePhoto()
            }
            Button("Cancel", role: .cancel) { photoToDelete = nil }
        } message: {
            Text("This removes the photo from Youthful. It cannot be undone.")
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { data in
                showingCamera = false
                if let data { pendingImageData = data; showingLabelPicker = true }
            }
            .ignoresSafeArea()
        }
        .confirmationDialog("Photo label", isPresented: $showingLabelPicker, titleVisibility: .visible) {
            ForEach(labels, id: \.self) { label in
                Button(label) {
                    selectedLabel = label
                    savePendingPhoto()
                }
            }
            Button("Cancel", role: .cancel) { pendingImageData = nil }
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        pendingImageData = data
                        showingLabelPicker = true
                        selectedItem = nil
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            CapsuleLabel(text: "Progress timeline")
            Text("Compare progress").font(.system(size: 34, weight: .semibold, design: .serif))
            Text("Add dated photos, keep them organized and delete any you no longer want.")
                .font(.subheadline).foregroundStyle(PremiumTheme.muted)
        }
    }

    private var captureButtons: some View {
        VStack(spacing: 10) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Choose photo", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .background(PremiumTheme.ink)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                showingCamera = true
            } label: {
                Label("Take photo", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .background(.white.opacity(0.78))
                    .foregroundStyle(PremiumTheme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var photoList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Saved photos").font(.system(size: 21, weight: .semibold, design: .serif))
                Spacer()
                Text("\(photos.count)").font(.caption.weight(.bold)).foregroundStyle(PremiumTheme.muted)
            }

            ForEach(photos) { photo in
                PremiumCard {
                    HStack(spacing: 12) {
                        Group {
                            if let image = UIImage(data: photo.imageData) {
                                Image(uiImage: image).resizable().scaledToFill()
                            } else {
                                Color.black.opacity(0.05)
                            }
                        }
                        .frame(width: 82, height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(photo.label).font(.subheadline.weight(.semibold))
                            Text(photo.date.formatted(.dateTime.month(.abbreviated).day().year()))
                                .font(.caption).foregroundStyle(PremiumTheme.muted)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            photoToDelete = photo
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 38, height: 38)
                                .background(Color.red.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Delete \(photo.label) photo")
                    }
                }
            }
        }
    }

    private func savePendingPhoto() {
        guard let data = pendingImageData, UIImage(data: data) != nil else {
            pendingImageData = nil
            return
        }
        let photo = ProgressPhoto(label: selectedLabel, imageData: data)
        context.insert(photo)
        try? context.save()
        pendingImageData = nil
    }

    private func deletePhoto() {
        guard let photo = photoToDelete else { return }
        context.delete(photo)
        try? context.save()
        photoToDelete = nil
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    let completion: (Data?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (Data?) -> Void
        init(completion: @escaping (Data?) -> Void) { self.completion = completion }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            completion(image?.jpegData(compressionQuality: 0.9))
        }
    }
}

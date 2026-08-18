import Foundation
import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func enable() async {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
        if granted { schedule() }
    }

    func schedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["am", "pm", "photo"])

        var am = DateComponents(); am.hour = 8; am.minute = 0
        var pm = DateComponents(); pm.hour = 21; pm.minute = 30

        let morning = UNMutableNotificationContent()
        morning.title = "☀️ Youthful"
        morning.body = "Cleanse, moisturize, SPF 50 and style your hair."
        morning.sound = .default

        let evening = UNMutableNotificationContent()
        evening.title = "🌙 Youthful"
        evening.body = "Time for your night routine."
        evening.sound = .default

        center.add(UNNotificationRequest(identifier:"am", content:morning, trigger:UNCalendarNotificationTrigger(dateMatching:am, repeats:true)))
        center.add(UNNotificationRequest(identifier:"pm", content:evening, trigger:UNCalendarNotificationTrigger(dateMatching:pm, repeats:true)))
    }

    func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["am","pm","photo"])
    }
}

// MARK: - Progress photo capture

struct ProgressPhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]

    @State private var pickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingCameraUnavailable = false
    @State private var selectedLabel = "Front"
    @State private var earlierIndex = 1
    @State private var laterIndex = 0

    private let labels = ["Front", "Left", "Right"]

    var body: some View {
        ZStack {
            PremiumBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        CapsuleLabel(text: "Progress photos")
                        Text("Compare your progress")
                            .font(.system(size: 34, weight: .semibold, design: .serif))
                        Text("Add a photo from your library or take a new one. Then choose any two dates to compare side-by-side.")
                            .font(.subheadline)
                            .foregroundStyle(PremiumTheme.muted)
                    }

                    PremiumCard {
                        VStack(alignment: .leading, spacing: 13) {
                            Text("ADD A PHOTO")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(1.8)
                                .foregroundStyle(PremiumTheme.muted)

                            Picker("Angle", selection: $selectedLabel) {
                                ForEach(labels, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.segmented)

                            HStack(spacing: 10) {
                                PhotosPicker(selection: $pickerItem, matching: .images) {
                                    Label("Choose photo", systemImage: "photo.on.rectangle")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(PremiumTheme.ink)

                                Button {
                                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                        showingCamera = true
                                    } else {
                                        showingCameraUnavailable = true
                                    }
                                    CoachHaptics.selection()
                                } label: {
                                    Label("Take photo", systemImage: "camera.fill")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                }
                                .buttonStyle(.bordered)
                                .tint(PremiumTheme.ink)
                            }
                        }
                    }

                    if photos.isEmpty {
                        PremiumCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title2)
                                    .foregroundStyle(PremiumTheme.warm)
                                Text("No progress photos yet")
                                    .font(.headline)
                                Text("Add your first photo above. Once you have two, the comparison view will appear below.")
                                    .font(.subheadline)
                                    .foregroundStyle(PremiumTheme.muted)
                            }
                        }
                    } else {
                        photoList
                    }

                    if photos.count >= 2 {
                        comparison
                    }
                }
                .padding(20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Compare progress")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: .constant(false), selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run { save(data: data) }
                }
                await MainActor.run { pickerItem = nil }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                if let data = image.jpegData(compressionQuality: 0.88) {
                    save(data: data)
                }
                showingCamera = false
            } onCancel: {
                showingCamera = false
            }
            .ignoresSafeArea()
        }
        .alert("Camera unavailable", isPresented: $showingCameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device or simulator does not have an available camera. You can still choose a photo from your library.")
        }
    }

    private var photoList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved photos")
                .font(.system(size: 21, weight: .semibold, design: .serif))

            ForEach(photos) { photo in
                if let image = UIImage(data: photo.imageData) {
                    PremiumCard {
                        HStack(spacing: 12) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 74, height: 74)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(photo.label).font(.subheadline.weight(.semibold))
                                Text(photo.date.formatted(.dateTime.month(.abbreviated).day().year()))
                                    .font(.caption)
                                    .foregroundStyle(PremiumTheme.muted)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Side-by-side comparison")
                .font(.system(size: 21, weight: .semibold, design: .serif))

            PremiumCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        comparisonPicker(title: "Earlier", selection: $earlierIndex)
                        comparisonPicker(title: "Later", selection: $laterIndex)
                    }

                    HStack(alignment: .top, spacing: 10) {
                        comparisonImage(photos[min(earlierIndex, photos.count - 1)])
                        comparisonImage(photos[min(laterIndex, photos.count - 1)])
                    }
                }
            }
        }
    }

    private func comparisonPicker(title: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(PremiumTheme.muted)
            Picker(title, selection: selection) {
                ForEach(0..<photos.count, id: \.self) { index in
                    Text(photos[index].date.formatted(.dateTime.month(.abbreviated).day().year())).tag(index)
                }
            }
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func comparisonImage(_ photo: ProgressPhoto) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let image = UIImage(data: photo.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            Text(photo.date.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.caption.weight(.bold))
        }
        .frame(maxWidth: .infinity)
    }

    private func save(data: Data) {
        let photo = ProgressPhoto(label: selectedLabel, imageData: data, date: .now)
        context.insert(photo)
        try? context.save()
        CoachHaptics.success()
        if photos.count + 1 >= 2 {
            laterIndex = 0
            earlierIndex = min(1, photos.count)
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            else { parent.onCancel() }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}

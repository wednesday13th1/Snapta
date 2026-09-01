import SwiftUI
import UIKit

struct CameraScreen: View {
    @ObservedObject var flow: LearningFlow
    @State private var pickerSource: PickerSource?

    var body: some View {
        ZStack {
            CameraPreviewPlaceholder().ignoresSafeArea(edges: .bottom)
            VStack {
                WordCard(word: flow.word, reading: flow.currentEntry.reading, compact: true).padding(.top, 8)
                Text("身の回りから「\(flow.word)」を見つけよう")
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(.black.opacity(0.42), in: Capsule())
                Spacer()
                Text("その場で撮るか、アルバムから選んでね")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(.black.opacity(0.42), in: Capsule())
                HStack(spacing: 22) {
                    PhotoChoiceButton(title: "カメラで撮る", icon: "camera.fill", isShutter: true) {
                        pickerSource = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .library
                    }
                    PhotoChoiceButton(title: "写真を選ぶ", icon: "photo.on.rectangle", isShutter: false) {
                        pickerSource = .library
                    }
                }
                .padding(.top, 15).padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
        }
        .sheet(item: $pickerSource) { source in
            ImagePicker(sourceType: source.uiSource, image: $flow.capturedImage) { didChooseImage in
                pickerSource = nil
                if didChooseImage {
                    flow.saveCapturedImage()
                    flow.go(.saved)
                }
            }
            .ignoresSafeArea(edges: source == .camera ? .all : [])
        }
    }
}

private enum PickerSource: String, Identifiable {
    case camera, library
    var id: String { rawValue }
    var uiSource: UIImagePickerController.SourceType { self == .camera ? .camera : .photoLibrary }
}

private struct PhotoChoiceButton: View {
    let title: String
    let icon: String
    let isShutter: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(.white).frame(width: 66, height: 66)
                    if isShutter {
                        Circle().stroke(SnaptaTheme.ink.opacity(0.18), lineWidth: 1).frame(width: 56, height: 56)
                    } else {
                        Image(systemName: icon).font(.system(size: 25, weight: .medium)).foregroundStyle(SnaptaTheme.indigo)
                    }
                    Circle().stroke(.white.opacity(0.65), lineWidth: 2).frame(width: 76, height: 76)
                }
                Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
            }
        }
        .accessibilityLabel(title)
    }
}

private struct CameraPreviewPlaceholder: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.23, green: 0.31, blue: 0.30), Color(red: 0.48, green: 0.53, blue: 0.43)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(.white.opacity(0.12)).frame(width: 230).blur(radius: 5).offset(x: 100, y: -100)
            RoundedRectangle(cornerRadius: 80).fill(.white.opacity(0.08)).frame(width: 300, height: 180).rotationEffect(.degrees(-18)).offset(x: -80, y: 150)
            Image(systemName: "viewfinder").font(.system(size: 190, weight: .ultraLight)).foregroundStyle(.white.opacity(0.25))
        }
    }
}

private struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var image: UIImage?
    let onComplete: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        if sourceType == .camera { picker.cameraCaptureMode = .photo }
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let chosenImage = info[.originalImage] as? UIImage
            parent.image = chosenImage
            parent.onComplete(chosenImage != nil)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.onComplete(false) }
    }
}

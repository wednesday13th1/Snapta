import SwiftUI
import PhotosUI

struct TodayWordScreen: View {
    @ObservedObject var flow: LearningFlow
    @State private var appeared = false
    @State private var showAddCard = false

    var body: some View {
        ScrollView {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(flow.entries) { entry in
                        Button {
                            withAnimation { flow.select(entry) }
                        } label: {
                            Text(entry.word)
                                .font(SnaptaTheme.mincho(14, weight: .semibold))
                                .padding(.horizontal, 14).frame(height: 38)
                                .foregroundStyle(flow.currentEntryID == entry.id ? .white : SnaptaTheme.indigo)
                                .background(flow.currentEntryID == entry.id ? SnaptaTheme.indigo : SnaptaTheme.paperLight)
                                .clipShape(Capsule()).overlay(Capsule().stroke(SnaptaTheme.indigo.opacity(0.2)))
                        }
                    }
                    Button { showAddCard = true } label: {
                        Label("追加", systemImage: "plus").font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 14).frame(height: 38)
                            .foregroundStyle(SnaptaTheme.vermilion).background(SnaptaTheme.paperLight)
                            .clipShape(Capsule()).overlay(Capsule().stroke(SnaptaTheme.vermilion.opacity(0.35)))
                    }
                }.padding(.horizontal, 20)
            }
            .padding(.bottom, 12)

            PaperPanel {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("8月31日  日曜日")
                            .font(.system(size: 12, weight: .medium))
                            .tracking(1)
                            .foregroundStyle(SnaptaTheme.ink.opacity(0.5))
                        Text("きょうの一枚")
                            .font(SnaptaTheme.mincho(21, weight: .semibold))
                            .foregroundStyle(SnaptaTheme.ink)
                    }

                    WordCard(word: flow.word, reading: flow.currentEntry.reading)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    VStack(spacing: 10) {
                        Text("ことばの意味")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(SnaptaTheme.moss)
                        Text(flow.currentEntry.meaningText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SnaptaTheme.ink.opacity(0.78))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(SnaptaTheme.moss.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    PrimaryButton("撮って探す", icon: "camera.fill") { flow.go(.camera) }
                    Button { flow.go(.flashcards) } label: {
                        Label("単語帳をめくる", systemImage: "book.closed.fill")
                            .font(.system(size: 16, weight: .bold)).frame(maxWidth: .infinity).frame(height: 50)
                            .foregroundStyle(SnaptaTheme.indigo)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(SnaptaTheme.indigo.opacity(0.4)))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .sheet(isPresented: $showAddCard) {
            AddKarutaSheet(flow: flow, isPresented: $showAddCard)
        }
    }
}

private struct AddKarutaSheet: View {
    @ObservedObject var flow: LearningFlow
    @Binding var isPresented: Bool
    @State private var word = ""
    @State private var reading = ""
    @State private var imageTitle = ""
    @State private var meaning = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var image: UIImage?

    var canSave: Bool { !word.trimmingCharacters(in: .whitespaces).isEmpty && image != nil }

    var body: some View {
        NavigationStack {
            JapaneseBackground {
                ScrollView {
                    PaperPanel {
                        VStack(spacing: 18) {
                            Text("新しいことば札")
                                .font(SnaptaTheme.mincho(25, weight: .semibold))
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6).fill(SnaptaTheme.paper).frame(height: 190)
                                    if let image {
                                        Image(uiImage: image).resizable().scaledToFill().frame(height: 190).clipped()
                                    } else {
                                        VStack(spacing: 10) {
                                            Image(systemName: "photo.badge.plus").font(.system(size: 32))
                                            Text("画像を選ぶ").font(.system(size: 15, weight: .bold))
                                        }.foregroundStyle(SnaptaTheme.indigo)
                                    }
                                }.clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            LabeledField(label: "ことば", placeholder: "例：屈折", text: $word)
                            LabeledField(label: "よみかた", placeholder: "例：くっせつ", text: $reading)
                            LabeledField(label: "画像の名前", placeholder: "例：水の中のストロー", text: $imageTitle)
                            LabeledField(label: "ことばの意味", placeholder: "短く、わかりやすい意味", text: $meaning)
                            PrimaryButton("ことば札を追加", icon: "plus") {
                                guard let image else { return }
                                flow.addEntry(word: word, reading: reading, imageTitle: imageTitle.isEmpty ? "登録した写真" : imageTitle, meaning: meaning, image: image)
                                isPresented = false
                            }
                            .disabled(!canSave).opacity(canSave ? 1 : 0.45)
                        }
                    }.padding(20)
                }
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("閉じる") { isPresented = false } } }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self), let loaded = UIImage(data: data) {
                        await MainActor.run { image = loaded }
                    }
                }
            }
        }
    }
}

private struct LabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12, weight: .bold)).foregroundStyle(SnaptaTheme.ink.opacity(0.6))
            TextField(placeholder, text: $text).textFieldStyle(.plain).padding(13)
                .background(SnaptaTheme.paper).clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(SnaptaTheme.line))
        }
    }
}

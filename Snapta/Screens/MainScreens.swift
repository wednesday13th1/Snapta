import SwiftUI

struct ScreenHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(SnaptaTheme.mincho(28, weight: .semibold)).foregroundStyle(SnaptaTheme.ink)
                .lineLimit(1).minimumScaleFactor(0.72)
            Text(subtitle).font(.system(size: 14, weight: .medium)).foregroundStyle(SnaptaTheme.ink.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeTabScreen: View {
    @ObservedObject var flow: LearningFlow
    let openKaruta: () -> Void
    let openNotebook: () -> Void
    let startLearning: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScreenHeader(title: "Snapta", subtitle: "きょうの言葉を見つけよう")

                if flow.hasUnregisteredWords {
                    PaperPanel {
                    VStack(spacing: 22) {
                        Text("きょうの言葉")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(SnaptaTheme.vermilion)

                        VStack(spacing: 7) {
                            Text(flow.currentEntry.reading)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(SnaptaTheme.ink.opacity(0.48))
                                .lineLimit(1).minimumScaleFactor(0.7)
                            Text(flow.word)
                                .font(SnaptaTheme.mincho(48, weight: .semibold))
                                .tracking(5)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }

                        PrimaryButton("言葉を探す", icon: "camera.fill") {
                            startLearning()
                        }
                    }
                    }
                } else {
                    EmptyState(icon: "checkmark.circle.fill", text: "すべての言葉をカルタに追加したよ！")
                }

                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                    Text("新しい言葉は、下の「追加」から入れよう")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SnaptaTheme.ink.opacity(0.52))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 30)
        }
    }
}

struct HomeLearningFlowScreen: View {
    private enum Step { case meaning, photo }

    @ObservedObject var flow: LearningFlow
    let close: () -> Void
    @State private var step: Step = .meaning
    @State private var meaning = ""
    @State private var image: UIImage?
    @State private var pickerSource: PickerSource?
    @State private var completed = false
    @FocusState private var meaningFocused: Bool

    private var trimmedMeaning: String {
        meaning.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        JapaneseBackground {
            VStack(spacing: 0) {
                header
                ScrollView {
                    PaperPanel {
                        if step == .meaning { meaningStep } else { photoStep }
                    }
                    .frame(maxWidth: SnaptaSpacing.maxContentWidth)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, SnaptaSpacing.screen)
                    .padding(.top, SnaptaSpacing.section)
                    .padding(.bottom, SnaptaSpacing.section)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .overlay {
                if completed {
                    Label("カルタに追加しました", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 18)
                        .background(SnaptaTheme.indigo, in: Capsule())
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .sheet(item: $pickerSource) { source in
            ImagePicker(sourceType: source.uiSource, image: $image) { _ in pickerSource = nil }
                .ignoresSafeArea(edges: source == .camera ? .all : [])
        }
    }

    private var header: some View {
        ZStack {
            Text(step == .meaning ? "意味を調べてみよう" : "写真を探そう")
                .font(SnaptaTheme.mincho(20, weight: .semibold))
                .foregroundStyle(SnaptaTheme.indigo)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 82)
            HStack {
                Button {
                    if step == .photo && image == nil {
                        step = .meaning
                    } else {
                        close()
                    }
                } label: {
                    Label("戻る", systemImage: "chevron.left")
                        .lineLimit(1)
                        .frame(minWidth: 62, minHeight: 44)
                }
                Spacer()
            }
        }
        .frame(minHeight: 48)
        .padding(.horizontal, 8)
        .background(SnaptaTheme.paper.opacity(0.94))
    }

    private var meaningStep: some View {
        VStack(spacing: 0) {
            WordCard(word: flow.word, reading: flow.currentEntry.reading)
                .padding(.bottom, SnaptaSpacing.section)
            Text("この言葉は、どんな意味だろう？")
                .font(.system(size: 17, weight: .bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, SnaptaSpacing.screen)
            TextField("", text: $meaning, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(4...7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, minHeight: 120, idealHeight: 140, alignment: .topLeading)
                .background(Color.clear)
                .focused($meaningFocused)
                .submitLabel(.done)
                .onSubmit { meaningFocused = false }
                .background(SnaptaTheme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(SnaptaTheme.line))
                .padding(.bottom, SnaptaSpacing.screen)

            Text("辞書の文章をそのまま写さなくても大丈夫。\n自分の言葉で書いてみよう。")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SnaptaTheme.ink.opacity(0.58))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 22)

            PrimaryButton("次へ") {
                meaningFocused = false
                meaning = trimmedMeaning
                step = .photo
            }
            .disabled(trimmedMeaning.isEmpty)
            .opacity(trimmedMeaning.isEmpty ? 0.4 : 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard meaningFocused else { return }
            dismissMeaningKeyboard()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("閉じる") { dismissMeaningKeyboard() }
            }
        }
    }

    private func dismissMeaningKeyboard() {
        meaningFocused = false
    }

    private var photoStep: some View {
        VStack(spacing: 20) {
            Text(flow.word)
                .font(SnaptaTheme.mincho(34, weight: .semibold))
                .foregroundStyle(SnaptaTheme.indigo)

            if let image {
                Text(meaning).font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(uiImage: image).resizable().scaledToFit()
                    .frame(maxHeight: 330)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                PrimaryButton("この写真でカルタを作る", icon: "checkmark") { save(image) }
                    .disabled(completed)
                Button("撮り直す") { openCamera() }.frame(minHeight: 44)
            } else {
                Text("\(flow.word)をさがしてみよう")
                    .font(SnaptaTheme.mincho(25, weight: .semibold))
                Text("身のまわりで、この言葉に合うものを見つけてみよう。")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SnaptaTheme.ink.opacity(0.62))
                    .multilineTextAlignment(.center)
                PrimaryButton("写真を撮る", icon: "camera.fill", action: openCamera)
                Button { pickerSource = .library } label: {
                    Label("写真から選ぶ", systemImage: "photo.on.rectangle")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .foregroundStyle(SnaptaTheme.indigo)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(SnaptaTheme.indigo.opacity(0.4)))
                }
            }
        }
    }

    private func openCamera() {
        pickerSource = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .library
    }

    private func save(_ image: UIImage) {
        guard !completed else { return }
        flow.registerCurrentWord(userMeaning: meaning, image: image)
        withAnimation(.easeOut(duration: 0.2)) { completed = true }
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            close()
        }
    }
}

struct KarutaLandingScreen: View {
    @ObservedObject var flow: LearningFlow
    let start: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScreenHeader(title: "カルタ", subtitle: "写真を見て、言葉を当てよう")

                PaperPanel {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle().fill(SnaptaTheme.indigo.opacity(0.1)).frame(width: 92, height: 92)
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(SnaptaTheme.indigo)
                        }

                        VStack(spacing: 7) {
                            Text(flow.learnedEntries.isEmpty ? "写真の札を作ろう" : "\(flow.learnedEntries.count)枚の札であそべるよ")
                                .font(SnaptaTheme.mincho(22, weight: .semibold))
                            Text(flow.learnedEntries.isEmpty ? "ホームで言葉をさがして、写真をとってね。" : "読みを聞いて、写真と意味の札を横へ払おう！")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(SnaptaTheme.ink.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }

                        PrimaryButton("カルタに挑戦！", icon: "play.fill", action: start)
                            .disabled(flow.learnedEntries.isEmpty)
                            .opacity(flow.learnedEntries.isEmpty ? 0.4 : 1)
                    }
                }
            }
            .padding(20)
        }
    }
}

struct NotebookScreen: View {
    private enum Mode: String, CaseIterable { case list = "リスト", cards = "カード" }
    @ObservedObject var flow: LearningFlow
    @State private var selected: KarutaEntry?
    @State private var mode: Mode = .list
    @State private var cardIndex = 0
    @State private var showsMeaning = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: SnaptaSpacing.related) {
                ScreenHeader(title: "わたしの単語帳", subtitle: "見つけた言葉を、くり返し覚えよう。")
                Picker("表示方法", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
            }
            .frame(maxWidth: SnaptaSpacing.maxContentWidth)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, SnaptaSpacing.screen)
            .padding(.top, SnaptaSpacing.screen)
            .padding(.bottom, SnaptaSpacing.related)

            if flow.learnedEntries.isEmpty {
                EmptyState(icon: "book.closed", text: "見つけた言葉はまだありません").padding(20)
            } else if mode == .list {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(flow.learnedEntries) { entry in
                            Button { selected = entry } label: { NotebookListRow(entry: entry) }.buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: SnaptaSpacing.maxContentWidth)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, SnaptaSpacing.screen)
                    .padding(.vertical, SnaptaSpacing.related)
                }
            } else {
                GeometryReader { proxy in
                    let imageHeight = min(max(proxy.size.height * 0.34, 180), 260)

                    VStack(spacing: SnaptaSpacing.compact) {
                        Text("\(min(cardIndex, flow.learnedEntries.count - 1) + 1) / \(flow.learnedEntries.count)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(SnaptaTheme.ink.opacity(0.5))
                            .frame(maxWidth: .infinity)

                        NotebookStudyCard(
                            entry: flow.learnedEntries[min(cardIndex, flow.learnedEntries.count - 1)],
                            imageHeight: imageHeight,
                            showsMeaning: $showsMeaning,
                            previous: { moveCard(-1) },
                            next: { moveCard(1) }
                        )

                        HStack(spacing: SnaptaSpacing.related) {
                            notebookNavigationButton("前の単語", icon: "chevron.left", action: { moveCard(-1) })
                            notebookNavigationButton("次の単語", icon: "chevron.right", action: { moveCard(1) })
                        }
                    }
                    .padding(.horizontal, SnaptaSpacing.screen)
                    .padding(.top, 4)
                    .padding(.bottom, SnaptaSpacing.compact)
                    .frame(maxWidth: SnaptaSpacing.maxContentWidth)
                    .frame(maxWidth: .infinity, maxHeight: proxy.size.height, alignment: .top)
                }
            }
        }
        .sheet(item: $selected) { entry in
            WordDetailScreen(flow: flow, entryID: entry.id, close: { selected = nil })
        }
        .onChange(of: mode) { _, _ in showsMeaning = false }
    }

    private func moveCard(_ offset: Int) {
        let count = flow.learnedEntries.count
        guard count > 0 else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            cardIndex = (cardIndex + offset + count) % count
            showsMeaning = false
        }
    }

    private func notebookNavigationButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: SnaptaSpacing.controlHeight)
                .foregroundStyle(SnaptaTheme.indigo)
                .background(SnaptaTheme.paperLight)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(SnaptaTheme.indigo.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }
}

private struct NotebookListRow: View {
    let entry: KarutaEntry
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                SnaptaTheme.moss.opacity(0.12)
                if let image = entry.image { Image(uiImage: image).resizable().scaledToFill() }
                else { Image(systemName: entry.symbol).foregroundStyle(SnaptaTheme.indigo) }
            }.frame(width: 58, height: 58).clipped().clipShape(RoundedRectangle(cornerRadius: 4))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.reading).font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SnaptaTheme.ink.opacity(0.48)).lineLimit(1).minimumScaleFactor(0.7)
                Text(entry.word).font(SnaptaTheme.mincho(25, weight: .semibold))
                    .foregroundStyle(SnaptaTheme.ink).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").foregroundStyle(SnaptaTheme.ink.opacity(0.3))
        }.padding(12).frame(maxWidth: .infinity, minHeight: 82).background(SnaptaTheme.paperLight)
            .clipShape(RoundedRectangle(cornerRadius: 5)).overlay(RoundedRectangle(cornerRadius: 5).stroke(SnaptaTheme.line))
    }
}

private struct NotebookStudyCard: View {
    let entry: KarutaEntry
    let imageHeight: CGFloat
    @Binding var showsMeaning: Bool
    let previous: () -> Void
    let next: () -> Void

    var body: some View {
        Button { withAnimation(.easeOut(duration: 0.16)) { showsMeaning.toggle() } } label: {
                VStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text(entry.reading).font(.system(size: 18, weight: .semibold)).foregroundStyle(SnaptaTheme.ink.opacity(0.5))
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Text(entry.word).font(SnaptaTheme.mincho(44, weight: .semibold)).foregroundStyle(SnaptaTheme.indigo)
                            .lineLimit(1).minimumScaleFactor(0.65)
                    }
                    .padding(.bottom, SnaptaSpacing.related)
                    ZStack {
                        Group {
                            if let image = entry.image {
                                Image(uiImage: image).resizable().scaledToFill()
                            } else {
                                ZStack {
                                    SnaptaTheme.moss.opacity(0.12)
                                    Image(systemName: entry.symbol)
                                        .font(.system(size: 58, weight: .light))
                                        .foregroundStyle(SnaptaTheme.indigo.opacity(0.65))
                                }
                            }
                        }
                        .opacity(showsMeaning ? 0 : 1)

                        Text(entry.meaningText)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(SnaptaTheme.ink)
                            .multilineTextAlignment(.center)
                            .lineSpacing(7)
                            .minimumScaleFactor(0.75)
                            .padding(SnaptaSpacing.card)
                            .opacity(showsMeaning ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text(showsMeaning ? "タップして写真を見る" : "タップして意味を見る")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(SnaptaTheme.ink.opacity(0.55))
                        .padding(.top, SnaptaSpacing.related)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, SnaptaSpacing.card)
                .padding(.vertical, SnaptaSpacing.screen)
                .frame(maxWidth: .infinity)
                    .background(SnaptaTheme.paperLight).clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(SnaptaTheme.line))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: SnaptaSpacing.maxContentWidth)
            .gesture(DragGesture(minimumDistance: 28).onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                value.translation.width < 0 ? next() : previous()
            })
    }
}

private struct WordDetailScreen: View {
    @ObservedObject var flow: LearningFlow
    let entryID: UUID
    let close: () -> Void
    @State private var editing = false
    @State private var confirmsDelete = false

    private var entry: KarutaEntry? { flow.entries.first(where: { $0.id == entryID }) }

    var body: some View {
        NavigationStack {
            JapaneseBackground {
                ScrollView {
                    if let entry { PaperPanel { NotebookDetailContent(entry: entry) }.padding(20) }
                }
            }
            .navigationTitle("ことばの記録").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: close) { Image(systemName: "xmark") }.accessibilityLabel("閉じる")
                }
                ToolbarItem(placement: .topBarTrailing) { Button("編集") { editing = true } }
            }
            .sheet(isPresented: $editing) {
                if let entry {
                    EditWordRecordScreen(flow: flow, entry: entry, close: { editing = false }, delete: {
                        editing = false
                        close()
                    })
                }
            }
        }
    }
}

private struct NotebookDetailContent: View {
    let entry: KarutaEntry

    var body: some View {
        VStack(spacing: 24) {
            Text(entry.word)
                .font(SnaptaTheme.mincho(46, weight: .semibold))
                .foregroundStyle(SnaptaTheme.indigo)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .accessibilityLabel("\(entry.word)の写真")
            }

            Text(entry.meaningText)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(SnaptaTheme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct EditWordRecordScreen: View {
    @ObservedObject var flow: LearningFlow
    let entry: KarutaEntry
    let close: () -> Void
    let delete: () -> Void
    @State private var word: String
    @State private var reading: String
    @State private var meaning: String
    @State private var image: UIImage?
    @State private var pickerSource: PickerSource?
    @State private var confirmsDelete = false

    init(flow: LearningFlow, entry: KarutaEntry, close: @escaping () -> Void, delete: @escaping () -> Void) {
        self.flow = flow; self.entry = entry; self.close = close; self.delete = delete
        _word = State(initialValue: entry.word); _reading = State(initialValue: entry.reading)
        _meaning = State(initialValue: entry.meaningText); _image = State(initialValue: entry.image)
    }

    private var canSave: Bool {
        !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !reading.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            JapaneseBackground {
                ScrollView {
                    VStack(spacing: 16) {
                        LabeledField(label: "言葉", placeholder: "言葉", text: $word)
                        LabeledField(label: "ふりがな", placeholder: "ふりがな", text: $reading)
                        LabeledField(label: "自分で入力した意味", placeholder: "意味", text: $meaning)
                        if let image {
                            Image(uiImage: image).resizable().scaledToFill().frame(height: 210).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        Button { pickerSource = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .library } label: {
                            Label("写真を変更", systemImage: "camera.fill").frame(maxWidth: .infinity).frame(height: 46)
                        }
                        PrimaryButton("保存") {
                            flow.updateEntry(id: entry.id, word: word, reading: reading, meaning: meaning, image: image)
                            close()
                        }.disabled(!canSave).opacity(canSave ? 1 : 0.4)
                        Button("この記録を削除", role: .destructive) { confirmsDelete = true }
                            .font(.system(size: 14, weight: .medium)).padding(.top, 18).frame(minHeight: 44)
                    }.padding(20)
                }
            }
            .navigationTitle("記録を編集").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("キャンセル", action: close) } }
            .sheet(item: $pickerSource) { source in
                ImagePicker(sourceType: source.uiSource, image: $image) { _ in pickerSource = nil }
                    .ignoresSafeArea(edges: source == .camera ? .all : [])
            }
            .confirmationDialog("この言葉の記録を削除しますか？", isPresented: $confirmsDelete, titleVisibility: .visible) {
                Button("削除", role: .destructive) { flow.deleteRecord(id: entry.id); delete() }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
}

private struct InfoBlock: View {
    let title: String; let text: String
    var body: some View { VStack(alignment: .leading, spacing: 6) { Text(title).font(.system(size: 12, weight: .bold)).foregroundStyle(SnaptaTheme.moss); Text(text).font(.system(size: 16)).lineSpacing(4) }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(SnaptaTheme.paper) }
}

struct WordLibraryScreen: View {
    @ObservedObject var flow: LearningFlow
    @State private var category = "すべて"
    private let categories = ["すべて", "国語", "理科", "社会", "算数・数学", "身の回り"]
    var filtered: [KarutaEntry] { category == "すべて" ? flow.entries : flow.entries.filter { $0.categoryText == category } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenHeader(title: "言葉を見つけよう", subtitle: "これから覚えたい言葉と出会おう。")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) { ForEach(categories, id: \.self) { item in Button { category = item } label: { Text(item).font(.system(size: 13, weight: .bold)).padding(.horizontal, 14).frame(height: 38).foregroundStyle(category == item ? .white : SnaptaTheme.indigo).background(category == item ? SnaptaTheme.indigo : SnaptaTheme.paperLight).clipShape(Capsule()) } } }
                }
                ForEach(filtered) { entry in
                    PaperPanel {
                        VStack(spacing: 12) {
                            Text(entry.categoryText).font(.system(size: 11, weight: .bold)).tracking(2).foregroundStyle(SnaptaTheme.vermilion)
                            Text(entry.reading).font(.system(size: 12, weight: .medium)).foregroundStyle(SnaptaTheme.ink.opacity(0.48))
                                .lineLimit(1).minimumScaleFactor(0.7)
                            Text(entry.word).font(SnaptaTheme.mincho(29, weight: .semibold))
                            Text(entry.meaningText).font(.system(size: 14)).foregroundStyle(SnaptaTheme.ink.opacity(0.6)).multilineTextAlignment(.center)
                            Button { flow.select(entry); flow.go(.camera) } label: { Text("この言葉を探す").font(.system(size: 14, weight: .bold)).frame(maxWidth: .infinity).frame(height: 44).foregroundStyle(SnaptaTheme.indigo).overlay(RoundedRectangle(cornerRadius: 7).stroke(SnaptaTheme.indigo.opacity(0.4))) }
                        }
                    }
                }
            }.padding(20)
        }
    }
}

struct AddWordFlowScreen: View {
    @ObservedObject var flow: LearningFlow
    let cancel: () -> Void
    let didAdd: () -> Void
    @State private var step = 1
    @State private var word = ""
    @State private var reading = ""
    @State private var meaning = ""
    @State private var image: UIImage?
    @State private var pickerSource: PickerSource?
    @State private var isSaving = false
    @FocusState private var inputFocused: Bool

    private var canContinue: Bool {
        step == 1
            ? !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !reading.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            : !meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("閉じる", action: cancel)
                Spacer()
                Text("\(step) / 4").font(.subheadline.weight(.bold))
            }.padding(20)
            ScrollView {
                PaperPanel {
                    VStack(spacing: 20) {
                        Text(stepTitle)
                            .font(SnaptaTheme.mincho(26, weight: .semibold))
                            .foregroundStyle(SnaptaTheme.indigo)
                            .multilineTextAlignment(.center)
                        if step < 4 {
                            Text(stepDescription).font(.subheadline)
                                .foregroundStyle(SnaptaTheme.ink.opacity(0.65))
                                .multilineTextAlignment(.center)
                        }
                        if step == 1 {
                            TextField("言葉を入力", text: $word)
                                .font(.title2).padding().background(SnaptaTheme.paper)
                                .focused($inputFocused)
                                .accessibilityLabel("言葉を入力")
                            TextField("ふりがなを入力", text: $reading)
                                .font(.body).padding().background(SnaptaTheme.paper)
                                .accessibilityLabel("ふりがなを入力")
                        } else if step == 2 {
                            Text(word).font(SnaptaTheme.mincho(30, weight: .semibold))
                                .multilineTextAlignment(.center)
                            TextField("意味を入力", text: $meaning, axis: .vertical)
                                .lineLimit(3...5).padding().background(SnaptaTheme.paper)
                                .focused($inputFocused)
                                .submitLabel(.done)
                                .onSubmit { dismissInputKeyboard() }
                                .accessibilityLabel("意味を入力")
                        } else {
                            if let image {
                                Image(uiImage: image).resizable().scaledToFit()
                                    .frame(maxHeight: 280)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .accessibilityLabel("撮った写真")
                            }
                            if step == 3 {
                                if image == nil {
                                    PrimaryButton("カメラで撮る", icon: "camera.fill", action: openCamera)
                                    Button("写真を選ぶ") { pickerSource = .library }
                                        .frame(minHeight: 44)
                                } else {
                                    PrimaryButton("この写真にする") { step = 4 }
                                    Button("撮り直す", action: openCamera).frame(minHeight: 44)
                                }
                            } else {
                                Text(word).font(SnaptaTheme.mincho(30, weight: .semibold))
                                    .multilineTextAlignment(.center)
                                Text(meaning).font(.body).lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                PrimaryButton("カルタに追加！", icon: "plus") {
                                    guard let image, !isSaving else { return }
                                    isSaving = true
                                    // Reuse the existing storage and timestamp (learnedAt).
                                    flow.addEntry(word: word, reading: reading, imageTitle: word, meaning: meaning, image: image)
                                    didAdd()
                                }.disabled(image == nil || isSaving)
                            }
                        }
                        if step < 3 {
                            PrimaryButton(step == 1 ? "意味を調べる →" : "写真を撮る →") {
                                inputFocused = false
                                word = word.trimmingCharacters(in: .whitespacesAndNewlines)
                                reading = reading.trimmingCharacters(in: .whitespacesAndNewlines)
                                meaning = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
                                step += 1
                            }.disabled(!canContinue).opacity(canContinue ? 1 : 0.4)
                        }
                    }
                }.padding(20)
            }
        }
        .sheet(item: $pickerSource) { source in
            ImagePicker(sourceType: source.uiSource, image: $image) { _ in
                pickerSource = nil
            }
            .ignoresSafeArea(edges: source == .camera ? .all : [])
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("閉じる") { dismissInputKeyboard() }
            }
        }
    }

    private func dismissInputKeyboard() {
        meaning = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        inputFocused = false
    }

    private func openCamera() {
        pickerSource = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .library
    }

    private var stepTitle: String {
        switch step {
        case 1: "気になる言葉を探してみよう"
        case 2: "どんな意味かな？"
        case 3: "言葉に合う写真を撮ろう！"
        default: "カルタに追加"
        }
    }

    private var stepDescription: String {
        switch step {
        case 1: "身の回りで見つけた言葉を入力してね。"
        case 2: "意味を調べて、自分の言葉で書いてみよう。"
        default: "見つけたものを写真に残してみよう。"
        }
    }
}

struct EmptyState: View {
    let icon: String; let text: String
    var body: some View { VStack(spacing: 14) { Image(systemName: icon).font(.system(size: 42)).foregroundStyle(SnaptaTheme.indigo.opacity(0.5)); Text(text).font(.system(size: 15, weight: .medium)).foregroundStyle(SnaptaTheme.ink.opacity(0.55)) }.frame(maxWidth: .infinity).padding(.vertical, 70).background(SnaptaTheme.paperLight).clipShape(RoundedRectangle(cornerRadius: 7)) }
}

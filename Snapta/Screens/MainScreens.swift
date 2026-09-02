import SwiftUI

struct ScreenHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(SnaptaTheme.mincho(28, weight: .semibold)).foregroundStyle(SnaptaTheme.ink)
            Text(subtitle).font(.system(size: 14, weight: .medium)).foregroundStyle(SnaptaTheme.ink.opacity(0.58))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeTabScreen: View {
    @ObservedObject var flow: LearningFlow
    let openKaruta: () -> Void
    let openNotebook: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                ScreenHeader(title: "Snapta", subtitle: "今日は、どんな言葉を見つける？")
                PaperPanel {
                    VStack(spacing: 18) {
                        Text("今日のことば").font(.system(size: 12, weight: .bold)).tracking(2).foregroundStyle(SnaptaTheme.vermilion)
                        Text(flow.word).font(SnaptaTheme.mincho(46, weight: .semibold)).tracking(6)
                        Text(flow.currentEntry.meaningText).font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SnaptaTheme.ink.opacity(0.65)).multilineTextAlignment(.center).lineSpacing(4)
                        Text("身の回りから「\(flow.word)」を探してみよう。")
                            .font(.system(size: 15, weight: .bold)).multilineTextAlignment(.center)
                        PrimaryButton("探しに行く", icon: "camera.fill") { flow.go(.camera) }
                    }
                }
                PaperPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("カルタで復習").font(SnaptaTheme.mincho(20, weight: .semibold))
                                Text("覚えた言葉、まだ覚えてる？").font(.system(size: 13)).foregroundStyle(SnaptaTheme.ink.opacity(0.55))
                            }
                            Spacer()
                            Text("\(flow.learnedEntries.count)枚").font(.system(size: 14, weight: .bold)).foregroundStyle(SnaptaTheme.indigo)
                        }
                        Button(action: openKaruta) {
                            Label("カルタを始める", systemImage: "rectangle.stack.fill")
                                .font(.system(size: 15, weight: .bold)).frame(maxWidth: .infinity).frame(height: 46)
                                .foregroundStyle(SnaptaTheme.indigo).overlay(RoundedRectangle(cornerRadius: 7).stroke(SnaptaTheme.indigo.opacity(0.4)))
                        }.disabled(flow.learnedEntries.isEmpty).opacity(flow.learnedEntries.isEmpty ? 0.4 : 1)
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    HStack { Text("最近のことば").font(SnaptaTheme.mincho(19, weight: .semibold)); Spacer(); Button("すべて見る", action: openNotebook).font(.system(size: 13, weight: .bold)) }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(flow.entries.reversed().prefix(5))) { entry in
                                Button { flow.select(entry) } label: {
                                    Text(entry.word).font(SnaptaTheme.mincho(17, weight: .semibold)).foregroundStyle(SnaptaTheme.ink)
                                        .frame(width: 94, height: 68).background(SnaptaTheme.paperLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 5)).overlay(RoundedRectangle(cornerRadius: 5).stroke(SnaptaTheme.line))
                                }
                            }
                        }
                    }
                }
            }.padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 24)
        }
    }
}

struct KarutaLandingScreen: View {
    @ObservedObject var flow: LearningFlow
    let start: () -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                ScreenHeader(title: "カルタ", subtitle: "撮った写真で、言葉を思い出そう。")
                PaperPanel {
                    VStack(spacing: 18) {
                        Image(systemName: "rectangle.stack.fill").font(.system(size: 42)).foregroundStyle(SnaptaTheme.indigo)
                        Text("今日の復習").font(SnaptaTheme.mincho(23, weight: .semibold))
                        Text(flow.learnedEntries.isEmpty ? "まずは言葉を探して、写真の札を作ろう。" : "\(flow.learnedEntries.count)枚の写真札で遊べます。")
                            .font(.system(size: 15)).foregroundStyle(SnaptaTheme.ink.opacity(0.6)).multilineTextAlignment(.center)
                        PrimaryButton("カルタを始める", icon: "play.fill", action: start)
                            .disabled(flow.learnedEntries.isEmpty).opacity(flow.learnedEntries.isEmpty ? 0.4 : 1)
                    }
                }
                ForEach([("最近覚えた言葉", "clock"), ("すべての言葉", "square.grid.2x2")], id: \.0) { option in
                    Button(action: start) {
                        HStack { Image(systemName: option.1); Text(option.0).font(.system(size: 16, weight: .bold)); Spacer(); Image(systemName: "chevron.right") }
                            .foregroundStyle(SnaptaTheme.ink).padding(18).background(SnaptaTheme.paperLight)
                            .clipShape(RoundedRectangle(cornerRadius: 7)).overlay(RoundedRectangle(cornerRadius: 7).stroke(SnaptaTheme.line))
                    }.disabled(flow.learnedEntries.isEmpty)
                }
            }.padding(20)
        }
    }
}

struct NotebookScreen: View {
    @ObservedObject var flow: LearningFlow
    @State private var selected: KarutaEntry?
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScreenHeader(title: "わたしの単語帳", subtitle: "見つけた言葉を、振り返ろう。")
                if flow.learnedEntries.isEmpty {
                    EmptyState(icon: "book.closed", text: "見つけた言葉はまだありません")
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(flow.learnedEntries) { entry in
                            Button { selected = entry } label: { NotebookCard(entry: entry) }.buttonStyle(.plain)
                        }
                    }
                }
            }.padding(20)
        }
        .sheet(item: $selected) { entry in
            WordDetailScreen(entry: entry) {
                flow.select(entry)
                selected = nil
                flow.go(.camera)
            }
        }
    }
}

private struct NotebookCard: View {
    let entry: KarutaEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                SnaptaTheme.moss.opacity(0.12)
                if let image = entry.image { Image(uiImage: image).resizable().scaledToFill() }
                else { Image(systemName: entry.symbol).font(.system(size: 34)).foregroundStyle(SnaptaTheme.indigo) }
            }.frame(height: 125).clipped()
            Text(entry.word).font(SnaptaTheme.mincho(21, weight: .semibold)).foregroundStyle(SnaptaTheme.ink)
            Text(entry.meaningText).font(.system(size: 12)).foregroundStyle(SnaptaTheme.ink.opacity(0.58)).lineLimit(2)
            if let date = entry.learnedAt { Text(date.formatted(date: .numeric, time: .omitted)).font(.system(size: 10)).foregroundStyle(SnaptaTheme.ink.opacity(0.4)) }
        }.padding(10).background(SnaptaTheme.paperLight).clipShape(RoundedRectangle(cornerRadius: 6)).overlay(RoundedRectangle(cornerRadius: 6).stroke(SnaptaTheme.line))
    }
}

private struct WordDetailScreen: View {
    let entry: KarutaEntry
    let retry: () -> Void
    var body: some View {
        NavigationStack {
            JapaneseBackground {
                ScrollView {
                    PaperPanel {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(entry.word).font(SnaptaTheme.mincho(36, weight: .semibold)).frame(maxWidth: .infinity)
                            if let image = entry.image { Image(uiImage: image).resizable().scaledToFill().frame(height: 250).clipped().clipShape(RoundedRectangle(cornerRadius: 5)) }
                            InfoBlock(title: "意味", text: entry.meaningText)
                            InfoBlock(title: "なぜこの写真を撮った？", text: entry.note.flatMap { $0.isEmpty ? nil : $0 } ?? "まだ説明はありません。")
                            PrimaryButton("もう一度探す", icon: "camera.fill", action: retry)
                        }
                    }.padding(20)
                }
            }.navigationTitle("ことばの記録").navigationBarTitleDisplayMode(.inline)
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
    let startCamera: () -> Void
    @State private var step = 1
    @State private var word = ""
    @State private var reading = ""
    @State private var meaning = ""
    @State private var category = "身の回り"

    var body: some View {
        VStack(spacing: 0) {
            HStack { Button("閉じる", action: cancel); Spacer(); Text("\(step) / 3").font(.system(size: 13, weight: .bold)) }.padding(20)
            ProgressView(value: Double(step), total: 3).tint(SnaptaTheme.indigo).padding(.horizontal, 20)
            Spacer()
            PaperPanel {
                VStack(spacing: 20) {
                    Text(stepTitle).font(SnaptaTheme.mincho(26, weight: .semibold)).multilineTextAlignment(.center)
                    if step == 1 {
                        TextField("例：屈折", text: $word).font(SnaptaTheme.mincho(28)).multilineTextAlignment(.center).padding().background(SnaptaTheme.paper)
                        TextField("よみかた", text: $reading).padding().background(SnaptaTheme.paper)
                    } else if step == 2 {
                        TextField("短く、わかりやすい意味", text: $meaning, axis: .vertical).lineLimit(3...5).padding().background(SnaptaTheme.paper)
                        Picker("カテゴリ", selection: $category) { ForEach(["国語", "理科", "社会", "算数・数学", "身の回り"], id: \.self) { Text($0) } }.pickerStyle(.menu)
                    } else {
                        Text("身の回りから「\(word)」を探してみよう。").font(.system(size: 17, weight: .bold)).multilineTextAlignment(.center)
                        Image(systemName: "camera.viewfinder").font(.system(size: 64, weight: .light)).foregroundStyle(SnaptaTheme.indigo)
                    }
                    PrimaryButton(step == 3 ? "カメラを開く" : "次へ", icon: step == 3 ? "camera.fill" : "arrow.right") {
                        if step < 3 { withAnimation { step += 1 } }
                        else { flow.addWord(word: word, reading: reading, meaning: meaning, category: category); startCamera() }
                    }.disabled(step == 1 && word.trimmingCharacters(in: .whitespaces).isEmpty).opacity(step == 1 && word.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                }
            }.padding(20)
            Spacer(); Spacer()
        }
    }
    private var stepTitle: String { step == 1 ? "言葉を入力" : step == 2 ? "意味をつけよう" : "探してみよう" }
}

struct EmptyState: View {
    let icon: String; let text: String
    var body: some View { VStack(spacing: 14) { Image(systemName: icon).font(.system(size: 42)).foregroundStyle(SnaptaTheme.indigo.opacity(0.5)); Text(text).font(.system(size: 15, weight: .medium)).foregroundStyle(SnaptaTheme.ink.opacity(0.55)) }.frame(maxWidth: .infinity).padding(.vertical, 70).background(SnaptaTheme.paperLight).clipShape(RoundedRectangle(cornerRadius: 7)) }
}

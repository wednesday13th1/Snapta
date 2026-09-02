import SwiftUI

private enum AppTab: String, CaseIterable {
    case home = "ホーム"
    case karuta = "カルタ"
    case add = "追加"
    case notebook = "単語帳"
    case words = "言葉"

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .karuta: "rectangle.stack.fill"
        case .add: "plus"
        case .notebook: "book.closed.fill"
        case .words: "text.book.closed.fill"
        }
    }
}

struct ContentView: View {
    @StateObject private var flow = LearningFlow()
    @State private var selectedTab: AppTab = .home
    @State private var showAddFlow = false

    var body: some View {
        JapaneseBackground {
            if flow.step == .today {
                tabContent
                    .safeAreaInset(edge: .bottom, spacing: 0) { BottomNavigation(selected: $selectedTab, showAdd: $showAddFlow) }
            } else {
                learningFlow
            }
        }
        .tint(SnaptaTheme.indigo)
        .fullScreenCover(isPresented: $showAddFlow) {
            JapaneseBackground {
                AddWordFlowScreen(flow: flow, cancel: { showAddFlow = false }) {
                    showAddFlow = false
                    flow.go(.camera)
                }
            }.tint(SnaptaTheme.indigo)
        }
    }

    @ViewBuilder private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeTabScreen(flow: flow, openKaruta: startKaruta, openNotebook: { selectedTab = .notebook })
        case .karuta:
            KarutaLandingScreen(flow: flow, start: startKaruta)
        case .add:
            Color.clear.onAppear { showAddFlow = true; selectedTab = .home }
        case .notebook:
            NotebookScreen(flow: flow)
        case .words:
            WordLibraryScreen(flow: flow)
        }
    }

    private var learningFlow: some View {
        VStack(spacing: 0) {
            FlowHeader(title: flow.step == .camera ? "探して撮る" : flow.step == .quiz ? "ことばかるた" : "ことばの記録") {
                flow.reset()
            }
            Group {
                switch flow.step {
                case .today: EmptyView()
                case .camera: CameraScreen(flow: flow)
                case .saved: SavedScreen(flow: flow)
                case .quiz: QuizScreen(flow: flow)
                case .flashcards: FlashcardScreen(flow: flow)
                }
            }
            .id(flow.step)
            .transition(.opacity.combined(with: .offset(y: 8)))
        }
    }

    private func startKaruta() {
        guard let first = flow.learnedEntries.first else { return }
        flow.select(first)
        flow.go(.quiz)
    }
}

private struct FlowHeader: View {
    let title: String
    let close: () -> Void
    var body: some View {
        HStack {
            Button(action: close) { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("閉じる")
            Spacer()
            Text(title).font(SnaptaTheme.mincho(20, weight: .semibold)).foregroundStyle(SnaptaTheme.indigo)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }.padding(.horizontal, 10).background(SnaptaTheme.paper.opacity(0.94))
    }
}

private struct BottomNavigation: View {
    @Binding var selected: AppTab
    @Binding var showAdd: Bool
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            tab(.home)
            tab(.karuta)
            Button { showAdd = true } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle().fill(SnaptaTheme.indigo).frame(width: 48, height: 48)
                        Image(systemName: "plus").font(.system(size: 21, weight: .bold)).foregroundStyle(.white)
                    }
                    Text("追加").font(.system(size: 10, weight: .bold)).foregroundStyle(SnaptaTheme.indigo)
                }.frame(maxWidth: .infinity)
            }.accessibilityLabel("新しい言葉を追加")
            tab(.notebook)
            tab(.words)
        }
        .padding(.top, 8)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Rectangle().fill(SnaptaTheme.line).frame(height: 1) }
    }

    private func tab(_ tab: AppTab) -> some View {
        Button { selected = tab } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon).font(.system(size: 18, weight: .medium)).frame(height: 25)
                Text(tab.rawValue).font(.system(size: 10, weight: selected == tab ? .bold : .medium))
            }.foregroundStyle(selected == tab ? SnaptaTheme.indigo : SnaptaTheme.ink.opacity(0.42)).frame(maxWidth: .infinity)
        }.accessibilityLabel(tab.rawValue).accessibilityAddTraits(selected == tab ? .isSelected : [])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView().previewDisplayName("Snapta") }
}

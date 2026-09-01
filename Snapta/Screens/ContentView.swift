import SwiftUI

struct ContentView: View {
    @StateObject private var flow = LearningFlow()

    var body: some View {
        JapaneseBackground {
            VStack(spacing: 0) {
                AppHeader(onClose: flow.step == .today ? nil : { flow.reset() })
                ProgressThread(step: flow.step)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 14)

                Group {
                    switch flow.step {
                    case .today: TodayWordScreen(flow: flow)
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
        .tint(SnaptaTheme.indigo)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("Snapta・今日のことば")
    }
}

private struct AppHeader: View {
    let onClose: (() -> Void)?

    var body: some View {
        HStack {
            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                        .frame(width: 42, height: 42)
                }
                .accessibilityLabel("はじめにもどる")
            } else {
                Color.clear.frame(width: 42, height: 42)
            }
            Spacer()
            Text("Snapta")
                .font(SnaptaTheme.mincho(22, weight: .semibold))
                .tracking(2)
                .foregroundStyle(SnaptaTheme.indigo)
            Spacer()
            Button(action: {}) {
                Image(systemName: "questionmark").font(.system(size: 15, weight: .semibold))
                    .frame(width: 42, height: 42)
            }
            .accessibilityLabel("ヘルプ")
        }
        .foregroundStyle(SnaptaTheme.ink)
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }
}

private struct ProgressThread: View {
    let step: LearningStep
    private let stages = ["探す", "写真", "かるた"]

    var activeIndex: Int {
        switch step {
        case .today: 0
        case .camera: 1
        case .saved, .quiz, .flashcards: 2
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(stages.indices, id: \.self) { index in
                if index > 0 {
                    Rectangle()
                        .fill(index <= activeIndex ? SnaptaTheme.indigo : SnaptaTheme.line)
                        .frame(height: 1)
                }
                VStack(spacing: 4) {
                    Circle()
                        .fill(index <= activeIndex ? SnaptaTheme.indigo : SnaptaTheme.paperLight)
                        .overlay(Circle().stroke(SnaptaTheme.indigo.opacity(0.35), lineWidth: 1))
                        .frame(width: 8, height: 8)
                    Text(stages[index])
                        .font(.system(size: 10, weight: index == activeIndex ? .bold : .regular))
                        .foregroundStyle(index <= activeIndex ? SnaptaTheme.indigo : SnaptaTheme.ink.opacity(0.4))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("学習の進み具合、\(stages[activeIndex])")
    }
}

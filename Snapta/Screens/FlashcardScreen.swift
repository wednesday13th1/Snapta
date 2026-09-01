import SwiftUI

struct FlashcardScreen: View {
    @ObservedObject var flow: LearningFlow
    @State private var page = 0
    @State private var showBack = false
    @State private var turnDirection: CGFloat = 1

    private var entry: KarutaEntry { flow.entries[min(page, flow.entries.count - 1)] }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("ことばの単語帳").font(SnaptaTheme.mincho(24, weight: .semibold))
                Spacer()
                Text("\(page + 1) / \(flow.entries.count)")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(SnaptaTheme.ink.opacity(0.5))
            }.padding(.horizontal, 24)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8).fill(SnaptaTheme.ink.opacity(0.08)).offset(x: 7, y: 5)
                RoundedRectangle(cornerRadius: 8).fill(SnaptaTheme.paperLight)
                Rectangle().fill(SnaptaTheme.vermilion.opacity(0.65)).frame(width: 3).padding(.vertical, 18)

                Group {
                    if showBack { backPage } else { frontPage }
                }
                .id("\(entry.id)-\(showBack)")
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .modifier(active: PageTurn(angle: -70 * turnDirection), identity: PageTurn(angle: 0))),
                    removal: .opacity.combined(with: .modifier(active: PageTurn(angle: 70 * turnDirection), identity: PageTurn(angle: 0)))
                ))
                .padding(30)
            }
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(SnaptaTheme.line))
            .shadow(color: SnaptaTheme.ink.opacity(0.1), radius: 14, y: 7)
            .padding(.horizontal, 22)
            .frame(maxHeight: 500)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.easeInOut(duration: 0.4)) { showBack.toggle() } }
            .gesture(DragGesture(minimumDistance: 30).onEnded { value in
                if value.translation.width < -40 { changePage(by: 1) }
                if value.translation.width > 40 { changePage(by: -1) }
            })

            HStack(spacing: 30) {
                Button { changePage(by: -1) } label: { Image(systemName: "chevron.left").frame(width: 48, height: 48) }
                    .disabled(page == 0).opacity(page == 0 ? 0.3 : 1)
                Text(showBack ? "タップでことばへ" : "タップで答えを見る")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(SnaptaTheme.ink.opacity(0.55))
                Button { changePage(by: 1) } label: { Image(systemName: "chevron.right").frame(width: 48, height: 48) }
                    .disabled(page == flow.entries.count - 1).opacity(page == flow.entries.count - 1 ? 0.3 : 1)
            }.foregroundStyle(SnaptaTheme.indigo)
            Spacer(minLength: 15)
        }
    }

    private var frontPage: some View {
        VStack(spacing: 20) {
            Text("ことば").font(.system(size: 12, weight: .bold)).tracking(3).foregroundStyle(SnaptaTheme.vermilion)
            Spacer()
            Text(entry.word).font(SnaptaTheme.mincho(48, weight: .semibold)).tracking(6)
            Text(entry.reading).font(.system(size: 14, weight: .medium)).tracking(3).foregroundStyle(SnaptaTheme.ink.opacity(0.5))
            Spacer()
            Image(systemName: "hand.tap").foregroundStyle(SnaptaTheme.indigo.opacity(0.45))
        }.frame(maxWidth: .infinity)
    }

    private var backPage: some View {
        VStack(spacing: 18) {
            Text(entry.word).font(SnaptaTheme.mincho(25, weight: .semibold))
            ZStack {
                RoundedRectangle(cornerRadius: 5).fill(SnaptaTheme.moss.opacity(0.13))
                if let image = entry.image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Image(systemName: entry.symbol).font(.system(size: 55, weight: .light)).foregroundStyle(SnaptaTheme.indigo.opacity(0.7))
                }
            }.frame(height: 190).clipped().clipShape(RoundedRectangle(cornerRadius: 5))
            Text(entry.meaningText).font(.system(size: 17, weight: .medium)).multilineTextAlignment(.center).lineSpacing(6)
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity)
    }

    private func changePage(by amount: Int) {
        let next = page + amount
        guard flow.entries.indices.contains(next) else { return }
        turnDirection = amount > 0 ? 1 : -1
        withAnimation(.easeInOut(duration: 0.45)) { page = next; showBack = false }
    }
}

private struct PageTurn: ViewModifier {
    let angle: CGFloat
    func body(content: Content) -> some View {
        content.rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), anchor: angle > 0 ? .trailing : .leading, perspective: 0.45)
    }
}

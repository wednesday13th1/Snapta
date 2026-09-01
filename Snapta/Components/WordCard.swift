import SwiftUI

struct WordCard: View {
    let word: String
    var reading: String = ""
    var compact = false

    var body: some View {
        VStack(spacing: compact ? 9 : 16) {
            HStack(spacing: 6) {
                Rectangle().fill(SnaptaTheme.vermilion).frame(width: 18, height: 2)
                Text("今日のことば")
                    .font(SnaptaTheme.mincho(compact ? 11 : 13, weight: .semibold))
                    .tracking(2)
                Rectangle().fill(SnaptaTheme.vermilion).frame(width: 18, height: 2)
            }
            .foregroundStyle(SnaptaTheme.ink.opacity(0.66))

            Text(word)
                .font(SnaptaTheme.mincho(compact ? 28 : 46, weight: .semibold))
                .tracking(compact ? 3 : 7)
                .foregroundStyle(SnaptaTheme.ink)

            if !compact {
                Text(reading)
                    .font(.system(size: 13, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(SnaptaTheme.ink.opacity(0.5))
            }
        }
        .frame(width: compact ? 132 : 210, height: compact ? 108 : 270)
        .background(SnaptaTheme.paperLight)
        .overlay(alignment: .topTrailing) {
            DiamondMark()
                .fill(SnaptaTheme.moss.opacity(0.7))
                .frame(width: compact ? 18 : 24, height: compact ? 18 : 24)
                .padding(compact ? 8 : 12)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(SnaptaTheme.ink.opacity(0.2), lineWidth: 1)
                .padding(5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .shadow(color: SnaptaTheme.ink.opacity(0.1), radius: 9, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日のことば、\(word)")
    }
}

struct DiamondMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

import SwiftUI

enum SnaptaTheme {
    static let paper = Color(red: 247 / 255, green: 244 / 255, blue: 237 / 255)
    static let paperLight = Color(red: 253 / 255, green: 252 / 255, blue: 248 / 255)
    static let ink = Color(red: 43 / 255, green: 41 / 255, blue: 38 / 255)
    static let indigo = Color(red: 41 / 255, green: 70 / 255, blue: 91 / 255)
    static let vermilion = Color(red: 185 / 255, green: 74 / 255, blue: 61 / 255)
    static let moss = Color(red: 115 / 255, green: 128 / 255, blue: 91 / 255)
    static let line = ink.opacity(0.13)

    static func mincho(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct SeigaihaPattern: View {
    var color: Color = SnaptaTheme.indigo.opacity(0.055)

    var body: some View {
        Canvas { context, size in
            let radius: CGFloat = 25
            for row in -1...Int(size.height / radius) + 1 {
                let y = CGFloat(row) * radius * 0.72
                let offset = row.isMultiple(of: 2) ? 0.0 : radius
                for column in -1...Int(size.width / (radius * 2)) + 1 {
                    let x = CGFloat(column) * radius * 2 + offset
                    for scale in [1.0, 0.7, 0.4] {
                        let r = radius * scale
                        var path = Path()
                        path.addArc(
                            center: CGPoint(x: x, y: y),
                            radius: r,
                            startAngle: .degrees(180),
                            endAngle: .degrees(360),
                            clockwise: false
                        )
                        context.stroke(path, with: .color(color), lineWidth: 0.75)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct JapaneseBackground<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            SnaptaTheme.paper.ignoresSafeArea()
            SeigaihaPattern().ignoresSafeArea()
            content
        }
    }
}

struct PaperPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(SnaptaTheme.paperLight)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(SnaptaTheme.line, lineWidth: 1)
            }
            .shadow(color: SnaptaTheme.ink.opacity(0.07), radius: 14, y: 6)
    }
}

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.system(size: 17, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(.white)
            .background(SnaptaTheme.indigo)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(LiftButtonStyle())
    }
}

struct LiftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .offset(y: configuration.isPressed ? -1 : 0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

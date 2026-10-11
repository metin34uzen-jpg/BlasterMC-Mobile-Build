import SwiftUI
import UIKit

// V10: immersive but readable presentation primitives. Nothing here invents player data.
enum V10 {
    static let ink = BlasterTheme.navy
    static let gold = BlasterTheme.gold
    static let bright = BlasterTheme.amber
    static let line = BlasterTheme.gold.opacity(0.16)
    static let soft = Color(red: 0.984, green: 0.973, blue: 0.948)

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func copy(_ value: String) {
        UIPasteboard.general.string = value
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct V10Heading: View {
    let eyebrow: String
    let title: String
    var detail: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(2.1)
                .foregroundStyle(V10.gold)
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .tracking(-0.65)
                    .foregroundStyle(BlasterTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 1)
            }
            if !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(BlasterTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct V10Plate<Content: View>: View {
    var dark: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .fill(dark ?
                          LinearGradient(colors: [V10.ink, Color(red: 0.19, green: 0.26, blue: 0.39)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [.white, V10.soft],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(dark ? V10.bright.opacity(0.26) : V10.line, lineWidth: 1)
            }
            .shadow(color: V10.ink.opacity(dark ? 0.15 : 0.07), radius: 15, y: 7)
    }
}

struct V10Tag: View {
    let text: String
    let symbol: String
    var dark: Bool = false

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .foregroundStyle(dark ? BlasterTheme.cream : V10.ink)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(dark ? .white.opacity(0.10) : V10.gold.opacity(0.10),
                        in: Capsule())
            .overlay(Capsule().strokeBorder(V10.bright.opacity(dark ? 0.27 : 0.15)))
    }
}

struct V10SparkField: View {
    @State private var shift = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { g in
            ZStack {
                ForEach(0..<20, id: \.self) { idx in
                    let x = CGFloat((idx * 73 + 29) % 97) / 100 * g.size.width
                    let y = CGFloat((idx * 47 + 11) % 97) / 100 * g.size.height
                    Image(systemName: idx.isMultiple(of: 3) ? "sparkle" : "plus")
                        .font(.system(size: CGFloat(6 + idx % 4 * 3), weight: .ultraLight))
                        .foregroundStyle(V10.bright.opacity(idx.isMultiple(of: 3) ? 0.52 : 0.24))
                        .position(x: x + (shift ? 5 : -5), y: y + (shift ? -8 : 7))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                shift = true
            }
        }
    }
}

struct V10Divider: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [V10.gold.opacity(0.4), V10.gold.opacity(0.02)],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(height: 1)
    }
}

struct V10SquareAction: View {
    let title: String
    let detail: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button {
            V10.tap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(V10.gold)
                    .frame(width: 47, height: 47)
                    .background(V10.gold.opacity(0.11),
                                in: RoundedRectangle(cornerRadius: 14))
                Spacer(minLength: 1)
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(V10.ink)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(BlasterTheme.muted)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 125, alignment: .leading)
            .padding(15)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20)
                .strokeBorder(V10.line, lineWidth: 1))
        }
        .buttonStyle(BlasterTapStyle())
    }
}

struct V10ProgressBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            Capsule().fill(V10.ink.opacity(0.09))
                .overlay(alignment: .leading) {
                    Capsule().fill(LinearGradient(
                        colors: [V10.gold, V10.bright],
                        startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * min(1, max(0, progress)))
                }
        }
        .frame(height: 7)
        .accessibilityValue("\(Int(min(1, max(0, progress)) * 100)) yüzde")
    }
}

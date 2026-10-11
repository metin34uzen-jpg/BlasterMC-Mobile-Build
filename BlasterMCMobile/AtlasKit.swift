import SwiftUI
import UIKit

// ATLAS / 11 — a fresh, fully independent component system.
// Every multi-child surface uses an explicit VStack. No fixed-height text clipping.
enum Atlas {
    static let canvas = Color(red: 0.976, green: 0.965, blue: 0.941)
    static let paper = Color(red: 1.0, green: 0.998, blue: 0.990)
    static let ink = Color(red: 0.102, green: 0.169, blue: 0.265)
    static let muted = Color(red: 0.392, green: 0.429, blue: 0.478)
    static let blue = Color(red: 0.118, green: 0.260, blue: 0.442)
    static let blueLight = Color(red: 0.902, green: 0.940, blue: 0.972)
    static let copper = Color(red: 0.737, green: 0.363, blue: 0.126)
    static let orange = Color(red: 1.0, green: 0.724, blue: 0.345)
    static let sand = Color(red: 0.992, green: 0.923, blue: 0.806)
    static let line = Color(red: 0.868, green: 0.861, blue: 0.842)
    static let danger = Color(red: 0.68, green: 0.20, blue: 0.17)
    static func haptic() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func copy(_ value: String) {
        UIPasteboard.general.string = value
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct AtlasBackground: View {
    var body: some View {
        ZStack {
            Atlas.canvas
            LinearGradient(colors: [Color.white.opacity(0.60), .clear, Atlas.blue.opacity(0.025)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .ignoresSafeArea()
    }
}

struct AtlasCard<Content: View>: View {
    var inset: CGFloat = 18
    var spacing: CGFloat = 12
    var tinted = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(inset)
        .background(tinted ? Atlas.blueLight : Atlas.paper,
                    in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 19)
            .strokeBorder(tinted ? Atlas.blue.opacity(0.11) : Atlas.line, lineWidth: 1))
    }
}

struct AtlasHeading: View {
    let kicker: String
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(kicker.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Atlas.copper)
                .fixedSize(horizontal: false, vertical: true)
            Text(title)
                .font(.system(size: 23, weight: .heavy, design: .rounded))
                .tracking(-0.7)
                .foregroundStyle(Atlas.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let detail {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Atlas.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AtlasMasthead: View {
    let label: String
    var trailingSymbol: String? = nil
    var onTrailing: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 11) {
            BlasterLogo(size: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text("BLASTERMC")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(Atlas.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(0.85)
                    .foregroundStyle(Atlas.copper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 6)
            if let trailingSymbol, let onTrailing {
                Button {
                    Atlas.haptic()
                    onTrailing()
                } label: {
                    Image(systemName: trailingSymbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Atlas.ink)
                        .frame(width: 43, height: 43)
                        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Atlas.line))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AtlasAction: View {
    let title: String
    var symbol: String = "arrow.up.right"
    var secondary = false
    let action: () -> Void

    var body: some View {
        Button {
            Atlas.haptic()
            action()
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(secondary ? Atlas.ink : Color.white)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(secondary ? Atlas.paper : Atlas.blue,
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(secondary ? Atlas.line : Atlas.blue.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }
}

struct AtlasPill: View {
    let title: String
    var symbol: String? = nil
    var highlighted = false

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 10, weight: .bold))
            }
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(highlighted ? Atlas.blue : Atlas.muted)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(highlighted ? Atlas.blueLight : Atlas.canvas, in: Capsule())
    }
}

struct AtlasEmpty: View {
    let title: String
    let detail: String
    var symbol = "tray"

    var body: some View {
        AtlasCard(tinted: true) {
            Image(systemName: symbol)
                .font(.system(size: 25, weight: .light))
                .foregroundStyle(Atlas.copper)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Atlas.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(Atlas.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct AtlasBanner<Content: View>: View {
    var eyebrow: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 9) {
                Rectangle().fill(Atlas.orange).frame(width: 19, height: 3)
                Text(eyebrow.uppercased())
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(1.15)
                    .foregroundStyle(Atlas.orange)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                AtlasPixelSignature()
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [Atlas.blue, Atlas.ink],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 22)
            .strokeBorder(Atlas.orange.opacity(0.35), lineWidth: 1))
    }
}

// Subtle block-grid mark, never placed behind content and never used as a fake island.
struct AtlasPixelSignature: View {
    private let cells: [(Int, Int)] = [(0,0),(1,0),(2,0),(1,1),(2,1),(3,1),(2,2),(3,2)]
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<cells.count, id: \.self) { index in
                Rectangle()
                    .fill(index.isMultiple(of: 3) ? Atlas.orange : Color.white.opacity(0.20))
                    .frame(width: 5, height: 5)
                    .offset(x: CGFloat(cells[index].0) * 7,
                            y: CGFloat(cells[index].1) * 7)
            }
        }
        .frame(width: 27, height: 20)
        .accessibilityHidden(true)
    }
}

struct AtlasRule: View {
    var body: some View {
        Rectangle().fill(Atlas.line).frame(height: 1)
    }
}

struct AtlasScreen<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 21) {
                content
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 32)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(AtlasBackground())
    }
}

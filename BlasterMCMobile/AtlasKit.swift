import SwiftUI
import UIKit

// BLASTER 12 / AURORA — independent, scalable visual language.
// Every card is vertically laid out, never uses a hardcoded content height.
enum Atlas {
    static let canvas = Color(red: 0.963, green: 0.961, blue: 0.953)
    static let paper = Color(red: 1.000, green: 1.000, blue: 0.995)
    static let ink = Color(red: 0.087, green: 0.130, blue: 0.225)
    static let muted = Color(red: 0.377, green: 0.414, blue: 0.479)
    static let blue = Color(red: 0.090, green: 0.265, blue: 0.667)
    static let blueLight = Color(red: 0.895, green: 0.929, blue: 1.000)
    static let copper = Color(red: 0.854, green: 0.315, blue: 0.195)
    static let orange = Color(red: 1.000, green: 0.720, blue: 0.396)
    static let sand = Color(red: 1.000, green: 0.937, blue: 0.855)
    static let line = Color(red: 0.865, green: 0.878, blue: 0.905)
    static let danger = Color(red: 0.735, green: 0.173, blue: 0.175)
    static let navy = Color(red: 0.066, green: 0.130, blue: 0.293)
    static let aqua = Color(red: 0.675, green: 0.886, blue: 0.986)
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
            LinearGradient(colors: [Color.white.opacity(0.55), .clear, Atlas.blue.opacity(0.025)],
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
                    in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 21, style: .continuous)
            .strokeBorder(tinted ? Atlas.blue.opacity(0.15) : Atlas.line.opacity(0.78), lineWidth: 1))
        .shadow(color: Atlas.navy.opacity(tinted ? 0.015 : 0.045), radius: 16, x: 0, y: 6)
    }
}

struct AtlasHeading: View {
    let kicker: String
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Atlas.copper).frame(width: 15, height: 3)
                Text(kicker.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(1.15)
                    .foregroundStyle(Atlas.copper)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .tracking(-0.8)
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
        .accessibilityElement(children: .combine)
    }
}

struct AtlasMasthead: View {
    let label: String
    var trailingSymbol: String? = nil
    var onTrailing: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Atlas.navy)
                    .frame(width: 50, height: 50)
                BlasterLogo(size: 43)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("BLASTERMC")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .tracking(-0.65)
                    .foregroundStyle(Atlas.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(Atlas.copper)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 3)
            if let trailingSymbol, let onTrailing {
                Button {
                    Atlas.haptic()
                    onTrailing()
                } label: {
                    Image(systemName: trailingSymbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Atlas.blue)
                        .frame(width: 46, height: 46)
                        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(Atlas.line))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Haberleri aç")
            }
        }
        .padding(.vertical, 2)
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
            HStack(spacing: 9) {
                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 5)
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 25, height: 25)
            }
            .foregroundStyle(secondary ? Atlas.blue : Color.white)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(secondary ? Atlas.paper : Atlas.blue,
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15)
                .strokeBorder(secondary ? Atlas.line : Atlas.blue.opacity(0.2)))
        }
        .buttonStyle(.plain)
    }
}

struct AtlasPill: View {
    let title: String
    var symbol: String? = nil
    var highlighted = false

    var body: some View {
        HStack(spacing: 6) {
            if let symbol { Image(systemName: symbol).font(.system(size: 10, weight: .bold)) }
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(highlighted ? Atlas.blue : Atlas.muted)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
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
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Atlas.blue)
                .frame(width: 49, height: 49)
                .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 15))
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
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
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(LinearGradient(colors: [Atlas.blue, Atlas.navy],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            AtlasBlockArtwork()
                .frame(width: 155, height: 155)
                .opacity(0.65)
                .padding(.top, 14)
                .padding(.trailing, 4)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2).fill(Atlas.orange)
                        .frame(width: 18, height: 3)
                    Text(eyebrow.uppercased())
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .tracking(0.95)
                        .foregroundStyle(Atlas.orange)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(21)
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(Atlas.aqua.opacity(0.20)))
    }
}

// A vector-only pixel constellation, inspired by Minecraft's square geometry.
// Unlike the removed voxel-island mockup, it never obscures content or simulates a screenshot.
struct AtlasBlockArtwork: View {
    private let blocks: [(CGFloat, CGFloat, CGFloat, Double)] = [
        (0,0,23,0.25),(27,0,23,0.15),(54,0,23,0.4),(81,0,23,0.15),
        (27,27,23,0.30),(54,27,23,0.14),(81,27,23,0.27),
        (54,54,23,0.34),(81,54,23,0.12),(108,54,23,0.35),
        (81,81,23,0.32),(108,81,23,0.17),(108,108,23,0.31)
    ]
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<blocks.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(index.isMultiple(of: 4) ? Atlas.orange.opacity(blocks[index].3) :
                          Atlas.aqua.opacity(blocks[index].3))
                    .frame(width: blocks[index].2, height: blocks[index].2)
                    .offset(x: blocks[index].0, y: blocks[index].1)
            }
        }
    }
}

struct AtlasPixelSignature: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(index == 0 ? Atlas.orange : Color.white.opacity(0.5))
                    .frame(width: 7, height: 7)
            }
        }
        .frame(height: 20)
        .accessibilityHidden(true)
    }
}

struct AtlasRule: View {
    var body: some View { Rectangle().fill(Atlas.line).frame(height: 1) }
}

struct AtlasScreen<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 23) {
                content
            }
            .padding(.horizontal, 17)
            .padding(.top, 15)
            .padding(.bottom, 32)
            .frame(maxWidth: 650)
            .frame(maxWidth: .infinity)
        }
        .background(AtlasBackground())
    }
}

import SwiftUI
import UIKit

// BLASTERMC MOBILE 13 — REALM
// A visual language inspired by Minecraft's spatial geometry, not a generic store template.
enum Atlas {
    static let canvas = Color(red: 0.958, green: 0.960, blue: 0.949)
    static let paper = Color(red: 1.000, green: 1.000, blue: 0.988)
    static let ink = Color(red: 0.055, green: 0.105, blue: 0.205)
    static let muted = Color(red: 0.355, green: 0.400, blue: 0.467)
    static let blue = Color(red: 0.075, green: 0.235, blue: 0.590)
    static let blueLight = Color(red: 0.875, green: 0.918, blue: 0.985)
    static let copper = Color(red: 0.790, green: 0.275, blue: 0.165)
    static let orange = Color(red: 1.000, green: 0.735, blue: 0.390)
    static let sand = Color(red: 1.000, green: 0.925, blue: 0.820)
    static let line = Color(red: 0.835, green: 0.855, blue: 0.878)
    static let danger = Color(red: 0.720, green: 0.160, blue: 0.170)
    static let navy = Color(red: 0.035, green: 0.075, blue: 0.165)
    static let deepBlue = Color(red: 0.055, green: 0.145, blue: 0.345)
    static let aqua = Color(red: 0.620, green: 0.840, blue: 0.940)
    static let mint = Color(red: 0.210, green: 0.620, blue: 0.475)

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
            LinearGradient(colors: [.white.opacity(0.72), .clear, Atlas.blue.opacity(0.035)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            GeometryReader { proxy in
                Path { path in
                    let step: CGFloat = 26
                    stride(from: CGFloat(0), through: proxy.size.width, by: step).forEach { x in
                        stride(from: CGFloat(0), through: proxy.size.height, by: step).forEach { y in
                            path.addRect(CGRect(x: x, y: y, width: 1, height: 1))
                        }
                    }
                }
                .fill(Atlas.navy.opacity(0.035))
            }
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }
}

struct AtlasCard<Content: View>: View {
    var inset: CGFloat = 17
    var spacing: CGFloat = 12
    var tinted = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(inset)
            .background(tinted ? Atlas.blueLight : Atlas.paper,
                        in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .strokeBorder(tinted ? Atlas.blue.opacity(0.17) : Atlas.line.opacity(0.9), lineWidth: 1)
            }
            .shadow(color: Atlas.navy.opacity(tinted ? 0.025 : 0.055), radius: 13, x: 0, y: 5)
    }
}

struct AtlasHeading: View {
    let kicker: String
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                Text(kicker.uppercased())
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(Atlas.copper)
                    .fixedSize(horizontal: false, vertical: true)
                Rectangle().fill(Atlas.copper.opacity(0.48)).frame(width: 23, height: 1)
            }
            Text(title)
                .font(.system(size: 23, weight: .black, design: .rounded))
                .tracking(-0.75)
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
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Atlas.navy)
                BlasterLogo(size: 38)
            }
            .frame(width: 43, height: 43)
            VStack(alignment: .leading, spacing: 2) {
                Text("BLASTERMC")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(-0.5)
                    .foregroundStyle(Atlas.ink)
                    .lineLimit(1)
                Text(label.uppercased())
                    .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                    .tracking(0.75)
                    .foregroundStyle(Atlas.copper)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 4)
            if let trailingSymbol, let onTrailing {
                Button {
                    Atlas.haptic()
                    onTrailing()
                } label: {
                    Image(systemName: trailingSymbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Atlas.ink)
                        .frame(width: 43, height: 43)
                        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Atlas.line))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Haberleri aç")
            }
        }
        .padding(.vertical, 1)
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
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .black))
                    .frame(width: 28, height: 28)
                    .background(secondary ? Atlas.blueLight : Color.white.opacity(0.14),
                                in: RoundedRectangle(cornerRadius: 9))
            }
            .foregroundStyle(secondary ? Atlas.blue : Color.white)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, minHeight: 49)
            .background(secondary ? Atlas.paper : Atlas.blue,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14)
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
        HStack(spacing: 5) {
            if let symbol { Image(systemName: symbol).font(.system(size: 9, weight: .bold)) }
            Text(title)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
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
        VStack(alignment: .leading, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 23, weight: .medium))
                .foregroundStyle(Atlas.blue)
                .frame(width: 45, height: 45)
                .background(Atlas.blueLight, in: RoundedRectangle(cornerRadius: 13))
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(Atlas.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(Atlas.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Atlas.line))
    }
}

struct AtlasBanner<Content: View>: View {
    var eyebrow: String
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Atlas.blue, Atlas.navy],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            RealmPortalArt()
                .frame(width: 105, height: 132)
                .opacity(0.42)
                .padding(.top, 12)
                .padding(.trailing, 4)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 7) {
                    Capsule().fill(Atlas.orange).frame(width: 18, height: 3)
                    Text(eyebrow.uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .tracking(0.8)
                        .foregroundStyle(Atlas.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 58)
            .padding(19)
        }
        .fixedSize(horizontal: false, vertical: true)
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Atlas.aqua.opacity(0.16)))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// A portal made from SwiftUI vector shapes; no low-resolution stock art or reused screenshots.
struct RealmPortalArt: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Atlas.aqua.opacity(0.48), Atlas.blue.opacity(0.02)],
                                         center: .center, startRadius: 2, endRadius: w * 0.52))
                    .frame(width: w * 1.12, height: h * 0.9)
                    .blur(radius: 4)
                Circle()
                    .strokeBorder(LinearGradient(colors: [Atlas.orange, Atlas.aqua, Atlas.blueLight],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing),
                                  lineWidth: max(3, w * 0.045))
                    .frame(width: w * 0.66, height: h * 0.76)
                    .rotationEffect(.degrees(-15))
                    .shadow(color: Atlas.aqua.opacity(0.4), radius: 9)
                RoundedRectangle(cornerRadius: w * 0.18)
                    .fill(LinearGradient(colors: [Atlas.aqua.opacity(0.32), Atlas.blue.opacity(0.02)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.48, height: h * 0.58)
                    .rotationEffect(.degrees(-15))
                RealmCube(width: w * 0.35, height: h * 0.31, tone: 0)
                    .position(x: w * 0.18, y: h * 0.78)
                RealmCube(width: w * 0.29, height: h * 0.25, tone: 1)
                    .position(x: w * 0.81, y: h * 0.22)
                RealmCube(width: w * 0.23, height: h * 0.20, tone: 2)
                    .position(x: w * 0.83, y: h * 0.78)
                Circle().fill(Atlas.orange).frame(width: 5, height: 5).position(x: w * 0.18, y: h * 0.25)
                Circle().fill(Atlas.aqua).frame(width: 4, height: 4).position(x: w * 0.79, y: h * 0.48)
            }
        }
    }
}

struct RealmCube: View {
    var width: CGFloat
    var height: CGFloat
    var tone: Int = 0

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: 0))
                    p.addLine(to: CGPoint(x: w, y: h * 0.25))
                    p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
                    p.addLine(to: CGPoint(x: 0, y: h * 0.25))
                    p.closeSubpath()
                }.fill(tone == 1 ? Atlas.orange : Atlas.aqua)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.25))
                    p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
                    p.addLine(to: CGPoint(x: w * 0.5, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h * 0.72))
                    p.closeSubpath()
                }.fill(tone == 2 ? Atlas.blueLight : Atlas.blue.opacity(0.86))
                Path { p in
                    p.move(to: CGPoint(x: w, y: h * 0.25))
                    p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
                    p.addLine(to: CGPoint(x: w * 0.5, y: h))
                    p.addLine(to: CGPoint(x: w, y: h * 0.72))
                    p.closeSubpath()
                }.fill(tone == 1 ? Atlas.copper : Atlas.navy.opacity(0.76))
                Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: 0))
                    p.addLine(to: CGPoint(x: w, y: h * 0.25))
                    p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
                    p.addLine(to: CGPoint(x: 0, y: h * 0.25))
                    p.closeSubpath()
                }.stroke(.white.opacity(0.34), lineWidth: 0.8)
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

struct AtlasPixelSignature: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(index == 0 ? Atlas.orange : Color.white.opacity(0.58))
                    .frame(width: 7, height: 7)
            }
        }
        .frame(height: 20)
        .accessibilityHidden(true)
    }
}

struct AtlasBlockArtwork: View {
    var body: some View { RealmPortalArt() }
}

struct AtlasRule: View {
    var body: some View { Rectangle().fill(Atlas.line).frame(height: 1) }
}

struct AtlasScreen<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 21) { content }
                .padding(.horizontal, 17)
                .padding(.top, 14)
                .padding(.bottom, 28)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
        }
        .background(AtlasBackground())
    }
}

import SwiftUI

enum BlasterTheme {
    static let canvas = Color(red: 0.968, green: 0.954, blue: 0.927)
    static let paper = Color(red: 1.00, green: 0.990, blue: 0.971)
    static let ink = Color(red: 0.17, green: 0.19, blue: 0.23)
    static let muted = Color(red: 0.48, green: 0.47, blue: 0.46)
    static let gold = Color(red: 0.84, green: 0.51, blue: 0.13)
    static let amber = Color(red: 1.00, green: 0.76, blue: 0.34)
    static let navy = Color(red: 0.11, green: 0.18, blue: 0.30)
    static let cream = Color(red: 1.00, green: 0.94, blue: 0.82)
    static let copper = Color(red: 0.49, green: 0.27, blue: 0.13)
}

struct BlasterLogo: View {
    var size: CGFloat = 52
    var body: some View {
        Image("BrandLogo")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("BlasterMC altın B logosu")
    }
}

struct PremiumBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.996, green: 0.982, blue: 0.944),
                BlasterTheme.canvas,
                Color(red: 0.940, green: 0.944, blue: 0.944)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [
                BlasterTheme.amber.opacity(0.12),
                .clear
            ], center: .topTrailing, startRadius: 40, endRadius: 440)
            RadialGradient(colors: [
                BlasterTheme.navy.opacity(0.045),
                .clear
            ], center: .bottomLeading, startRadius: 0, endRadius: 450)
        }
        .ignoresSafeArea()
    }
}

struct PremiumBanner: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let symbol: String
    @State private var lifted = false

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [
                    BlasterTheme.navy,
                    Color(red: 0.24, green: 0.25, blue: 0.31),
                    BlasterTheme.copper
                ], startPoint: .leading, endPoint: .bottomTrailing))
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(BlasterTheme.amber.opacity(0.16))
                        .frame(width: 190, height: 190)
                        .blur(radius: 42)
                    Image(systemName: symbol)
                        .font(.system(size: 106))
                        .foregroundStyle(BlasterTheme.amber.opacity(0.23))
                        .rotationEffect(.degrees(-16))
                        .offset(x: lifted ? -2 : 12, y: lifted ? -12 : 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .offset(x: geometry.size.width * 0.08)
            }
            .clipped()
            VStack(alignment: .leading, spacing: 11) {
                Text(eyebrow)
                    .font(.system(size: 10, weight: .black))
                    .tracking(2.0)
                    .foregroundStyle(BlasterTheme.amber)
                Text(title)
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 38)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(23)
        }
        .frame(minHeight: 192)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28)
            .strokeBorder(BlasterTheme.amber.opacity(0.26), lineWidth: 1))
        .shadow(color: BlasterTheme.navy.opacity(0.20), radius: 19, y: 10)
        .onAppear {
            withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                lifted = true
            }
        }
    }
}

struct BlasterCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .fill(LinearGradient(colors: [
                        BlasterTheme.paper,
                        Color(red: 0.986, green: 0.977, blue: 0.957)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [
                        BlasterTheme.gold.opacity(0.32),
                        BlasterTheme.gold.opacity(0.06),
                        .white.opacity(0.90)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            }
            .shadow(color: BlasterTheme.navy.opacity(0.085), radius: 17, y: 8)
    }
}

struct SectionHeader: View {
    let title: String
    let caption: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(BlasterTheme.gold)
                    .frame(width: 4, height: 24)
                Text(title)
                    .font(.title2.weight(.heavy))
                    .tracking(-0.5)
                    .foregroundStyle(BlasterTheme.ink)
            }
            Text(caption)
                .font(.caption)
                .foregroundStyle(BlasterTheme.muted)
        }
    }
}

struct NoticePlaceholder: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        BlasterCard {
            VStack(spacing: 13) {
                Image(systemName: symbol)
                    .font(.system(size: 30))
                    .foregroundStyle(BlasterTheme.gold)
                    .frame(width: 66, height: 66)
                    .background(BlasterTheme.cream, in: RoundedRectangle(cornerRadius: 17))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(BlasterTheme.ink)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(BlasterTheme.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
}

struct BlasterTapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.976 : 1)
            .opacity(configuration.isPressed ? 0.89 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

struct GoldButton: View {
    let title: String
    let symbol: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.heavy))
                .tracking(0.25)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(BlasterTheme.navy)
                .background(LinearGradient(colors: [
                    BlasterTheme.cream,
                    BlasterTheme.amber,
                    BlasterTheme.gold
                ], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(.white.opacity(0.45), lineWidth: 1))
                .shadow(color: BlasterTheme.gold.opacity(0.22), radius: 12, y: 6)
        }
        .buttonStyle(BlasterTapStyle())
    }
}

import SwiftUI

/// Realm hotbar: five clear destinations in a Minecraft-inspired slot rail.
struct AtlasShell: View {
    @ObservedObject var server: ServerStatusModel
    @State private var selected = 0

    var body: some View {
        ZStack {
            AtlasBackground()
            Group {
                switch selected {
                case 1: AtlasWorldView(server: server)
                case 2: AtlasMarketView()
                case 3: AtlasSeasonView()
                case 4: AtlasProfileView()
                default: AtlasHomeView(server: server, select: navigate, active: selected == 0)
                }
            }
            .id(selected)
            .transition(.opacity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { hotbar }
        .preferredColorScheme(.light)
    }

    private func navigate(_ index: Int) {
        guard selected != index else { return }
        Atlas.haptic()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            selected = index
        }
    }

    private var hotbar: some View {
        HStack(spacing: 5) {
            tab(0, title: "Ana Sayfa", icon: "house.fill")
            tab(1, title: "Dünya", icon: "square.stack.3d.up.fill")
            tab(2, title: "Mağaza", icon: "shippingbox.fill")
            tab(3, title: "Sezon", icon: "trophy.fill")
            tab(4, title: "Profil", icon: "person.crop.square.fill")
        }
        .padding(7)
        .background(Atlas.navy, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 21).strokeBorder(.white.opacity(0.12)))
        .shadow(color: Atlas.navy.opacity(0.22), radius: 18, x: 0, y: 6)
        .padding(.horizontal, 11)
        .padding(.top, 5)
        .padding(.bottom, 3)
        .background(
            LinearGradient(colors: [Atlas.canvas.opacity(0.0), Atlas.canvas.opacity(0.98)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tab(_ index: Int, title: String, icon: String) -> some View {
        let active = selected == index
        return Button { navigate(index) } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .black))
                    .frame(height: 20)
                Text(title)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(active ? Atlas.navy : Color.white.opacity(0.78))
            .frame(maxWidth: .infinity)
            .frame(height: 51)
            .background(active ? Atlas.orange : Atlas.deepBlue.opacity(0.2),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(active ? Atlas.orange : Color.white.opacity(0.08)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(active ? .isSelected : .isButton)
    }
}

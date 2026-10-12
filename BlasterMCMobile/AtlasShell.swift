import SwiftUI

/// AURORA navigation: one focused screen, a tactile floating dock, and a
/// bottom safe-area boundary that never hides the profile logout action.
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            dock
        }
        .preferredColorScheme(.light)
    }

    private func navigate(_ index: Int) {
        guard selected != index else { return }
        Atlas.haptic()
        withAnimation(.easeInOut(duration: 0.18)) { selected = index }
    }

    private var dock: some View {
        HStack(spacing: 2) {
            tab(0, title: "Ana Sayfa", icon: "house.fill")
            tab(1, title: "Dünya", icon: "square.stack.3d.up.fill")
            tab(2, title: "Mağaza", icon: "bag.fill")
            tab(3, title: "Sezon", icon: "trophy.fill")
            tab(4, title: "Profil", icon: "person.crop.circle.fill")
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Atlas.line, lineWidth: 1))
        .shadow(color: Atlas.navy.opacity(0.12), radius: 20, x: 0, y: 7)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 3)
        .background(
            LinearGradient(colors: [Atlas.canvas.opacity(0.0), Atlas.canvas.opacity(0.97)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tab(_ index: Int, title: String, icon: String) -> some View {
        let active = selected == index
        return Button {
            navigate(index)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: active ? .bold : .medium))
                    .frame(height: 23)
                Text(title)
                    .font(.system(size: 9.5, weight: active ? .heavy : .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(active ? Color.white : Atlas.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(active ? Atlas.blue : Color.clear,
                        in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(active ? .isSelected : .isButton)
    }
}

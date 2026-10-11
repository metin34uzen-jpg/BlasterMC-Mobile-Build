import SwiftUI

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
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .preferredColorScheme(.light)
    }

    private func navigate(_ index: Int) {
        guard selected != index else { return }
        Atlas.haptic()
        selected = index
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Atlas.line).frame(height: 1)
            HStack(spacing: 0) {
                tab(0, title: "Ana Sayfa", icon: "house")
                tab(1, title: "Dünya", icon: "globe.europe.africa")
                tab(2, title: "Mağaza", icon: "bag")
                tab(3, title: "Sezon", icon: "trophy")
                tab(4, title: "Profil", icon: "person.crop.circle")
            }
            .padding(.horizontal, 6)
            .padding(.top, 8)
            .padding(.bottom, 5)
        }
        .background(Atlas.paper.ignoresSafeArea(edges: .bottom))
    }

    private func tab(_ index: Int, title: String, icon: String) -> some View {
        let active = selected == index
        return Button {
            navigate(index)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: active ? .bold : .regular))
                    .foregroundStyle(active ? Atlas.copper : Atlas.muted)
                    .frame(height: 25)
                Text(title)
                    .font(.system(size: 10, weight: active ? .heavy : .medium))
                    .foregroundStyle(active ? Atlas.ink : Atlas.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                Capsule()
                    .fill(active ? Atlas.copper : Color.clear)
                    .frame(width: 19, height: 3)
            }
            .frame(maxWidth: .infinity, minHeight: 53)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(active ? .isSelected : .isButton)
    }
}

import SwiftUI

// One tactile navigation system for the entire BlasterMC player universe.
struct ForgeShell: View {
    @ObservedObject var server: ServerStatusModel
    @State private var selected = 0

    var body: some View {
        ZStack {
            ForgeBackground()
            Group {
                switch selected {
                case 1:
                    ForgeWorldView(server: server)
                case 2:
                    ForgeMarketView()
                case 3:
                    ForgeSeasonView()
                case 4:
                    ForgeProfileView()
                default:
                    ForgeHomeView(server: server,open: change,active: selected == 0)
                }
            }
            .id(selected)
            .transition(.opacity)
        }
        .safeAreaInset(edge:.bottom,spacing:0) {
            dock
        }
    }

    private func change(_ index:Int) {
        guard selected != index else { return }
        Forge.impact()
        withAnimation(.easeInOut(duration:0.16)) {
            selected=index
        }
    }

    private var dock: some View {
        VStack(spacing:0) {
            Rectangle()
                .fill(Forge.gold.opacity(0.48))
                .frame(height:1)
            HStack(spacing:2) {
                item(0,title:"EV",symbol:"house.fill")
                item(1,title:"DÜNYA",symbol:"square.stack.3d.up")
                item(2,title:"MARKET",symbol:"bag.fill")
                item(3,title:"SEZON",symbol:"trophy.fill")
                item(4,title:"PROFİL",symbol:"person.crop.square.fill")
            }
            .padding(.horizontal,10)
            .padding(.top,9)
            .padding(.bottom,7)
            .background(Forge.midnight)
        }
        .background(Forge.midnight.ignoresSafeArea(edges:.bottom))
        .shadow(color:Forge.midnight.opacity(0.15),radius:12,y:-4)
    }

    private func item(_ index:Int,title:String,symbol:String) -> some View {
        let active = selected == index
        return Button {
            change(index)
        } label: {
            VStack(spacing:5) {
                ZStack {
                    ForgeCut(cut:7)
                        .fill(active ? Forge.sun : .clear)
                        .frame(maxWidth:.infinity)
                        .frame(height:29)
                    Image(systemName:symbol)
                        .font(.system(size:16,weight:active ? .bold : .medium))
                        .foregroundStyle(active ? Forge.midnight : .white.opacity(0.77))
                }
                Text(title)
                    .font(.system(size:9,weight:.black,design:.monospaced))
                    .tracking(0.1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(active ? Forge.sun : .white.opacity(0.66))
            }
            .frame(maxWidth:.infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(BlasterTapStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(active ? .isSelected : .isButton)
    }
}

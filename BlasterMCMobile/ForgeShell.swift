import SwiftUI

// One tactile navigation system for the entire BlasterMC player universe.
struct ForgeShell: View {
    @ObservedObject var server: ServerStatusModel
    @State private var selected = 0

    var body: some View {
        ZStack {
            StudioBackground()
            Group {
                switch selected {
                case 1:
                    StudioWorldView(server: server)
                case 2:
                    StudioMarketView()
                case 3:
                    StudioSeasonView()
                case 4:
                    StudioProfileView()
                default:
                    StudioHomeView(server: server,open: change,active: selected == 0)
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
        Studio.touch()
        withAnimation(.easeInOut(duration:0.16)) {
            selected=index
        }
    }

    private var dock: some View {
        VStack(spacing:0) {
            Rectangle().fill(Studio.line).frame(height:1)
            HStack(spacing:0) {
                item(0,title:"Ana Sayfa",symbol:"house")
                item(1,title:"Dünya",symbol:"globe.europe.africa")
                item(2,title:"Mağaza",symbol:"bag")
                item(3,title:"Sezon",symbol:"trophy")
                item(4,title:"Profil",symbol:"person.crop.circle")
            }
            .padding(.horizontal,8)
            .padding(.top,7)
            .padding(.bottom,5)
        }
        .background(Studio.paper.ignoresSafeArea(edges:.bottom))
    }

    private func item(_ index:Int,title:String,symbol:String)->some View {
        let isActive=selected == index
        return Button {
            change(index)
        } label: {
            VStack(spacing:5) {
                Image(systemName:isActive ? symbol+".fill" : symbol)
                    .font(.system(size:19,weight:isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Studio.gold : Studio.secondary)
                    .frame(height:25)
                Text(title)
                    .font(.system(size:10,weight:isActive ? .bold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.79)
                    .foregroundStyle(isActive ? Studio.ink : Studio.secondary)
                Capsule()
                    .fill(isActive ? Studio.gold : .clear)
                    .frame(width:18,height:2)
            }
            .frame(maxWidth:.infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(BlasterTapStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isActive ? .isSelected : .isButton)
    }
}

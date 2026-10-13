import SwiftUI

struct AtlasWorldView: View {
    @ObservedObject var server: ServerStatusModel
    @State private var tab = 0
    @State private var copied = ""
    @State private var toolsOpen = false

    private var modeTitle: String {
        switch tab { case 1: return "Ana lobi"; case 2: return "Topluluk"; default: return "SkyBlock" }
    }
    private var modeDescription: String {
        switch tab {
        case 1: return "Sunucunun ana merkezine dön, diğer oyuncularla buluş ve yeni macerana hazırlan."
        case 2: return "Duyuruları takip et, topluluğa katıl ve BlasterMC'deki yenilikleri kaçırma."
        default: return "Kendi adanı kur, kaynaklarını büyüt ve sezon sıralamasında zirveye oyna."
        }
    }

    var body: some View {
        AtlasScreen {
            AtlasMasthead(label: "Oyun rehberi / REALM")
            worldHero
            address
            modePicker
            modeDetails
            commandConsole
            communityLinks
        }
        .refreshable { await server.refresh() }
        .sheet(isPresented: $toolsOpen) { AtlasQuickPanel() }
    }

    private var worldHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(LinearGradient(colors: [Atlas.deepBlue, Atlas.navy],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            RealmPortalArt()
                .frame(width: 132, height: 150)
                .opacity(0.64)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 5)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 11) {
                AtlasPill(title: "OYUN EVRENİ", symbol: "globe.americas.fill", highlighted: true)
                Text(tab == 0 ? "Adanı\nkur. Büyü." :
                     tab == 1 ? "Merkeze\ngeri dön." : "Birlikte\ndaha güçlüyüz.")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .tracking(-0.9)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("BlasterMC'de sıradaki adımını seç.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .padding(.trailing, 118)
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    private var address: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Atlas.navy)
                Image(systemName: "server.rack")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Atlas.aqua)
            }
            .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle().fill(!server.hasConfirmedStatus || server.isStale ? Atlas.orange :
                                  server.isOnline ? Atlas.mint : Atlas.danger)
                        .frame(width: 6, height: 6)
                    Text(server.statusText.uppercased())
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .tracking(0.4)
                        .foregroundStyle(Atlas.muted)
                }
                Text("oyna.blastermc.com")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Atlas.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                Atlas.copy("oyna.blastermc.com")
                copied = "ip"
            } label: {
                Image(systemName: copied == "ip" ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Atlas.blue)
                    .frame(width: 39, height: 39)
                    .background(Atlas.blueLight, in: RoundedRectangle(cornerRadius: 11))
            }
            .accessibilityLabel("Sunucu adresini kopyala")
        }
        .padding(12)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Atlas.line))
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            AtlasHeading(kicker: "DÜNYA SEÇİMİ", title: "Nereden başlayalım?")
            HStack(spacing: 8) {
                modeTile("SkyBlock", subtitle: "Ada yaşamı", icon: "square.stack.3d.up.fill",
                         index: 0, tint: Atlas.blueLight)
                modeTile("Lobi", subtitle: "Ana merkez", icon: "house.fill",
                         index: 1, tint: Atlas.sand)
                modeTile("Topluluk", subtitle: "Oyuncular", icon: "person.3.fill",
                         index: 2, tint: Color(red: 0.91, green: 0.91, blue: 0.84))
            }
        }
    }

    private func modeTile(_ title: String, subtitle: String, icon: String,
                          index: Int, tint: Color) -> some View {
        let selected = tab == index
        return Button {
            Atlas.haptic()
            withAnimation(.easeInOut(duration: 0.18)) { tab = index }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(selected ? Atlas.orange : Atlas.ink)
                    .frame(width: 32, height: 32)
                    .background(selected ? Atlas.navy : tint, in: RoundedRectangle(cornerRadius: 10))
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Atlas.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Atlas.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 93, alignment: .leading)
            .padding(10)
            .background(selected ? Atlas.paper : Atlas.paper.opacity(0.55),
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .strokeBorder(selected ? Atlas.blue : Atlas.line, lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : .isButton)
    }

    private var modeDetails: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13).fill(Atlas.navy)
                    Image(systemName: tab == 0 ? "hammer.fill" :
                          tab == 1 ? "house.fill" : "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Atlas.orange)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 5) {
                    Text(modeTitle)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                    Text(modeDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(Atlas.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if tab == 0 {
                HStack(spacing: 7) {
                    AtlasPill(title: "ADA GELİŞTİR", symbol: "hammer.fill")
                    AtlasPill(title: "KAYNAK TOPLA", symbol: "cube.fill")
                    AtlasPill(title: "SIRALAMAYA GİR", symbol: "trophy.fill")
                }
            } else if tab == 1 {
                AtlasPill(title: "SUNUCU ADRESİ KOPYALA", symbol: "doc.on.doc")
            } else {
                AtlasPill(title: "RESMÎ WEB", symbol: "globe")
                AtlasPill(title: "DISCORD", symbol: "bubble.left")
            }
        }
        .padding(15)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Atlas.line))
    }

    private var commandConsole: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                AtlasHeading(kicker: "OYUN İÇİ", title: "Komut konsolu",
                             detail: "Dokunarak kopyala, oyunda kullan.")
                Spacer(minLength: 0)
                Button { toolsOpen = true } label: {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Atlas.blue)
                        .frame(width: 38, height: 38)
                        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Atlas.line))
                }
                .accessibilityLabel("Tüm komutları aç")
            }
            if tab == 0 {
                commandRow("/is", label: "Ada menüsü", subtitle: "Ada işlemlerini görüntüle")
                commandRow("/is home", label: "Adana dön", subtitle: "Kendi adana ışınlan")
                commandRow("/is top", label: "Ada sıralaması", subtitle: "Lider adaları gör")
            } else if tab == 1 {
                commandRow("/lobi", label: "Ana lobiye dön", subtitle: "Sunucunun merkezine dön")
                commandRow("/is", label: "SkyBlock", subtitle: "Ada menüsünü aç")
            } else {
                Link(destination: URL(string: "https://blastermc.com")!) {
                    linkRow("Resmî web sitesi", detail: "blastermc.com", icon: "globe")
                }
                Link(destination: URL(string: "https://discord.blastermc.com")!) {
                    linkRow("Discord topluluğu", detail: "discord.blastermc.com",
                            icon: "bubble.left.and.bubble.right.fill")
                }
            }
            Text("Komutlar kopyalanır; uygulama Minecraft istemcisini uzaktan kontrol etmez.")
                .font(.system(size: 10))
                .foregroundStyle(Atlas.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func commandRow(_ command: String, label: String, subtitle: String) -> some View {
        Button {
            Atlas.copy(command)
            copied = command
        } label: {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11).fill(Atlas.canvas)
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Atlas.blue)
                }
                .frame(width: 39, height: 39)
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                    Text(command + "  ·  " + subtitle)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Atlas.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: copied == command ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(copied == command ? Atlas.mint : Atlas.blue)
            }
            .padding(11)
            .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(Atlas.line))
        }
        .buttonStyle(.plain)
    }

    private var communityLinks: some View {
        HStack(spacing: 9) {
            Link(destination: URL(string: "https://blastermc.com")!) {
                linkRow("BlasterMC", detail: "Web sitesi", icon: "globe")
            }
            Link(destination: URL(string: "https://discord.blastermc.com")!) {
                linkRow("Discord", detail: "Topluluk", icon: "bubble.left.and.bubble.right.fill")
            }
        }
    }

    private func linkRow(_ title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Atlas.blue)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 11, weight: .black)).foregroundStyle(Atlas.ink)
                Text(detail).font(.system(size: 9, weight: .medium)).foregroundStyle(Atlas.muted)
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Atlas.copper)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Atlas.line))
    }
}

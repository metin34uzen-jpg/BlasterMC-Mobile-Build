import SwiftUI

struct AtlasWorldView: View {
    @ObservedObject var server: ServerStatusModel
    @State private var tab = 0
    @State private var copied = ""

    var body: some View {
        AtlasScreen {
            AtlasMasthead(label: "Dünya / SkyBlock")
            AtlasBanner(eyebrow: "BLASTERMC  /  OYUN EVRENİ") {
                Text("Bir blokla\nbaşlayan hikâye.")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("SkyBlock adan, ana lobi ve topluluk bağlantıların.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.90))
                    .fixedSize(horizontal: false, vertical: true)
            }
            address
            AtlasHeading(kicker: "OYUN REHBERİ", title: "Nereye gitmek istersin?")
            tabs
            guide
            shortcuts
            AtlasAction(title: "Sunucu durumunu yenile",
                        symbol: "arrow.clockwise", secondary: true) {
                Task { await server.refresh() }
            }
        }
        .refreshable { await server.refresh() }
    }

    private var address: some View {
        AtlasCard(tinted: true) {
            HStack(spacing: 8) {
                Circle()
                    .fill(!server.hasConfirmedStatus || server.isStale ? Color.orange :
                          server.isOnline ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(server.statusText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Atlas.ink)
                Spacer()
                if server.hasConfirmedStatus {
                    Text("\(server.onlinePlayers) oyuncu")
                        .font(.system(size: 11))
                        .foregroundStyle(Atlas.muted)
                }
            }
            Text("oyna.blastermc.com")
                .font(.system(size: 21, weight: .heavy, design: .monospaced))
                .foregroundStyle(Atlas.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            AtlasAction(title: copied == "ip" ? "Adres kopyalandı" : "Sunucu adresini kopyala",
                        symbol: copied == "ip" ? "checkmark" : "doc.on.doc") {
                Atlas.copy("oyna.blastermc.com")
                copied = "ip"
            }
        }
    }

    private var tabs: some View {
        HStack(spacing: 8) {
            choice("SkyBlock", index: 0)
            choice("Lobi", index: 1)
            choice("Topluluk", index: 2)
        }
    }

    private func choice(_ title: String, index: Int) -> some View {
        Button {
            Atlas.haptic()
            tab = index
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tab == index ? Color.white : Atlas.ink)
                .frame(maxWidth: .infinity, minHeight: 43)
                .background(tab == index ? Atlas.blue : Atlas.paper,
                            in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(tab == index ? Atlas.blue : Atlas.line))
        }
        .buttonStyle(.plain)
    }

    private var guide: some View {
        AtlasCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: tab == 0 ? "square.stack.3d.up.fill" :
                      tab == 1 ? "house.fill" : "person.3.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Atlas.copper)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 8) {
                    Text(tab == 0 ? "Adanı geliştir." :
                         tab == 1 ? "Merkeze geri dön." : "Topluluğu keşfet.")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(tab == 0 ?
                         "Kendi adanı kur, kaynak topla ve diğer adalarla yarış. Aşağıdaki komutlarla macerana yön ver." :
                         tab == 1 ?
                         "Lobi, BlasterMC evreninin ana merkezidir. Oyun içinden tek komutla geri dönebilirsin." :
                         "Resmî web sitemiz ve Discord topluluğumuz üzerinden yenilikleri takip edebilirsin.")
                        .font(.system(size: 12))
                        .foregroundStyle(Atlas.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var shortcuts: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "HIZLI ERİŞİM", title: tab == 2 ? "Bağlantılar" : "Oyun komutları")
            if tab == 0 {
                command("/is", label: "Ada menüsünü aç")
                command("/is home", label: "Kendi adana dön")
                command("/is top", label: "En iyi adaları gör")
            } else if tab == 1 {
                command("/lobi", label: "Ana lobiye dön")
                command("/is", label: "SkyBlock ada menüsü")
            } else {
                Link(destination: URL(string: "https://blastermc.com")!) {
                    external("Resmî web sitesi", subtitle: "blastermc.com", symbol: "globe")
                }
                Link(destination: URL(string: "https://discord.blastermc.com")!) {
                    external("Discord topluluğu", subtitle: "discord.blastermc.com",
                             symbol: "bubble.left.and.bubble.right.fill")
                }
            }
            if tab != 2 {
                Text("Komutlar kopyalanır; uygulama oyun içinde kendiliğinden işlem yapmaz. Komutların kullanılabilirliği sunucuya bağlıdır.")
                    .font(.system(size: 11))
                    .foregroundStyle(Atlas.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func command(_ value: String, label: String) -> some View {
        Button {
            Atlas.copy(value)
            copied = value
        } label: {
            AtlasCard(inset: 14) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Atlas.ink)
                        Text(value)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Atlas.copper)
                    }
                    Spacer()
                    Label(copied == value ? "Kopyalandı" : "Kopyala",
                          systemImage: copied == value ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Atlas.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func external(_ title: String, subtitle: String, symbol: String) -> some View {
        AtlasCard(inset: 14) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(Atlas.copper)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Atlas.ink)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Atlas.muted)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(Atlas.blue)
            }
        }
    }
}

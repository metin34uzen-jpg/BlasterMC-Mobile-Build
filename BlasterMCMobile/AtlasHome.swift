import SwiftUI

struct AtlasHomeView: View {
    @EnvironmentObject private var session: BlasterSession
    @ObservedObject var server: ServerStatusModel
    let select: (Int) -> Void
    let active: Bool
    @Environment(\.scenePhase) private var phase
    @State private var newsOpen = false
    @State private var toolsOpen = false
    @State private var copied = false

    var body: some View {
        AtlasScreen {
            AtlasMasthead(label: "Oyuncu merkezi / AURORA", trailingSymbol: "bell.badge") {
                newsOpen = true
            }
            greeting
            liveNetwork
            actionDeck
            toolbox
            seasonTeaser
            account
            latestNews
            links
        }
        .sheet(isPresented: $newsOpen) {
            AtlasNewsView()
                .environmentObject(session)
        }
        .sheet(isPresented: $toolsOpen) {
            AtlasQuickPanel()
        }
        .task(id: active && phase == .active) {
            guard active && phase == .active else { return }
            while !Task.isCancelled {
                await server.refresh()
                do { try await Task.sleep(for: .seconds(12)) }
                catch { break }
            }
        }
        .refreshable {
            await server.refresh()
            await session.reloadProfile()
            await session.reloadPublic()
        }
    }

    private var greeting: some View {
        AtlasBanner(eyebrow: "BLASTERMC / YENİ NESİL DENEYİM") {
            Text("Bir sonraki\nmacera burada.")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .tracking(-1.2)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text("Hoş geldin, \(session.profile?.minecraftName ?? "Oyuncu"). SkyBlock, sezon ve topluluğun tek bir yerde.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.91))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Atlas.haptic()
                select(1)
            } label: {
                HStack(spacing: 9) {
                    Text("MACERAYA BAŞLA")
                        .font(.system(size: 12, weight: .heavy))
                        .tracking(0.3)
                    Image(systemName: "arrow.up.right")
                    Spacer()
                }
                .foregroundStyle(Atlas.ink)
                .padding(.horizontal, 16)
                .frame(height: 46)
                .background(Atlas.orange, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private var liveNetwork: some View {
        VStack(alignment: .leading, spacing: 12) {
            AtlasHeading(kicker: "01 / SUNUCU", title: "Blaster Network",
                         detail: "Canlı oyuncu durumu ve bağlantı adresi")
            AtlasCard {
                HStack(spacing: 9) {
                    Circle()
                        .fill(!server.hasConfirmedStatus || server.isStale ? Color.orange :
                              server.isOnline ? Color.green : Color.red)
                        .frame(width: 9, height: 9)
                    Text(server.statusText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Atlas.ink)
                    Spacer()
                    Button {
                        Task { await server.refresh() }
                    } label: {
                        Label("Yenile", systemImage: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Atlas.copper)
                    }
                    .disabled(server.isLoading)
                }
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(server.hasConfirmedStatus ? server.onlinePlayers.formatted() : "—")
                        .font(.system(size: 41, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Atlas.ink)
                    Text(server.hasConfirmedStatus && server.maxPlayers > 0 ?
                         "/ \(server.maxPlayers.formatted()) oyuncu" : "çevrimiçi oyuncu")
                        .font(.system(size: 12))
                        .foregroundStyle(Atlas.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                AtlasRule()
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("OYUN ADRESİ")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Atlas.copper)
                        Text("oyna.blastermc.com")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(Atlas.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        Atlas.copy("oyna.blastermc.com")
                        copied = true
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Atlas.blue)
                            .frame(width: 48, height: 48)
                            .background(Atlas.blueLight, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel(copied ? "Kopyalandı" : "IP adresini kopyala")
                }
                if let last = server.lastSuccess {
                    Text("Son kontrol: \(last, style: .time)")
                        .font(.system(size: 10))
                        .foregroundStyle(Atlas.muted)
                }
            }
        }
    }

    private var actionDeck: some View {
        VStack(alignment: .leading, spacing: 12) {
            AtlasHeading(kicker: "02 / KEŞFET", title: "Blaster evrenini keşfet", detail: "İhtiyacın olan her şey bir dokunuş uzağında.")
            HStack(alignment: .top, spacing: 10) {
                tile("Dünya", detail: "SkyBlock ve komutlar",
                     symbol: "square.stack.3d.up.fill", index: 1)
                tile("Mağaza", detail: "VIP ve koleksiyon",
                     symbol: "bag.fill", index: 2)
            }
            HStack(alignment: .top, spacing: 10) {
                tile("Sezon", detail: "₺7.500 ödül",
                     symbol: "trophy.fill", index: 3)
                Button {
                    newsOpen = true
                } label: {
                    tileContent("Haberler", detail: "Topluluk gündemi",
                                symbol: "megaphone.fill")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tile(_ title: String, detail: String, symbol: String, index: Int) -> some View {
        Button {
            Atlas.haptic()
            select(index)
        } label: {
            tileContent(title, detail: detail, symbol: symbol)
        }
        .buttonStyle(.plain)
    }

    private func tileContent(_ title: String, detail: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(Atlas.copper)
                .frame(height: 27)
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Atlas.ink)
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(Atlas.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(15)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Atlas.line))
    }

    private var toolbox: some View {
        Button {
            toolsOpen = true
        } label: {
            HStack(spacing: 13) {
                Image(systemName: "square.grid.3x3.topleft.filled")
                    .font(.system(size: 20))
                    .foregroundStyle(Atlas.blue)
                    .frame(width: 47, height: 47)
                    .background(Atlas.blueLight, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 5) {
                    Text("Hızlı erişim merkezi")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                    Text("Komutlar, sunucu IP'si ve bağlantılar")
                        .font(.system(size: 11))
                        .foregroundStyle(Atlas.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(Atlas.blue)
            }
            .padding(15)
            .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Atlas.line))
        }
        .buttonStyle(.plain)
    }

    private var seasonTeaser: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "03 / SEZON", title: "Zirvenin ödülü",
                         detail: "Açıklanan SkyBlock sıralama ödülleri")
            Button {
                select(3)
            } label: {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 25))
                            .foregroundStyle(Atlas.copper)
                            .frame(width: 45, height: 45)
                            .background(Atlas.sand, in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("₺7.500")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(Atlas.ink)
                            Text("TOPLAM NAKİT ÖDÜL")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Atlas.copper)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(Atlas.copper)
                    }
                    AtlasRule()
                    HStack(spacing: 10) {
                        rewardSmall("1.", value: "₺5.000")
                        rewardSmall("2.", value: "₺1.500")
                        rewardSmall("3.", value: "₺1.000")
                    }
                }
                .padding(17)
                .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 19))
                .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(Atlas.line))
            }
            .buttonStyle(.plain)
        }
    }

    private func rewardSmall(_ position: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(position)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Atlas.copper)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Atlas.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var account: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "04 / HESABIN", title: "Oyuncu kartın")
            Button {
                select(4)
            } label: {
                AtlasCard {
                    HStack(spacing: 12) {
                        avatar
                        VStack(alignment: .leading, spacing: 5) {
                            Text(session.profile?.minecraftName ?? "Oyuncu")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Atlas.ink)
                                .lineLimit(2)
                            Text(session.profile?.rank ?? "BlasterMC topluluğu")
                                .font(.system(size: 12))
                                .foregroundStyle(Atlas.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right").foregroundStyle(Atlas.copper)
                    }
                    AtlasRule()
                    HStack(spacing: 7) {
                        Image(systemName: "circle.hexagongrid.fill")
                            .foregroundStyle(Atlas.copper)
                        Text("Blaster Cüzdanı")
                            .font(.system(size: 12))
                            .foregroundStyle(Atlas.muted)
                        Spacer()
                        Text("\((session.profile?.credits ?? 0).formatted()) kredi")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Atlas.ink)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13).fill(Atlas.blueLight)
            if let url = session.profile?.skinUrl {
                AsyncImage(url: url) { image in image.resizable().scaledToFit() }
                    placeholder: { BlasterLogo(size: 40) }
                    .padding(4)
            } else { BlasterLogo(size: 40) }
        }
        .frame(width: 58, height: 62)
    }

    private var latestNews: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "05 / TOPLULUK", title: "Blaster Haberler")
            if let item = (session.announcements + session.events)
                .sorted(by: { $0.createdAt > $1.createdAt }).first {
                Button {
                    newsOpen = true
                } label: {
                    AtlasCard {
                        HStack {
                            AtlasPill(title: item.category, symbol: "megaphone", highlighted: true)
                            Spacer()
                            Text(item.createdAt, style: .date)
                                .font(.system(size: 10))
                                .foregroundStyle(Atlas.muted)
                        }
                        Text(item.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Atlas.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(item.body)
                            .font(.system(size: 12))
                            .foregroundStyle(Atlas.muted)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)
            } else {
                AtlasEmpty(title: "Haber akışı bekleniyor",
                           detail: session.dataError ?? "Duyurular yayınlandığında burada göreceksin.",
                           symbol: "newspaper")
            }
            AtlasAction(title: "Tüm haberleri aç", symbol: "arrow.up.right", secondary: true) {
                newsOpen = true
            }
        }
    }

    private var links: some View {
        HStack(spacing: 10) {
            Link(destination: URL(string: "https://blastermc.com")!) {
                Label("Web sitesi", systemImage: "globe")
                    .frame(maxWidth: .infinity, minHeight: 45)
            }
            Link(destination: URL(string: "https://discord.blastermc.com")!) {
                Label("Discord", systemImage: "person.2.fill")
                    .frame(maxWidth: .infinity, minHeight: 45)
            }
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(Atlas.blue)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Atlas.line))
    }
}

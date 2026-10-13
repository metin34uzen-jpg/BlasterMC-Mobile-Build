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

    private var latestStory: MobileNotice? {
        (session.announcements + session.events).sorted { $0.createdAt > $1.createdAt }.first
    }

    var body: some View {
        AtlasScreen {
            AtlasMasthead(label: "Oyuncu üssü / REALM", trailingSymbol: "newspaper") {
                newsOpen = true
            }
            realmHero
            serverConsole
            launchRail
            seasonStage
            communityStory
            playerIdentity
            footerLinks
        }
        .sheet(isPresented: $newsOpen) {
            AtlasNewsView().environmentObject(session)
        }
        .sheet(isPresented: $toolsOpen) {
            AtlasQuickPanel()
        }
        .task(id: active && phase == .active) {
            guard active && phase == .active else { return }
            while !Task.isCancelled {
                await server.refresh()
                do { try await Task.sleep(for: .seconds(15)) }
                catch { break }
            }
        }
        .refreshable {
            await server.refresh()
            await session.reloadProfile()
            await session.reloadPublic()
        }
    }

    private var realmHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .fill(LinearGradient(colors: [Atlas.navy, Atlas.deepBlue, Atlas.blue],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .fill(Atlas.aqua.opacity(0.09))
                .frame(width: 210, height: 210)
                .blur(radius: 16)
                .offset(x: 130, y: -45)
            RealmPortalArt()
                .frame(width: 132, height: 176)
                .offset(x: 104, y: 9)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 7) {
                    Circle().fill(Atlas.mint).frame(width: 7, height: 7)
                    Text("BLASTERNETWORK  /  SKYBLOCK")
                        .font(.system(size: 8.5, weight: .black, design: .monospaced))
                        .tracking(0.45)
                        .foregroundStyle(Atlas.aqua)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Text("KENDİ\nEFSANENİ\nYAZ.")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .tracking(-1.05)
                    .foregroundStyle(.white)
                    .lineSpacing(-2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("Hoş geldin, \(session.profile?.minecraftName ?? "oyuncu").")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Atlas.haptic()
                    select(1)
                } label: {
                    HStack(spacing: 8) {
                        Text("DÜNYAYI KEŞFET")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.35)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundStyle(Atlas.navy)
                    .padding(.horizontal, 13)
                    .frame(height: 38)
                    .background(Atlas.orange, in: RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 19)
            .padding(.vertical, 21)
            .padding(.trailing, 130)
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i == 0 ? Atlas.orange : .white.opacity(0.25))
                        .frame(width: i == 0 ? 19 : 5, height: 4)
                }
            }
            .padding(.trailing, 19)
            .padding(.bottom, 13)
            .accessibilityHidden(true)
        }
    }

    private var serverConsole: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                AtlasHeading(kicker: "01 / CANLI SUNUCU", title: "Ağ durumu")
                Spacer(minLength: 0)
                Button {
                    Task { await server.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Atlas.blue)
                        .frame(width: 37, height: 37)
                        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Atlas.line))
                }
                .disabled(server.isLoading)
                .accessibilityLabel("Sunucu durumunu yenile")
            }
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13).fill(Atlas.navy)
                        Image(systemName: "server.rack")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(Atlas.aqua)
                    }
                    .frame(width: 45, height: 45)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("BLASTER NETWORK")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(Atlas.ink)
                        HStack(spacing: 6) {
                            Circle().fill(!server.hasConfirmedStatus || server.isStale ? Atlas.orange :
                                          server.isOnline ? Atlas.mint : Atlas.danger)
                                .frame(width: 6, height: 6)
                            Text(server.statusText)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Atlas.muted)
                        }
                    }
                    Spacer(minLength: 3)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(server.hasConfirmedStatus ? server.onlinePlayers.formatted() : "—")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Atlas.ink)
                        Text("OYUNCU")
                            .font(.system(size: 8, weight: .heavy, design: .monospaced))
                            .tracking(0.8)
                            .foregroundStyle(Atlas.copper)
                    }
                }
                .padding(15)
                Rectangle().fill(Atlas.line).frame(height: 1)
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BAĞLANTI ADRESİ")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .tracking(0.9)
                            .foregroundStyle(Atlas.muted)
                        Text("oyna.blastermc.com")
                            .font(.system(size: 14, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Atlas.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 3)
                    Button {
                        Atlas.copy("oyna.blastermc.com")
                        copied = true
                    } label: {
                        Label(copied ? "KOPYALANDI" : "KOPYALA",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(Atlas.blue)
                            .padding(.horizontal, 11)
                            .frame(height: 34)
                            .background(Atlas.blueLight, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
            }
            .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 20))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Atlas.line))
            .shadow(color: Atlas.navy.opacity(0.04), radius: 12, x: 0, y: 4)
        }
    }

    private var launchRail: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                AtlasHeading(kicker: "02 / OYUNCU KISAYOLLARI", title: "Hızlı geçiş")
                Spacer()
                Button("Komutlar") { toolsOpen = true }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Atlas.blue)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 11) {
                    launchTile("SkyBlock", detail: "Adanı kur", symbol: "square.stack.3d.up.fill",
                               tint: Atlas.blueLight, index: 1)
                    launchTile("Mağaza", detail: "Rütbe ve kasa", symbol: "shippingbox.fill",
                               tint: Atlas.sand, index: 2)
                    launchTile("Sezon", detail: "₺7.500 ödül", symbol: "trophy.fill",
                               tint: Color(red: 0.91, green: 0.91, blue: 0.84), index: 3)
                    Button { newsOpen = true } label: {
                        launchTileContent("Haberler", detail: "Son gelişmeler",
                                          symbol: "newspaper.fill", tint: Atlas.blueLight)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
                .padding(.trailing, 2)
            }
        }
    }

    private func launchTile(_ title: String, detail: String, symbol: String,
                            tint: Color, index: Int) -> some View {
        Button {
            Atlas.haptic()
            select(index)
        } label: {
            launchTileContent(title, detail: detail, symbol: symbol, tint: tint)
        }
        .buttonStyle(.plain)
    }

    private func launchTileContent(_ title: String, detail: String,
                                   symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Atlas.ink)
                .frame(width: 40, height: 40)
                .background(tint, in: RoundedRectangle(cornerRadius: 13))
            Spacer(minLength: 0)
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(Atlas.ink)
            Text(detail)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Atlas.muted)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(width: 137, height: 128, alignment: .leading)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(Atlas.muted.opacity(0.65))
                .padding(13)
        }
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Atlas.line))
    }

    private var seasonStage: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                AtlasHeading(kicker: "03 / SEZON ÖDÜLLERİ", title: "Kürsüye çık")
                Spacer()
                Button("Sıralama") { select(3) }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Atlas.blue)
            }
            HStack(spacing: 8) {
                podiumPrize("1", "₺5.000", tone: Atlas.navy, foreground: .white, symbol: "crown.fill")
                    .frame(maxWidth: .infinity)
                podiumPrize("2", "₺1.500", tone: Atlas.paper, foreground: Atlas.ink, symbol: "medal.fill")
                    .frame(maxWidth: .infinity)
                podiumPrize("3", "₺1.000", tone: Atlas.paper, foreground: Atlas.ink, symbol: "medal.fill")
                    .frame(maxWidth: .infinity)
            }
            HStack(spacing: 7) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Atlas.copper)
                Text("Açıklanan nakit ödüller · Toplam ₺7.500")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Atlas.muted)
            }
        }
    }

    private func podiumPrize(_ rank: String, _ amount: String, tone: Color,
                             foreground: Color, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(rank == "1" ? Atlas.orange : Atlas.copper)
            Text("#\(rank)")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(foreground.opacity(0.65))
            Text(amount)
                .font(.system(size: rank == "1" ? 17 : 15, weight: .black, design: .rounded))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(12)
        .background(tone, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17)
            .strokeBorder(rank == "1" ? Atlas.orange.opacity(0.38) : Atlas.line))
    }

    private var communityStory: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                AtlasHeading(kicker: "04 / TOPLULUK", title: "Gündemde ne var?")
                Spacer()
                Button("Tümü") { newsOpen = true }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Atlas.blue)
            }
            if let item = latestStory {
                Button { newsOpen = true } label: {
                    HStack(spacing: 0) {
                        VStack(spacing: 0) {
                            Rectangle().fill(Atlas.copper).frame(width: 4)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 7) {
                                AtlasPill(title: item.category, symbol: "sparkle", highlighted: true)
                                Text(item.createdAt, style: .date)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Atlas.muted)
                            }
                            Text(item.title)
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(Atlas.ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(item.body)
                                .font(.system(size: 11))
                                .foregroundStyle(Atlas.muted)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            HStack(spacing: 6) {
                                Text("HABERİ OKU")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .tracking(0.7)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9, weight: .black))
                            }
                            .foregroundStyle(Atlas.copper)
                            .padding(.top, 2)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 17))
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                    .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Atlas.line))
                }
                .buttonStyle(.plain)
            } else {
                AtlasEmpty(title: "Yeni bir şeyler yolda",
                           detail: session.dataError ?? "Resmî duyuru ve etkinlikler burada yayınlanacak.",
                           symbol: "newspaper")
            }
        }
    }

    private var playerIdentity: some View {
        Button {
            select(4)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(Atlas.blueLight)
                    if let url = session.profile?.skinUrl {
                        AsyncImage(url: url) { image in image.resizable().scaledToFit() }
                            placeholder: { BlasterLogo(size: 36) }
                            .padding(4)
                    } else { BlasterLogo(size: 36) }
                }
                .frame(width: 51, height: 53)
                VStack(alignment: .leading, spacing: 4) {
                    Text("BLASTER ID")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .tracking(0.8)
                        .foregroundStyle(Atlas.copper)
                    Text(session.profile?.minecraftName ?? "Oyuncu hesabın")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                        .lineLimit(1)
                    Text(session.profile?.rank ?? "Profilini görüntüle")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Atlas.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 3) {
                    Text((session.profile?.credits ?? 0).formatted())
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                    Text("KREDİ")
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Atlas.copper)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Atlas.muted)
            }
            .padding(13)
            .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Atlas.line))
        }
        .buttonStyle(.plain)
    }

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Link(destination: URL(string: "https://blastermc.com")!) {
                Label("Web", systemImage: "globe")
            }
            Circle().fill(Atlas.line).frame(width: 3, height: 3)
            Link(destination: URL(string: "https://discord.blastermc.com")!) {
                Label("Discord", systemImage: "bubble.left.and.bubble.right")
            }
            Spacer()
            Text("REALM / 13")
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .tracking(0.7)
                .foregroundStyle(Atlas.muted.opacity(0.8))
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(Atlas.blue)
        .padding(.horizontal, 3)
        .padding(.top, 2)
    }
}

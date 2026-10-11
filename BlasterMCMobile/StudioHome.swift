import SwiftUI

/// Homepage rebuilt after on-device feedback: no absolute text overlay, no fixed-height title box.
struct StudioHomeView: View {
    @EnvironmentObject private var session: BlasterSession
    @ObservedObject var server: ServerStatusModel
    let open: (Int) -> Void
    let active: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var showNews = false
    @State private var copied = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 21) {
                masthead
                welcome
                serverCard
                myAccount
                explore
                seasonPreview
                community
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 32)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(StudioBackground())
        .sheet(isPresented: $showNews) { StudioNewsView().environmentObject(session) }
        .task(id: active && scenePhase == .active) {
            guard active && scenePhase == .active else { return }
            while !Task.isCancelled {
                await server.refresh()
                do { try await Task.sleep(for: .seconds(5)) }
                catch { break }
            }
        }
        .refreshable {
            async let s: Void = server.refresh()
            async let p: Void = session.reloadProfile()
            async let c: Void = session.reloadPublic()
            _ = await (s,p,c)
        }
        .preferredColorScheme(.light)
    }

    private var masthead: some View {
        HStack(spacing: 12) {
            BlasterLogo(size: 45)
            VStack(alignment: .leading, spacing: 3) {
                Text("BLASTERMC")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(Studio.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("OYUNCU MERKEZİ")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(Studio.gold)
            }
            Spacer(minLength: 8)
            Button {
                Studio.touch()
                showNews = true
            } label: {
                Image(systemName: "bell.badge")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Studio.ink)
                    .frame(width: 44, height: 44)
                    .background(Studio.paper, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Studio.line))
            }
            .buttonStyle(BlasterTapStyle())
            .accessibilityLabel("Blaster Haberler")
        }
    }

    // All copy is in natural vertical layout, with solid backing and explicit contrast.
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(Studio.sunlight).frame(width: 7, height: 7)
                Text("BLASTERMC  /  SKYBLOCK")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(1.0)
                    .foregroundStyle(Studio.sunlight)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Text("10.3")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Text("Oyuna yakın.\nDünyana bağlı.")
                .font(.system(size: 31, weight: .black, design: .rounded))
                .tracking(-0.9)
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 15)
                .padding(.bottom, 11)
            Text("Adan, hesabın, ödüllerin ve BlasterMC'deki tüm gelişmeler tek bir yerde.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.94))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 18)
            Button {
                Studio.touch()
                open(1)
            } label: {
                HStack(spacing: 9) {
                    Text("DÜNYAYI KEŞFET")
                        .font(.system(size: 12, weight: .black))
                        .tracking(0.35)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .black))
                }
                .foregroundStyle(Studio.ink)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(Studio.sunlight, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(BlasterTapStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(21)
        .background(
            LinearGradient(colors: [Studio.navy, Color(red: 0.13, green: 0.21, blue: 0.33)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Studio.sunlight.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    private var serverCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            StudioSection(kicker: "BLASTER NETWORK", title: "Sunucu şimdi")
            StudioPanel {
                HStack(spacing: 7) {
                    Circle()
                        .fill(!server.hasConfirmedStatus || server.isStale ? Color.orange :
                              (server.isOnline ? Color.green : Color.red))
                        .frame(width: 8, height: 8)
                    Text(server.statusText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Studio.ink)
                    Spacer()
                    Button {
                        Task { await server.refresh() }
                    } label: {
                        Label("Yenile", systemImage: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Studio.gold)
                    }
                    .buttonStyle(BlasterTapStyle())
                    .disabled(server.isLoading)
                }
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(server.hasConfirmedStatus ? server.onlinePlayers.formatted() : "—")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(Studio.ink)
                        .monospacedDigit()
                    Text(server.hasConfirmedStatus && server.maxPlayers > 0 ?
                         "/ \(server.maxPlayers.formatted()) oyuncu" : "çevrimiçi oyuncu")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Studio.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Divider().overlay(Studio.line)
                VStack(alignment: .leading, spacing: 11) {
                    Text("oyna.blastermc.com")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(Studio.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    StudioCTA(title: copied ? "Sunucu adresi kopyalandı" : "Sunucu IP adresini kopyala",
                              symbol: copied ? "checkmark" : "doc.on.doc") {
                        Studio.copy("oyna.blastermc.com")
                        copied = true
                    }
                }
                if let verified = server.lastSuccess {
                    Text("Son doğrulama: \(verified, style: .time)")
                        .font(.system(size: 10))
                        .foregroundStyle(Studio.secondary)
                }
            }
        }
    }

    private var myAccount: some View {
        VStack(alignment: .leading, spacing: 11) {
            StudioSection(kicker: "OYUNCU HESABI", title: "Senin merkezin")
            Button {
                Studio.touch()
                open(4)
            } label: {
                StudioPanel {
                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 13).fill(Studio.pale)
                            if let url = session.profile?.skinUrl {
                                AsyncImage(url: url) { image in image.resizable().scaledToFit() }
                                    placeholder: { BlasterLogo(size: 43) }
                                    .padding(5)
                            } else { BlasterLogo(size: 43) }
                        }
                        .frame(width: 58, height: 60)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.profile?.minecraftName ?? "Oyuncu")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Studio.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Text(session.profile?.rank ?? "BlasterMC oyuncusu")
                                .font(.system(size: 12))
                                .foregroundStyle(Studio.secondary)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Studio.gold)
                    }
                    Divider().overlay(Studio.line)
                    HStack {
                        Label("Blaster Cüzdanı", systemImage: "circle.hexagongrid.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Studio.secondary)
                        Spacer()
                        Text("\((session.profile?.credits ?? 0).formatted()) kredi")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Studio.ink)
                    }
                }
            }
            .buttonStyle(BlasterTapStyle())
        }
    }

    private var explore: some View {
        VStack(alignment: .leading, spacing: 11) {
            StudioSection(kicker: "KEŞFET", title: "BlasterMC evreni")
            HStack(spacing: 10) {
                destination("Dünya", subtitle: "SkyBlock ve lobi", symbol: "globe", index: 1)
                destination("Mağaza", subtitle: "VIP ve ürünler", symbol: "bag", index: 2)
            }
            HStack(spacing: 10) {
                destination("Sezon", subtitle: "₺5.000 büyük ödül", symbol: "trophy", index: 3)
                Button {
                    Studio.touch()
                    showNews = true
                } label: {
                    destinationBody("Haberler", subtitle: "Duyurular", symbol: "megaphone")
                }
                .buttonStyle(BlasterTapStyle())
            }
        }
    }

    private func destination(_ title: String, subtitle: String, symbol: String, index: Int) -> some View {
        Button {
            Studio.touch()
            open(index)
        } label: {
            destinationBody(title, subtitle: subtitle, symbol: symbol)
        }
        .buttonStyle(BlasterTapStyle())
    }

    private func destinationBody(_ title: String, subtitle: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Studio.gold)
                .frame(height: 25)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Studio.ink)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Studio.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 113, alignment: .leading)
        .padding(16)
        .background(Studio.paper, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Studio.line))
    }

    private var seasonPreview: some View {
        VStack(alignment: .leading, spacing: 11) {
            StudioSection(kicker: "SEZON ÖDÜLLERİ", title: "₺7.500 ödül havuzu")
            Button {
                Studio.touch()
                open(3)
            } label: {
                StudioPanel {
                    HStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 25))
                            .foregroundStyle(Studio.gold)
                            .frame(width: 40)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Zirvede yerini al")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Studio.ink)
                            Text("1. ₺5.000  •  2. ₺1.500  •  3. ₺1.000")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Studio.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "arrow.up.right").foregroundStyle(Studio.gold)
                    }
                }
            }
            .buttonStyle(BlasterTapStyle())
        }
    }

    private var community: some View {
        VStack(alignment: .leading, spacing: 11) {
            StudioSection(kicker: "TOPLULUK", title: "Blaster Haberler")
            if let first = (session.announcements + session.events)
                .sorted(by: { $0.createdAt > $1.createdAt }).first {
                Button { showNews = true } label: {
                    StudioPanel {
                        Text(first.category.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Studio.gold)
                        Text(first.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Studio.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(first.body)
                            .font(.system(size: 12))
                            .foregroundStyle(Studio.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                }
                .buttonStyle(BlasterTapStyle())
            } else {
                StudioEmpty(title: "Yeni haberler burada yayınlanacak",
                            detail: session.dataError ?? "Sunucu duyuruları bekleniyor.",
                            symbol: "megaphone.fill")
            }
        }
    }
}

import SwiftUI

struct V10HomeView: View {
    @ObservedObject var server: ServerStatusModel
    let navigate: (Int) -> Void
    let isSelected: Bool

    @EnvironmentObject private var session: BlasterSession
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("blaster.v10.journey.address") private var copiedAddress = false
    @AppStorage("blaster.v10.journey.world") private var visitedWorld = false
    @AppStorage("blaster.v10.journey.season") private var visitedSeason = false
    @State private var showNews = false
    @State private var copiedFeedback = false

    private var journeyCount: Int {
        [copiedAddress, visitedWorld, visitedSeason].filter { $0 }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    masthead
                    cinematicHero
                    accountRail
                    liveRealm
                    quickActions
                    explorerJourney
                    seasonSpotlight
                    latestSignal
                    endmark
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 35)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background(PremiumBackground())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showNews) {
                NewsView()
                    .environmentObject(session)
            }
            .task(id: isSelected && scenePhase == .active) {
                guard isSelected && scenePhase == .active else { return }
                while !Task.isCancelled {
                    await server.refresh()
                    do { try await Task.sleep(for: .seconds(3)) }
                    catch { break }
                }
            }
            .refreshable {
                async let s: Void = server.refresh()
                async let c: Void = session.reloadPublic()
                async let p: Void = session.reloadProfile()
                _ = await (s, c, p)
            }
        }
    }

    private var masthead: some View {
        HStack(spacing: 10) {
            BlasterLogo(size: 53)
            VStack(alignment: .leading, spacing: 2) {
                Text("BLASTERMC")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(V10.ink)
                Text("WORLD EXPERIENCE  /  V10")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(V10.gold)
            }
            Spacer(minLength: 6)
            Button {
                V10.tap()
                showNews = true
            } label: {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(V10.ink)
                    .frame(width: 44, height: 44)
                    .background(.white, in: Circle())
                    .overlay(Circle().strokeBorder(V10.line))
            }
            .accessibilityLabel("Haberler ve bildirim merkezi")
            Button {
                V10.tap()
                navigate(4)
            } label: {
                ZStack {
                    Circle().fill(V10.ink).frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .foregroundStyle(V10.bright)
                }
            }
            .accessibilityLabel("Oyuncu profilim")
        }
    }

    private var cinematicHero: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 29, style: .continuous)
                .fill(V10.ink)
            SkyWorldView()
                .opacity(0.68)
            LinearGradient(
                stops: [
                    .init(color: V10.ink.opacity(0.92), location: 0),
                    .init(color: V10.ink.opacity(0.56), location: 0.58),
                    .init(color: V10.ink.opacity(0.33), location: 1)
                ],
                startPoint: .leading, endPoint: .trailing)
            V10SparkField()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    V10Tag(text: "SEZON EVRENİ", symbol: "sparkles", dark: true)
                    Spacer()
                    Text("10.0")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(V10.bright)
                }
                Spacer(minLength: 14)
                Text("DÜNYA\nSENİNLE\nBAŞLAR.")
                    .font(.system(size: 39, weight: .black, design: .rounded))
                    .tracking(-1.3)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.77)
                    .lineLimit(3)
                Text("Gökyüzündeki maceran şimdi cebinde.\nOyuncu evrenini keşfet.")
                    .font(.system(size: 12, weight: .medium))
                    .lineSpacing(3)
                    .foregroundStyle(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 9) {
                    Button {
                        visitedWorld = true
                        V10.tap()
                        navigate(1)
                    } label: {
                        Label("DÜNYAYI KEŞFET", systemImage: "arrow.up.right")
                            .font(.system(size: 11, weight: .black))
                            .tracking(0.2)
                            .foregroundStyle(V10.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [V10.bright, BlasterTheme.cream],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: Capsule())
                    }
                    .buttonStyle(BlasterTapStyle())
                    ShareLink(item: "oyna.blastermc.com") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 43, height: 43)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                }
            }
            .padding(24)
        }
        .frame(height: 354)
        .clipShape(RoundedRectangle(cornerRadius: 29))
        .overlay(RoundedRectangle(cornerRadius: 29)
            .strokeBorder(V10.bright.opacity(0.38), lineWidth: 1))
        .shadow(color: V10.ink.opacity(0.20), radius: 24, y: 12)
    }

    private var accountRail: some View {
        Button {
            V10.tap()
            navigate(4)
        } label: {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(V10.gold.opacity(0.11))
                    if let skin = session.profile?.skinUrl {
                        AsyncImage(url: skin) { image in
                            image.resizable().scaledToFit()
                        } placeholder: { BlasterLogo(size: 37) }
                        .padding(5)
                    } else {
                        BlasterLogo(size: 37)
                    }
                }
                .frame(width: 55, height: 55)
                VStack(alignment: .leading, spacing: 4) {
                    Text("HOŞ GELDİN,")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.4)
                        .foregroundStyle(V10.gold)
                    Text(session.profile?.minecraftName ?? "Oyuncu")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(V10.ink)
                        .lineLimit(1)
                    Text(session.profile?.rank ?? "Oyuncu profili")
                        .font(.caption2)
                        .foregroundStyle(BlasterTheme.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 2)
                VStack(alignment: .trailing, spacing: 3) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundStyle(V10.gold)
                    Text((session.profile?.credits ?? 0).formatted())
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(V10.ink)
                    Text("KREDİ")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1)
                        .foregroundStyle(BlasterTheme.muted)
                }
            }
        }
        .buttonStyle(BlasterTapStyle())
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).strokeBorder(V10.line))
        .accessibilityLabel("Oyuncu profilim ve gerçek kredi bakiyem")
    }

    private var liveRealm: some View {
        VStack(alignment: .leading, spacing: 13) {
            V10Heading(eyebrow: "LIVE / BLASTER NETWORK",
                       title: "Dünya şu anda",
                       detail: "Oyun sunucusundan doğrulanan canlı durum")
            V10Plate(dark: true) {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Label("SKYBLOCK • NETWORK", systemImage: "server.rack")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1)
                            .foregroundStyle(BlasterTheme.cream)
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(!server.hasConfirmedStatus || server.isStale ? .orange :
                                      (server.isOnline ? .green : .red))
                                .frame(width: 7, height: 7)
                            Text(server.statusText)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                    V10Divider()
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text(server.hasConfirmedStatus ? server.onlinePlayers.formatted() : "—")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text(server.hasConfirmedStatus && server.maxPlayers > 0 ?
                             "/ \(server.maxPlayers.formatted()) çevrimiçi oyuncu" :
                             "oyuncu durumu")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer(minLength: 0)
                    }
                    Text(server.errorMessage ??
                         (server.isOnline ? "Macera devam ediyor. Sen de katıl!" :
                          "Sunucunun güncel durumunu yukarıdan takip et."))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 12) {
                        Button {
                            V10.copy("oyna.blastermc.com")
                            copiedAddress = true
                            copiedFeedback = true
                        } label: {
                            Label(copiedFeedback ? "KOPYALANDI" : "IP ADRESİNİ KOPYALA",
                                  systemImage: copiedFeedback ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(V10.ink)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(V10.bright, in: Capsule())
                        }
                        .buttonStyle(BlasterTapStyle())
                        Button {
                            Task { await server.refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 39, height: 39)
                                .background(.white.opacity(0.13), in: Circle())
                        }
                        .disabled(server.isLoading)
                        .accessibilityLabel("Durumu yenile")
                        Spacer(minLength: 0)
                    }
                    if let verified = server.lastSuccess {
                        Text("Son doğrulama \(verified, style: .time) • \(server.sourceName)")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 13) {
            V10Heading(eyebrow: "EXPLORE / WORLD MAP",
                       title: "Macera portalın",
                       detail: "Sana ait tüm BlasterMC alanları")
            HStack(spacing: 10) {
                V10SquareAction(title: "Dünya", detail: "SkyBlock rehberi", symbol: "globe.europe.africa.fill") {
                    visitedWorld = true
                    navigate(1)
                }
                V10SquareAction(title: "Mağaza", detail: "VIP & koleksiyon", symbol: "bag.fill") {
                    navigate(2)
                }
            }
            HStack(spacing: 10) {
                V10SquareAction(title: "Sezon", detail: "Sıralama & ödüller", symbol: "trophy.fill") {
                    visitedSeason = true
                    navigate(3)
                }
                V10SquareAction(title: "Profil", detail: "Blaster ID & cüzdan", symbol: "person.crop.square") {
                    navigate(4)
                }
            }
        }
    }

    private var explorerJourney: some View {
        VStack(alignment: .leading, spacing: 12) {
            V10Heading(eyebrow: "PERSONAL / DEVICE JOURNEY",
                       title: "Keşif rotan",
                       detail: "Bu iPhone'da tamamladığın keşif adımları • Oyun ödülü içermez")
            V10Plate {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("DÜNYANI TANIMAYA BAŞLA")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1)
                            .foregroundStyle(V10.ink)
                        Spacer()
                        Text("\(journeyCount)/3")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundStyle(V10.gold)
                    }
                    V10ProgressBar(progress: Double(journeyCount)/3)
                    journeyRow("Sunucu adresini kopyala", done: copiedAddress, symbol: "doc.on.doc") {
                        copiedAddress = true
                        V10.copy("oyna.blastermc.com")
                    }
                    journeyRow("Dünyayı keşfet", done: visitedWorld, symbol: "globe") {
                        visitedWorld = true
                        navigate(1)
                    }
                    journeyRow("Sezon arenasına göz at", done: visitedSeason, symbol: "crown") {
                        visitedSeason = true
                        navigate(3)
                    }
                    if journeyCount == 3 {
                        Label("Keşif rotası tamamlandı!", systemImage: "checkmark.seal.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(V10.gold)
                    }
                }
            }
        }
    }

    private func journeyRow(_ title: String, done: Bool, symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            V10.tap()
            action()
        } label: {
            HStack(spacing: 11) {
                Image(systemName: done ? "checkmark.circle.fill" : symbol)
                    .font(.system(size: 17))
                    .foregroundStyle(done ? V10.gold : V10.ink.opacity(0.7))
                    .frame(width: 30)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(V10.ink)
                    .lineLimit(1)
                Spacer()
                Image(systemName: done ? "checkmark" : "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(V10.gold)
            }
        }
        .buttonStyle(BlasterTapStyle())
    }

    private var seasonSpotlight: some View {
        VStack(alignment: .leading, spacing: 13) {
            V10Heading(eyebrow: "ARENA / SEASON",
                       title: "Zirveye yolculuk",
                       detail: "Gerçek SkyBlock liderlik tablosu")
            Button {
                visitedSeason = true
                V10.tap()
                navigate(3)
            } label: {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 24).fill(
                        LinearGradient(colors: [V10.ink, Color(red: 0.41, green: 0.29, blue: 0.22)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                    V10SparkField()
                    HStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 35))
                            .foregroundStyle(V10.bright)
                            .frame(width: 68, height: 74)
                            .background(.white.opacity(0.10),
                                        in: RoundedRectangle(cornerRadius: 17))
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SEZON ARENASI")
                                .font(.system(size: 10, weight: .black))
                                .tracking(1.7)
                                .foregroundStyle(V10.bright)
                            Text(session.season?.rankings?.first?.ownerUsername ??
                                 session.season?.title ?? "SkyBlock sezonu")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text(session.season?.rankings?.first.map {
                                "Lider • \($0.islandValue.formatted()) ada değeri"
                            } ?? "Canlı sıralamayı ve ödülleri keşfet")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.76))
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(V10.bright)
                    }
                    .padding(18)
                }
                .frame(minHeight: 112)
            }
            .buttonStyle(BlasterTapStyle())
        }
    }

    private var latestSignal: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                V10Heading(eyebrow: "NEWSROOM / LIVE",
                           title: "Evrenin nabzı",
                           detail: "BlasterMC duyuruları ve etkinlikleri")
                Spacer()
                Button {
                    showNews = true
                } label: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(V10.gold)
                        .padding(12)
                        .background(.white, in: Circle())
                }
                .accessibilityLabel("Tüm haberler")
            }
            if let first = (session.announcements + session.events)
                .sorted(by: { $0.createdAt > $1.createdAt }).first {
                Button { showNews = true } label: {
                    V10Plate {
                        VStack(alignment: .leading, spacing: 9) {
                            V10Tag(text: first.category, symbol: "bolt.fill")
                            Text(first.title)
                                .font(.system(size: 19, weight: .black, design: .rounded))
                                .foregroundStyle(V10.ink)
                                .multilineTextAlignment(.leading)
                            Text(first.body)
                                .font(.subheadline)
                                .lineLimit(3)
                                .foregroundStyle(BlasterTheme.muted)
                                .multilineTextAlignment(.leading)
                            Text(first.createdAt, style: .date)
                                .font(.caption2)
                                .foregroundStyle(V10.gold)
                        }
                    }
                }
                .buttonStyle(BlasterTapStyle())
            } else {
                V10Plate {
                    Label("Henüz yeni duyuru yok", systemImage: "sparkles")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(V10.ink)
                    Text(session.dataError ?? "Sunucu duyuruları geldikçe burada yayınlanır.")
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                }
            }
        }
    }

    private var endmark: some View {
        HStack(spacing: 8) {
            BlasterLogo(size: 28)
            Text("BLASTERMC  •  WORLD EXPERIENCE 10")
                .font(.system(size: 9, weight: .black))
                .tracking(1.2)
                .foregroundStyle(BlasterTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

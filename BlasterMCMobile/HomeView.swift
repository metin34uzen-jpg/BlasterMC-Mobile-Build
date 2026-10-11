import SwiftUI

struct HomeView: View {
    @ObservedObject var server: ServerStatusModel
    let navigate: (Int) -> Void
    let isSelected: Bool
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var session: BlasterSession
    @State private var animate = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    topBar
                    hero
                    playerWelcome
                    status
                    shortcuts
                    seasonSpotlight
                    storeSpotlight
                    latest
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
            .background(PremiumBackground())
            .toolbar(.hidden, for: .navigationBar)
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
                async let n: Void = session.reloadPublic()
                _ = await (s,n)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            BlasterLogo(size: 54)
            VStack(alignment: .leading, spacing: 3) {
                Text("BLASTERMC")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(BlasterTheme.ink)
                Text("OYUNCU EVRENİ")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.1)
                    .foregroundStyle(BlasterTheme.gold)
            }
            Spacer()
            Button {
                navigate(4)
            } label: {
                Image(systemName: "bell.badge")
                    .font(.title3)
                    .foregroundStyle(BlasterTheme.navy)
                    .frame(width: 44, height: 44)
                    .background(BlasterTheme.paper, in: Circle())
            }
            .accessibilityLabel("Haberler ve bildirimler")
        }
        .padding(.top, 16)
    }

    private var hero: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [BlasterTheme.navy,
                    Color(red: 0.16, green: 0.27, blue: 0.44),
                    Color(red: 0.30, green: 0.36, blue: 0.43)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))

            SkyWorldView()
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(alignment: .trailing) {
                    BlasterLogo(size: 68)
                        .rotationEffect(.degrees(-10))
                        .shadow(color: BlasterTheme.gold.opacity(0.35), radius: 20)
                        .offset(x: -27, y: -58)
                }

            VStack(alignment: .leading, spacing: 12) {
                Text("✦  BLASTERMC MOBILE")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(BlasterTheme.amber)
                Text("Yeni bir\nmacera seni\nbekliyor.")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(-1.2)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Gökyüzündeki adandan tüm dünyaya.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.83))
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    navigate(3)
                } label: {
                    Label("SEZONU KEŞFET", systemImage: "arrow.up.right")
                        .font(.system(size: 12, weight: .black))
                        .tracking(0.5)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .foregroundStyle(BlasterTheme.navy)
                        .background(BlasterTheme.amber, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(25)
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: BlasterTheme.navy.opacity(0.20), radius: 20, y: 12)
        .onAppear { animate = true }
    }

    private var playerWelcome: some View {
        BlasterCard {
            HStack(spacing: 13) {
                if let skin = session.profile?.skinUrl {
                    AsyncImage(url: skin) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Image(systemName: "person.crop.square")
                            .foregroundStyle(BlasterTheme.gold)
                    }
                    .frame(width: 52, height: 52)
                    .background(BlasterTheme.cream, in: RoundedRectangle(cornerRadius: 12))
                } else {
                    BlasterLogo(size: 52)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("HOŞ GELDİN")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.8)
                        .foregroundStyle(BlasterTheme.gold)
                    Text(session.profile?.minecraftName ?? "Oyuncu")
                        .font(.headline.weight(.heavy))
                        .lineLimit(1)
                    Text(session.profile?.rank ?? "")
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundStyle(BlasterTheme.gold)
                    Text("\(session.profile?.credits ?? 0)")
                        .font(.title3.weight(.black))
                        .foregroundStyle(BlasterTheme.ink)
                    Text("KREDİ").font(.system(size: 9, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(BlasterTheme.muted)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { navigate(1) }
            .accessibilityLabel("Profilim ve kredi bakiyem")
        }
    }

    private var status: some View {
        BlasterCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Label("CANLI SUNUCU", systemImage: "server.rack")
                        .font(.caption.weight(.heavy))
                        .tracking(1)
                    Spacer()
                    HStack(spacing: 7) {
                        Circle()
                            .fill(server.isStale ? Color.orange : (server.isOnline ? Color.green : Color.red))
                            .frame(width: 8, height: 8)
                            .scaleEffect(animate ? 1.18 : 0.82)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
                        Text(server.statusText.uppercased())
                            .font(.caption2.weight(.bold))
                    }
                }
                .foregroundStyle(BlasterTheme.navy)
                HStack(alignment: .firstTextBaseline) {
                    Text(server.hasConfirmedStatus ? "\(server.onlinePlayers)" : "—")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(BlasterTheme.ink)
                    Text(server.hasConfirmedStatus ? "/ \(server.maxPlayers) oyuncu" : "oyuncu durumu")
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                }
                Text(server.errorMessage ??
                    (server.isOnline ? "Oyuncular şu an BlasterMC dünyasında!" : "Sunucu şu anda çevrimdışı görünüyor."))
                    .font(.subheadline)
                    .foregroundStyle(BlasterTheme.muted)
                if let last = server.lastSuccess {
                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                        Text("Son doğrulama: \(last, style: .time) • 3 sn otomatik yenileme")
                    }
                    .font(.caption2)
                    .foregroundStyle(BlasterTheme.muted)
                }
                HStack {
                    Text("oyna.blastermc.com")
                        .font(.caption.monospaced())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 8)
                    ShareLink(item: "oyna.blastermc.com") {
                        Image(systemName: "square.on.square")
                    }
                    Button {
                        Task { await server.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(server.isLoading)
                }
                .foregroundStyle(BlasterTheme.gold)
            }
        }
    }

    private var shortcuts: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(title: "Senin dünyan", caption: "Her şey tek bir yerde")
            HStack(spacing: 12) {
                tile("Profilim", symbol: "person.crop.circle.fill", subtitle: "Oyuncu merkezi", tab: 1)
                tile("Mağaza", symbol: "shippingbox.fill", subtitle: "VIP ve ürünler", tab: 2)
            }
            HStack(spacing: 12) {
                tile("Sezon", symbol: "trophy.fill", subtitle: "Ödüller", tab: 3)
                tile("Haberler", symbol: "sparkles", subtitle: "Etkinlikler", tab: 4)
            }
        }
    }

    private func tile(_ name: String, symbol: String, subtitle: String, tab: Int) -> some View {
        Button { navigate(tab) } label: {
            VStack(alignment: .leading, spacing: 13) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(BlasterTheme.gold)
                    .frame(width: 38, height: 38)
                    .background(BlasterTheme.amber.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                Text(name).font(.headline).foregroundStyle(BlasterTheme.ink)
                Text(subtitle).font(.caption).foregroundStyle(BlasterTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(17)
            .background(BlasterTheme.paper, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(BlasterTapStyle())
    }

    private var seasonSpotlight: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Sezonun zirvesi", caption: "Canlı SkyBlock rekabeti")
            Button { navigate(3) } label: {
                HStack(spacing: 15) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 35))
                        .foregroundStyle(BlasterTheme.amber)
                        .frame(width: 70, height: 77)
                        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SEZON ARENASI")
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(BlasterTheme.amber)
                        if let first = session.season?.rankings?.first {
                            Text(first.ownerUsername)
                                .font(.title3.weight(.black))
                                .foregroundStyle(.white)
                            Text("Zirvede • \(first.islandValue.formatted()) ada değeri")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.80))
                        } else {
                            Text(session.season?.title ?? "BlasterMC Sezonu")
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text("Sıralamayı ve sezon takvimini incele")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.80))
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(BlasterTheme.amber)
                }
                .padding(18)
                .background(LinearGradient(colors: [
                    BlasterTheme.navy,
                    Color(red: 0.36, green: 0.27, blue: 0.20)
                ], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 22))
            }
            .buttonStyle(BlasterTapStyle())
        }
    }

    private var storeSpotlight: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Mağaza vitrini", caption: "Blaster Market'ten seçilen içerikler")
            if session.products.isEmpty {
                BlasterCard {
                    HStack(spacing: 13) {
                        Image(systemName: "shippingbox.fill")
                            .font(.title2)
                            .foregroundStyle(BlasterTheme.gold)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Mağaza kataloğu yenileniyor")
                                .font(.headline)
                            Text("Güncel VIP ve ürünler burada görünecek.")
                                .font(.caption)
                                .foregroundStyle(BlasterTheme.muted)
                        }
                        Spacer()
                    }
                }
            } else {
                ForEach(Array(session.products.prefix(2))) { product in
                    Button { navigate(2) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "gift.fill")
                                .font(.title2)
                                .foregroundStyle(BlasterTheme.gold)
                                .frame(width: 46, height: 46)
                                .background(BlasterTheme.cream, in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(product.name)
                                    .font(.headline)
                                    .foregroundStyle(BlasterTheme.ink)
                                Text(product.category.uppercased())
                                    .font(.caption2.bold())
                                    .foregroundStyle(BlasterTheme.muted)
                            }
                            Spacer()
                            Text(product.priceCredits.map { "\($0.formatted()) kredi" } ?? "Mağazada")
                                .font(.caption.weight(.black))
                                .foregroundStyle(BlasterTheme.gold)
                        }
                        .padding(16)
                        .background(BlasterTheme.paper, in: RoundedRectangle(cornerRadius: 19))
                    }
                    .buttonStyle(BlasterTapStyle())
                }
            }
        }
    }

    private var latest: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "BlasterMC gündemi", caption: "En yeni haber ve etkinlikler")
            if let announcement = session.announcements.first {
                BlasterCard {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(announcement.title).font(.headline)
                        Text(announcement.body).font(.subheadline).foregroundStyle(BlasterTheme.muted)
                            .lineLimit(3)
                        Button("Tüm haberleri gör") { navigate(4) }
                            .font(.caption.bold())
                            .foregroundStyle(BlasterTheme.gold)
                    }
                }
            } else {
                NoticePlaceholder(
                    symbol: "sparkles.rectangle.stack",
                    title: "Haber akışı hazırlanıyor",
                    message: session.dataError ?? "Duyurular mobil API bağlandığında burada görüntülenecek."
                )
            }
        }
    }
}

private struct VoxelBlock: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [BlasterTheme.amber, BlasterTheme.gold],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 102, height: 102)
                .rotationEffect(.degrees(45))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.white.opacity(0.34), lineWidth: 3)
                        .frame(width: 102, height: 102)
                        .rotationEffect(.degrees(45))
                }
            BlasterLogo(size: 82)
        }
        .shadow(color: BlasterTheme.amber.opacity(0.4), radius: 25)
    }
}

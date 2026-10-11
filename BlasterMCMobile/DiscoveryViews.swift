import SwiftUI
import UserNotifications

struct StoreView: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var category = "Tümü"

    private var categories: [String] {
        ["Tümü"] + Array(Set(session.products.map(\.category))).sorted()
    }

    private var visibleProducts: [StoreProduct] {
        category == "Tümü" ? session.products :
            session.products.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    PremiumBanner(
                        eyebrow: "✦  BLASTERMC / MARKET",
                        title: "Efsaneler\nburada güçlenir.",
                        subtitle: "VIP rütbeleri, oyun içi içerikler ve özel koleksiyonlar.",
                        symbol: "shippingbox.fill"
                    )
                    walletStrip
                    HStack {
                        SectionHeader(title: "Mağaza koleksiyonu", caption: "Gerçek ürünler, güncel kredi fiyatları")
                        Spacer()
                        Image(systemName: "square.grid.2x2.fill")
                            .foregroundStyle(BlasterTheme.gold)
                    }
                    if !session.products.isEmpty {
                        categoryChips
                        ForEach(visibleProducts) { product in
                            StoreProductCard(product: product)
                        }
                    } else {
                        NoticePlaceholder(
                            symbol: "shippingbox.fill",
                            title: "Koleksiyon güncelleniyor",
                            message: session.dataError ?? "Mağazanın doğrulanmış ürünleri hazırlanıyor."
                        )
                    }
                    GoldButton(title: "KATALOĞU YENİLE", symbol: "arrow.clockwise") {
                        Task { await session.reloadPublic() }
                    }
                    BlasterCard {
                        Label("Güvenli alışveriş", systemImage: "checkmark.shield")
                            .font(.headline)
                        Text("Ürünleri burada inceleyebilirsin. Doğrulanmış satın alma ve oyun içi teslimat API'si etkinleştirilmeden mobil ödeme işlemi yapılmaz.")
                            .font(.caption)
                            .foregroundStyle(BlasterTheme.muted)
                    }
                }
                .padding(18)
                .padding(.bottom, 25)
            }
            .background(PremiumBackground())
            .navigationTitle("Blaster Market")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await session.reloadPublic() }
        }
    }

    private var walletStrip: some View {
        HStack(spacing: 13) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.title2)
                .foregroundStyle(BlasterTheme.gold)
            VStack(alignment: .leading, spacing: 3) {
                Text("BLASTER CÜZDANI")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(BlasterTheme.muted)
                Text((session.profile?.credits ?? 0).formatted() + " kredi")
                    .font(.title3.weight(.black))
                    .foregroundStyle(BlasterTheme.navy)
            }
            Spacer()
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(BlasterTheme.gold)
        }
        .padding(19)
        .background(BlasterTheme.paper, in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19)
            .strokeBorder(BlasterTheme.gold.opacity(0.30), lineWidth: 1))
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(categories, id: \.self) { item in
                    Button { withAnimation(.easeInOut(duration: 0.2)) { category = item } } label: {
                        Text(item)
                            .font(.caption.weight(.heavy))
                            .padding(.horizontal, 17)
                            .padding(.vertical, 11)
                            .foregroundStyle(category == item ? BlasterTheme.cream : BlasterTheme.ink)
                            .background(category == item ? BlasterTheme.navy : BlasterTheme.paper,
                                        in: Capsule())
                            .overlay(Capsule().strokeBorder(
                                BlasterTheme.gold.opacity(category == item ? 0.6 : 0.13),
                                lineWidth: 1))
                    }
                    .buttonStyle(BlasterTapStyle())
                }
            }
        }
    }
}

private struct StoreProductCard: View {
    let product: StoreProduct

    var body: some View {
        BlasterCard {
            HStack(alignment: .top, spacing: 16) {
                productArt
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.category.uppercased())
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.4)
                        .foregroundStyle(BlasterTheme.gold)
                    Text(product.name)
                        .font(.title3.weight(.black))
                        .foregroundStyle(BlasterTheme.ink)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                        .lineLimit(3)
                    HStack(spacing: 6) {
                        Image(systemName: "circle.hexagongrid.fill")
                        Text(product.priceCredits.map { "\($0.formatted()) kredi" } ?? "Fiyat açıklanmadı")
                    }
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(BlasterTheme.gold)
                    .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var productArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17)
                .fill(LinearGradient(colors: [
                    BlasterTheme.cream,
                    Color(red: 0.97, green: 0.85, blue: 0.67)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
            if let imageURL = product.imageUrl {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 33))
                        .foregroundStyle(BlasterTheme.gold)
                }
                .padding(8)
            } else {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 33))
                    .foregroundStyle(BlasterTheme.gold)
            }
        }
        .frame(width: 92, height: 103)
        .overlay(RoundedRectangle(cornerRadius: 17)
            .strokeBorder(BlasterTheme.gold.opacity(0.24), lineWidth: 1))
    }
}

struct SeasonView: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var ambient = false
    @State private var rankingSearch = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    seasonHero
                    topRankings
                    seasonJourney
                    rewardSection
                    footer
                }
                .padding(18)
            }
            .background(BlasterTheme.canvas)
            .navigationTitle("Sezon Arenası")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await session.reloadSeason() }
            .task { await session.reloadSeason() }
        }
    }

    private var seasonHero: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 29)
                .fill(LinearGradient(colors: [
                    BlasterTheme.navy,
                    Color(red: 0.23, green: 0.22, blue: 0.28),
                    Color(red: 0.45, green: 0.28, blue: 0.13)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))

            GeometryReader { geo in
                ZStack(alignment: .trailing) {
                    Circle()
                        .fill(BlasterTheme.amber.opacity(0.14))
                        .frame(width: 220, height: 220)
                        .blur(radius: 45)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 110, weight: .thin))
                        .rotationEffect(.degrees(-12))
                        .foregroundStyle(BlasterTheme.amber.opacity(0.25))
                        .shadow(color: BlasterTheme.amber.opacity(0.21), radius: 18)
                        .offset(x: ambient ? 25 : 37, y: ambient ? -14 : 10)
                    ForEach(0..<9, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: CGFloat(6 + (i%3)*4)))
                            .foregroundStyle(BlasterTheme.amber.opacity(i.isMultiple(of: 2) ? 0.65 : 0.28))
                            .offset(x: CGFloat((i*29)%130)-20,
                                    y: CGFloat((i*31)%180)-70+(ambient ? -5 : 8))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: ambient)
            }
            .clipped()

            VStack(alignment: .leading, spacing: 13) {
                Text("✦  BLASTERMC / SKYBLOCK")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2.0)
                    .foregroundStyle(BlasterTheme.amber)

                Text(session.season?.title ?? "Sezon\nArenası")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .tracking(-1)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 50)

                Text(session.season?.subtitle ?? "Adanı geliştir, zirveye ulaş ve sezon hedeflerini takip et.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)

                Label(session.season?.endsAtLabel ?? "Bitiş tarihi henüz duyurulmadı",
                      systemImage: "calendar.badge.clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BlasterTheme.cream)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            .padding(23)
        }
        .frame(minHeight: 280)
        .clipShape(RoundedRectangle(cornerRadius: 29))
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                ambient = true
            }
        }
    }

    private var topRankings: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(title: "Zirve mücadelesi", caption: "Gerçek ada değerleri ve oyuncu sıralaması")
            if let rankings = session.season?.rankings, !rankings.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(V10.gold)
                    TextField("Oyuncu veya ada ara", text: $rankingSearch)
                        .font(.subheadline)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !rankingSearch.isEmpty {
                        Button {
                            rankingSearch = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(BlasterTheme.muted)
                        }
                    }
                }
                .padding(14)
                .background(BlasterTheme.paper, in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(V10.line))
                let matching = rankings.filter {
                    rankingSearch.isEmpty ||
                    $0.ownerUsername.localizedStandardContains(rankingSearch) ||
                    $0.islandName.localizedStandardContains(rankingSearch)
                }
                if matching.isEmpty {
                    NoticePlaceholder(symbol: "magnifyingglass",
                                      title: "Oyuncu bulunamadı",
                                      message: "Başka bir oyuncu veya ada adı ara.")
                } else {
                    ForEach(matching) { rank in
                        rankRow(rank, isPodium: rank.rankPosition <= 3)
                    }
                }
                if let updated = session.season?.updatedAt {
                    Label("Son senkronizasyon: \(updated, style: .relative)",
                          systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                        .foregroundStyle(BlasterTheme.muted)
                }
            } else {
                NoticePlaceholder(
                    symbol: "chart.bar.xaxis",
                    title: "Sezon sıralaması",
                    message: "Sunucudan doğrulanmış ada sıralamaları bekleniyor. Oyuncu adı veya puan uydurulmuyor."
                )
            }
        }
    }

    private func rankRow(_ rank: SeasonRanking, isPodium: Bool) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPodium ? BlasterTheme.cream : BlasterTheme.canvas)
                Text("#\(rank.rankPosition)")
                    .font(.headline.weight(.black))
                    .foregroundStyle(BlasterTheme.gold)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 5) {
                Text(rank.ownerUsername)
                    .font(.headline)
                    .foregroundStyle(BlasterTheme.ink)
                Text(rank.islandName)
                    .font(.caption)
                    .foregroundStyle(BlasterTheme.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 4) {
                Text(rank.islandValue.formatted())
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(BlasterTheme.navy)
                Text("ADA DEĞERİ")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(0.9)
                    .foregroundStyle(BlasterTheme.gold)
            }
        }
        .padding(14)
        .background(BlasterTheme.paper, in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19)
            .strokeBorder(BlasterTheme.gold.opacity(isPodium ? 0.29 : 0.08), lineWidth: 1))
    }

    private var seasonJourney: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(title: "Sezon yolculuğu", caption: "Duyurulan resmî takvim")
            if let items = session.season?.milestones, !items.isEmpty {
                BlasterCard {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top, spacing: 13) {
                                ZStack {
                                    Circle()
                                        .fill(BlasterTheme.amber.opacity(0.18))
                                    Image(systemName: index == 0 ? "flag.checkered" : "diamond.fill")
                                        .font(.caption)
                                        .foregroundStyle(BlasterTheme.gold)
                                }
                                .frame(width: 35, height: 35)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title).font(.subheadline.bold())
                                    Text((item.date?.isEmpty == false) ? (item.date ?? "") : "Tarih henüz açıklanmadı")
                                        .font(.caption)
                                        .foregroundStyle(BlasterTheme.muted)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            } else {
                BlasterCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Label("Sezon başlangıcı", systemImage: "flag.fill")
                        Label("Sıralama mücadelesi", systemImage: "chart.bar.fill")
                        Label("Kesin sonuçlar", systemImage: "rosette")
                        Label("Ödül teslimi", systemImage: "gift.fill")
                    }
                    .font(.subheadline)
                    .foregroundStyle(BlasterTheme.ink)
                    Text("Resmî tarihler web sitesi API'sinden alınacak.")
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                }
            }
        }
    }

    private var rewardSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(title: "Sezon ödülleri", caption: "Duyurulan ödüller ve kazanımlar")
            if let rewards = session.season?.rewards, !rewards.isEmpty {
                ForEach(rewards) { reward in
                    BlasterCard {
                        Label(reward.title, systemImage: "gift.fill")
                            .font(.headline)
                            .foregroundStyle(BlasterTheme.gold)
                        Text(reward.description)
                            .font(.subheadline)
                            .foregroundStyle(BlasterTheme.muted)
                        if reward.isClaimed == true {
                            Label("Alındı", systemImage: "checkmark.seal.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                    }
                }
            } else {
                NoticePlaceholder(
                    symbol: "gift.fill",
                    title: "Ödüller henüz yayınlanmadı",
                    message: "Ödül bilgileri açıklanınca burada listelenecek. Gerçek olmayan ödül veya kazanım gösterilmiyor."
                )
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 9) {
            if let error = session.dataError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(BlasterTheme.muted)
                    .multilineTextAlignment(.center)
            }
            GoldButton(title: "SEZON BİLGİLERİNİ YENİLE", symbol: "arrow.clockwise") {
                Task { await session.reloadSeason() }
            }
        }
    }
}

struct NewsView: View {
    @EnvironmentObject private var session: BlasterSession
    @StateObject private var push = PushCoordinator.shared
    @State private var selectedFeed = 0
    @State private var search = ""
    @State private var savedOnly = false
    @AppStorage("blaster.v10.news.saved") private var savedIDs = ""

    private var saved: Set<Int> {
        Set(savedIDs.split(separator: ",").compactMap { Int($0) })
    }

    private var items: [MobileNotice] {
        let base: [MobileNotice]
        switch selectedFeed {
        case 1: base = session.announcements
        case 2: base = session.events
        default: base = session.announcements + session.events
        }
        return base.filter {
            (!savedOnly || saved.contains($0.id)) &&
            (search.isEmpty || $0.title.localizedStandardContains(search) ||
             $0.body.localizedStandardContains(search))
        }.sorted { $0.createdAt > $1.createdAt }
    }

    private func toggleSaved(_ id: Int) {
        var ids = saved
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        savedIDs = ids.sorted().map(String.init).joined(separator: ",")
        V10.tap()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PremiumBanner(
                        eyebrow: "✦  BLASTERMC / NEWSROOM",
                        title: "Dünyandaki\nher gelişme.",
                        subtitle: "Güncel haberler, sezon duyuruları ve topluluk etkinlikleri.",
                        symbol: "bell.badge.fill"
                    )
                    notificationStatus
                    HStack {
                        SectionHeader(title: "BlasterMC gündemi", caption: "Sunucudan gelen doğrulanmış içerikler")
                        Spacer()
                        Text("\(session.announcements.count + session.events.count)")
                            .font(.title3.weight(.black))
                            .foregroundStyle(BlasterTheme.gold)
                    }
                    feedPicker
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(V10.gold)
                        TextField("Haberlerde ara", text: $search)
                            .font(.subheadline)
                        Button {
                            savedOnly.toggle()
                        } label: {
                            Label("Kaydettiklerim", systemImage: savedOnly ? "bookmark.fill" : "bookmark")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(V10.gold)
                        }
                    }
                    .padding(14)
                    .background(BlasterTheme.paper, in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(V10.line))
                    if items.isEmpty {
                        NoticePlaceholder(
                            symbol: "newspaper.fill",
                            title: "Bu alanda henüz haber yok",
                            message: session.dataError ?? "Yeni içerikler yayınlandığında burada görüntülenecek."
                        )
                    } else {
                        ForEach(items) { notice in
                            NewsItemCard(notice: notice, isSaved: saved.contains(notice.id)) {
                                toggleSaved(notice.id)
                            }
                        }
                    }
                    GoldButton(title: "DUYURULARI YENİLE", symbol: "arrow.clockwise") {
                        Task { await session.reloadPublic() }
                    }
                }
                .padding(18)
                .padding(.bottom, 28)
            }
            .background(PremiumBackground())
            .navigationTitle("Blaster Haberler")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await session.reloadPublic() }
            .task { await push.refreshPermissionStatus() }
        }
    }

    private var feedPicker: some View {
        HStack(spacing: 9) {
            ForEach(Array(["Tümü", "Duyurular", "Etkinlikler"].enumerated()), id: \.offset) { index, name in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { selectedFeed = index }
                } label: {
                    Text(name)
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(selectedFeed == index ? BlasterTheme.cream : BlasterTheme.ink)
                        .background(selectedFeed == index ? BlasterTheme.navy : BlasterTheme.paper,
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(BlasterTapStyle())
            }
        }
    }

    private var notificationStatus: some View {
        BlasterCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 11) {
                    Image(systemName: "bell.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(BlasterTheme.gold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bildirim Merkezi")
                            .font(.headline)
                        Text("İzin ve teslimat durumlarını ayrı takip et")
                            .font(.caption)
                            .foregroundStyle(BlasterTheme.muted)
                    }
                }
                Divider()
                statusLine("iPhone bildirim izni",
                           value: push.permissionDescription,
                           symbol: push.permissionGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                statusLine("Uzaktan APNs",
                           value: push.deviceToken == nil ? "Push yetkisi / cihaz kaydı bulunamadı" : "Cihaz kayıt belirteci alındı",
                           symbol: "antenna.radiowaves.left.and.right")
                Text("Bildirim izni açık olsa da ücretsiz AltStore imzası uzaktan APNs özelliğini sağlamayabilir. Yerel bildirimler ayrı çalışır.")
                    .font(.caption2)
                    .foregroundStyle(BlasterTheme.muted)
            }
        }
    }

    private func statusLine(_ title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .foregroundStyle(BlasterTheme.gold)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(value).font(.caption).foregroundStyle(BlasterTheme.muted)
            }
            Spacer()
        }
    }
}

private struct NewsItemCard: View {
    let notice: MobileNotice
    let isSaved: Bool
    let onToggleSave: () -> Void

    var body: some View {
        BlasterCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 9) {
                    Image(systemName: notice.category == "ETKİNLİK" ? "calendar.badge.clock" : "megaphone.fill")
                        .font(.subheadline)
                        .foregroundStyle(BlasterTheme.gold)
                    Text(notice.category.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.6)
                        .foregroundStyle(BlasterTheme.gold)
                    Spacer()
                    Button(action: onToggleSave) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(BlasterTheme.gold)
                    }
                    .accessibilityLabel(isSaved ? "Kaydedilenlerden kaldır" : "Haberi kaydet")
                    Text(notice.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(BlasterTheme.muted)
                }
                Text(notice.title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(BlasterTheme.ink)
                Text(notice.body)
                    .font(.subheadline)
                    .foregroundStyle(BlasterTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

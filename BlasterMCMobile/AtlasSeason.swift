import SwiftUI

struct AtlasSeasonView: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var tab = 0
    @State private var search = ""

    private var rankings: [SeasonRanking] {
        (session.season?.rankings ?? []).filter {
            search.isEmpty || $0.ownerUsername.localizedStandardContains(search) ||
            $0.islandName.localizedStandardContains(search)
        }
    }

    var body: some View {
        AtlasScreen {
            AtlasMasthead(label: "Sezon arenası / REALM")
            introduction
            awards
            selection
            if tab == 0 {
                leaderboard
            } else {
                timeline
            }
            AtlasAction(title: "Sezon bilgilerini yenile",
                        symbol: "arrow.clockwise", secondary: true) {
                Task { await session.reloadSeason() }
            }
            if let error = session.dataError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Atlas.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .task { await session.reloadSeason() }
        .refreshable { await session.reloadSeason() }
    }

    private var introduction: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Atlas.navy, Atlas.deepBlue],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            RealmPortalArt()
                .frame(width: 128, height: 142)
                .opacity(0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 8)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 11) {
                AtlasPill(title: "SEZON / SKYBLOCK", symbol: "sparkles", highlighted: true)
                Text(session.season?.title ?? "Ada şampiyonası")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .tracking(-0.65)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(session.season?.subtitle ?? "Kur, geliştir ve sıralamada zirveye oyna.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Image(systemName: "banknote.fill").foregroundStyle(Atlas.orange)
                    Text("₺7.500 TOPLAM ÖDÜL")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Atlas.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .padding(.trailing, 95)
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Atlas.aqua.opacity(0.16)))
    }

    private var awards: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "NAKİT ÖDÜLLER", title: "Şampiyonlar kürsüsü",
                         detail: "İlk üç ada için açıklanan ödüller")
            HStack(alignment: .bottom, spacing: 8) {
                prize(rank: 2, amount: "₺1.500", name: "İKİNCİ", top: false)
                    .frame(maxWidth: .infinity)
                prize(rank: 1, amount: "₺5.000", name: "ŞAMPİYON", top: true)
                    .frame(maxWidth: .infinity)
                prize(rank: 3, amount: "₺1.000", name: "ÜÇÜNCÜ", top: false)
                    .frame(maxWidth: .infinity)
            }
            Text("Açıklanan ödüllerdir; kazanan veya ödeme durumu anlamına gelmez.")
                .font(.system(size: 10))
                .foregroundStyle(Atlas.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func prize(rank: Int, amount: String, name: String, top: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: rank == 1 ? "crown.fill" : "medal.fill")
                .font(.system(size: top ? 22 : 17, weight: .bold))
                .foregroundStyle(top ? Atlas.orange : Atlas.copper)
            Text("#\(rank)")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(top ? Color.white.opacity(0.68) : Atlas.muted)
            Text(amount)
                .font(.system(size: top ? 19 : 15, weight: .black, design: .rounded))
                .foregroundStyle(top ? Color.white : Atlas.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
            Text(name)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .tracking(0.25)
                .foregroundStyle(top ? Atlas.orange : Atlas.copper)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: top ? 160 : rank == 2 ? 132 : 118)
        .background(top ? Atlas.navy : Atlas.paper,
                    in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17)
            .strokeBorder(top ? Atlas.orange.opacity(0.4) : Atlas.line))
        .shadow(color: Atlas.navy.opacity(top ? 0.1 : 0.02), radius: 10, x: 0, y: 4)
    }

    private var selection: some View {
        HStack(spacing: 9) {
            tabButton("Sıralama", value: 0, symbol: "list.number")
            tabButton("Takvim ve ödüller", value: 1, symbol: "calendar")
        }
    }

    private func tabButton(_ title: String, value: Int, symbol: String) -> some View {
        Button {
            Atlas.haptic()
            tab = value
        } label: {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tab == value ? Color.white : Atlas.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(tab == value ? Atlas.blue : Atlas.paper,
                            in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(tab == value ? Atlas.blue : Atlas.line))
        }
        .buttonStyle(.plain)
    }

    private var leaderboard: some View {
        VStack(alignment: .leading, spacing: 12) {
            AtlasHeading(kicker: "CANLI SIRALAMA", title: "Ada liderleri",
                         detail: "Sunucunun bildirdiği güncel ada değerleri")
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(Atlas.copper)
                TextField("Oyuncu veya ada ara", text: $search)
                    .font(.system(size: 13))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Atlas.ink)
            }
            .padding(14)
            .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Atlas.line))
            if rankings.isEmpty {
                AtlasEmpty(title: "Ada sıralaması bekleniyor",
                           detail: "Sunucu güncel sıralamayı ilettiğinde burada görünecek.",
                           symbol: "chart.bar.xaxis")
            } else {
                LazyVStack(spacing: 9) {
                    ForEach(rankings) { entry in rankingRow(entry) }
                }
            }
        }
    }

    private func rankingRow(_ item: SeasonRanking) -> some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.rankPosition == 1 ? Atlas.orange :
                          item.rankPosition == 2 ? Atlas.blueLight :
                          item.rankPosition == 3 ? Atlas.sand : Atlas.canvas)
                if item.rankPosition <= 3 {
                    Image(systemName: item.rankPosition == 1 ? "crown.fill" : "medal.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Atlas.ink)
                } else {
                    Text("#\(item.rankPosition)")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(Atlas.muted)
                }
            }
            .frame(width: 43, height: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.ownerUsername)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Atlas.ink)
                    .lineLimit(1)
                Text(item.islandName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Atlas.muted)
                    .lineLimit(1)
                GeometryReader { geo in
                    Capsule().fill(Atlas.line)
                        .overlay(alignment: .leading) {
                            Capsule().fill(item.rankPosition == 1 ? Atlas.orange : Atlas.blue)
                                .frame(width: geo.size.width * min(1, max(0.08,
                                    Double(item.islandValue) / Double(max(1, (session.season?.rankings ?? []).map(\.islandValue).max() ?? 1)))))
                        }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.islandValue.formatted())
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Atlas.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text("ADA DEĞERİ")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .tracking(0.3)
                    .foregroundStyle(Atlas.copper)
            }
        }
        .padding(12)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Atlas.line))
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            AtlasHeading(kicker: "RESMÎ TAKVİM", title: "Sezon yol haritası")
            if let events = session.season?.milestones, !events.isEmpty {
                ForEach(events) { event in
                    AtlasCard {
                        Label(event.title, systemImage: "calendar")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Atlas.ink)
                        Text(event.date ?? "Tarih açıklanmadı")
                            .font(.system(size: 12))
                            .foregroundStyle(Atlas.muted)
                    }
                }
            } else {
                AtlasEmpty(title: "Takvim henüz paylaşılmadı",
                           detail: "Resmî tarihler açıklandığında burada yer alacak.",
                           symbol: "calendar")
            }
            AtlasHeading(kicker: "DİĞER KAZANIMLAR", title: "Ek sezon ödülleri")
            if let rewards = session.season?.rewards, !rewards.isEmpty {
                ForEach(rewards) { reward in
                    AtlasCard {
                        HStack(alignment: .top, spacing: 11) {
                            Image(systemName: "gift.fill")
                                .foregroundStyle(Atlas.copper)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(reward.title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Atlas.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(reward.description)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Atlas.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                                if reward.isClaimed == true {
                                    AtlasPill(title: "Teslim edildi",
                                              symbol: "checkmark.seal.fill", highlighted: true)
                                }
                            }
                        }
                    }
                }
            } else {
                AtlasEmpty(title: "Ek ödül duyurusu yok",
                           detail: "₺5.000, ₺1.500 ve ₺1.000 nakit ödüller yukarıda gösteriliyor.",
                           symbol: "gift")
            }
        }
    }
}

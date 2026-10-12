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
            AtlasMasthead(label: "Sezon merkezi / AURORA")
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
        AtlasBanner(eyebrow: "BLASTERMC  /  SEZON ARENASI") {
            Text("Zirve senin\nolsun.")
                .font(.system(size: 31, weight: .black, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(session.season?.title ?? "SkyBlock ada sıralaması")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.91))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 9) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Atlas.orange)
                Text("TOPLAM ₺7.500 NAKİT ÖDÜL")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .padding(.top, 2)
        }
    }

    private var awards: some View {
        VStack(alignment: .leading, spacing: 12) {
            AtlasHeading(kicker: "AÇIKLANAN NAKİT ÖDÜLLER",
                         title: "Şampiyonlar kürsüsü",
                         detail: "Sezon sonunda sıralamadaki ilk üç ada")
            prize(rank: 1, amount: "₺5.000", name: "BİRİNCİLİK ÖDÜLÜ", top: true)
            HStack(alignment: .top, spacing: 10) {
                prize(rank: 2, amount: "₺1.500", name: "İKİNCİLİK", top: false)
                prize(rank: 3, amount: "₺1.000", name: "ÜÇÜNCÜLÜK", top: false)
            }
            Text("Bu tutarlar açıklanan ödüllerdir; kazanan veya ödeme durumu anlamına gelmez.")
                .font(.system(size: 11))
                .foregroundStyle(Atlas.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func prize(rank: Int, amount: String, name: String, top: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: rank == 1 ? "crown.fill" : "medal.fill")
                    .font(.system(size: top ? 23 : 19))
                    .foregroundStyle(top ? Atlas.orange : Atlas.copper)
                Spacer(minLength: 0)
                Text("#\(rank)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(top ? Color.white.opacity(0.83) : Atlas.muted)
            }
            Text(amount)
                .font(.system(size: top ? 35 : 25, weight: .black, design: .rounded))
                .foregroundStyle(top ? Color.white : Atlas.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(name)
                .font(.system(size: 10, weight: .heavy))
                .tracking(0.5)
                .foregroundStyle(top ? Atlas.orange : Atlas.copper)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(top ? 20 : 17)
        .background(top ? Atlas.blue : Atlas.paper,
                    in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19)
            .strokeBorder(top ? Atlas.orange.opacity(0.38) : Atlas.line))
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
        AtlasCard(inset: 15) {
            HStack(alignment: .center, spacing: 12) {
                Text("#\(item.rankPosition)")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(item.rankPosition <= 3 ? Atlas.copper : Atlas.ink)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.ownerUsername)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Atlas.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.islandName)
                        .font(.system(size: 11))
                        .foregroundStyle(Atlas.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 5) {
                    Text(item.islandValue.formatted())
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("ADA DEĞERİ")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Atlas.copper)
                }
            }
        }
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

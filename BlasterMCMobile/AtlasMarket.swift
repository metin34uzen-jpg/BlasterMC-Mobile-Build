import SwiftUI

struct AtlasMarketView: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var search = ""
    @State private var category = "Tümü"
    @State private var order = 0
    @State private var savedOnly = false
    @State private var selection: StoreProduct?
    @State private var comparing: Set<Int> = []
    @State private var showCompare = false
    @AppStorage("blaster.v11.market.favorites") private var favoritesRaw = ""

    private var favorites: Set<Int> {
        Set(favoritesRaw.split(separator: ",").compactMap { Int($0) })
    }
    private var categories: [String] {
        ["Tümü"] + Array(Set(session.products.map(\.category))).sorted()
    }
    private var featured: StoreProduct? {
        session.products.first(where: {
            let text = ($0.category + " " + $0.name).lowercased()
            return text.contains("vip") || text.contains("rütbe")
        }) ?? session.products.first
    }
    private var visible: [StoreProduct] {
        let filtered = session.products.filter {
            (category == "Tümü" || $0.category == category) &&
            (!savedOnly || favorites.contains($0.id)) &&
            (search.isEmpty || $0.name.localizedStandardContains(search) ||
             $0.category.localizedStandardContains(search) ||
             $0.description.localizedStandardContains(search))
        }
        switch order {
        case 1: return filtered.sorted { ($0.priceCredits ?? Int.max) < ($1.priceCredits ?? Int.max) }
        case 2: return filtered.sorted { ($0.priceCredits ?? -1) > ($1.priceCredits ?? -1) }
        default: return filtered
        }
    }

    var body: some View {
        AtlasScreen {
            AtlasMasthead(label: "Market / Koleksiyon")
            showcase
            balance
            controls
            catalog
            disclaimer
        }
        .refreshable { await session.reloadPublic() }
        .sheet(item: $selection) { item in detail(item) }
        .sheet(isPresented: $showCompare) { comparisonSheet }
    }

    private var showcase: some View {
        AtlasBanner(eyebrow: "BLASTER MARKET  /  SEÇKİ") {
            Text("Oyuncu\nkoleksiyonu.")
                .font(.system(size: 31, weight: .black, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text("Rütbeler, kasalar ve oyun içi içerikler.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.89))
                .fixedSize(horizontal: false, vertical: true)
            if let item = featured {
                HStack(alignment: .top, spacing: 13) {
                    AtlasProductArt(product: item, size: 86, onDark: true)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ÖNE ÇIKAN ÜRÜN")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Atlas.orange)
                        Text(item.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(item.priceCredits.map { "\($0.formatted()) kredi" } ??
                             "Fiyat açıklanmadı")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Atlas.orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
                Button {
                    selection = item
                } label: {
                    HStack {
                        Text("ÜRÜNÜ İNCELE")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Atlas.ink)
                    .padding(.horizontal, 15)
                    .frame(height: 45)
                    .background(Atlas.orange, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                Text("Ürünler sunucudan yüklendiğinde bu vitrinde gösterilecek.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.80))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var balance: some View {
        AtlasCard(tinted: true) {
            HStack(spacing: 12) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Atlas.copper)
                    .frame(width: 43, height: 43)
                    .background(Atlas.sand, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text("BLASTER CÜZDANI")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Atlas.muted)
                    Text("\((session.profile?.credits ?? 0).formatted()) kredi")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                }
                Spacer()
                Image(systemName: "lock.shield")
                    .foregroundStyle(Atlas.blue)
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            AtlasHeading(kicker: "KATALOĞU KEŞFET", title: "Sana uygun olanı bul")
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(Atlas.copper)
                TextField("Ürün, VIP veya kasa ara", text: $search)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Atlas.ink)
                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Atlas.muted)
                    }
                }
            }
            .padding(15)
            .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Atlas.line))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { item in
                        Button {
                            Atlas.haptic()
                            category = item
                        } label: {
                            Text(item)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(category == item ? Color.white : Atlas.ink)
                                .padding(.horizontal, 16)
                                .frame(height: 39)
                                .background(category == item ? Atlas.blue : Atlas.paper, in: Capsule())
                                .overlay(Capsule().strokeBorder(category == item ? Atlas.blue : Atlas.line))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            HStack(spacing: 12) {
                Button {
                    savedOnly.toggle()
                } label: {
                    Label("Favoriler", systemImage: savedOnly ? "heart.fill" : "heart")
                        .foregroundStyle(savedOnly ? Atlas.copper : Atlas.ink)
                }
                Spacer()
                Menu {
                    Button("Önerilen") { order = 0 }
                    Button("Fiyat: artan") { order = 1 }
                    Button("Fiyat: azalan") { order = 2 }
                } label: {
                    Label(order == 0 ? "Sırala" : order == 1 ? "Artan fiyat" : "Azalan fiyat",
                          systemImage: "arrow.up.arrow.down")
                        .foregroundStyle(Atlas.blue)
                }
            }
            .font(.system(size: 12, weight: .bold))
        }
    }

    private var catalog: some View {
        VStack(alignment: .leading, spacing: 12) {
            AtlasHeading(kicker: "BLASTER ÜRÜNLERİ", title: "Koleksiyon",
                         detail: "\(visible.count) ürün görüntüleniyor")
            if session.products.isEmpty {
                AtlasEmpty(title: "Katalog bekleniyor",
                           detail: session.dataError ?? "Gerçek mağaza ürünleri web API'sinden alınacak.",
                           symbol: "bag")
            } else if visible.isEmpty {
                AtlasEmpty(title: "Bu filtrede ürün bulunamadı",
                           detail: "Kategori veya arama terimini değiştirebilirsin.",
                           symbol: "magnifyingglass")
            } else {
                LazyVStack(spacing: 11) {
                    ForEach(visible) { item in productCard(item) }
                }
            }
            if comparing.count == 2 {
                AtlasAction(title: "Seçilen iki ürünü karşılaştır",
                            symbol: "square.split.2x1") {
                    showCompare = true
                }
            }
            AtlasAction(title: "Kataloğu yenile", symbol: "arrow.clockwise", secondary: true) {
                Task { await session.reloadPublic() }
            }
        }
    }

    private func productCard(_ item: StoreProduct) -> some View {
        AtlasCard(inset: 15, spacing: 13) {
            HStack(alignment: .top, spacing: 13) {
                AtlasProductArt(product: item, size: 100)
                VStack(alignment: .leading, spacing: 7) {
                    Text(item.category.uppercased())
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Atlas.copper)
                        .lineLimit(1)
                    Text(item.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.description)
                        .font(.system(size: 12))
                        .foregroundStyle(Atlas.muted)
                        .lineLimit(3)
                    Text(item.priceCredits.map { "\($0.formatted()) KREDİ" } ??
                         "FİYAT AÇIKLANMADI")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Atlas.blue)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            AtlasRule()
            HStack(spacing: 10) {
                Button {
                    selection = item
                } label: {
                    Label("Detaylar", systemImage: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Atlas.blue)
                }
                Spacer()
                Button { toggleFavorite(item.id) } label: {
                    Image(systemName: favorites.contains(item.id) ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundStyle(Atlas.copper)
                        .frame(width: 42, height: 36)
                }
                .accessibilityLabel(favorites.contains(item.id) ? "Favoriden kaldır" : "Favoriye ekle")
                Button {
                    if comparing.contains(item.id) { comparing.remove(item.id) }
                    else if comparing.count < 2 { comparing.insert(item.id) }
                } label: {
                    Image(systemName: comparing.contains(item.id) ?
                          "checkmark.square.fill" : "square.split.2x1")
                        .font(.system(size: 17))
                        .foregroundStyle(Atlas.blue)
                        .frame(width: 42, height: 36)
                }
                .accessibilityLabel("Karşılaştırma seçimi")
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleFavorite(_ id: Int) {
        var set = favorites
        if set.contains(id) { set.remove(id) }
        else { set.insert(id) }
        favoritesRaw = set.sorted().map(String.init).joined(separator: ",")
        Atlas.haptic()
    }

    private func detail(_ item: StoreProduct) -> some View {
        NavigationStack {
            AtlasScreen {
                AtlasHeading(kicker: item.category, title: item.name)
                AtlasCard {
                    HStack(alignment: .top, spacing: 14) {
                        AtlasProductArt(product: item, size: 114)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.priceCredits.map { "\($0.formatted()) kredi" } ??
                                 "Fiyat açıklanmadı")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(Atlas.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            AtlasPill(title: "BLASTER MARKET", highlighted: true)
                        }
                    }
                    Text(item.description)
                        .font(.system(size: 13))
                        .foregroundStyle(Atlas.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                AtlasAction(title: favorites.contains(item.id) ? "Favoriden kaldır" : "Favoriye ekle",
                            symbol: "heart") {
                    toggleFavorite(item.id)
                }
                Text("Bu sürümde mobil satın alma etkin değildir. Teslimat veya ödeme işlemi başlatılmaz.")
                    .font(.system(size: 12))
                    .foregroundStyle(Atlas.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .navigationTitle("Ürün detayları")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private var comparisonSheet: some View {
        NavigationStack {
            AtlasScreen {
                AtlasHeading(kicker: "MARKET / KARŞILAŞTIR", title: "İki ürün yan yana")
                ForEach(session.products.filter { comparing.contains($0.id) }) { item in
                    AtlasCard {
                        Text(item.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Atlas.ink)
                        Text(item.priceCredits.map { "\($0.formatted()) kredi" } ??
                             "Fiyat açıklanmadı")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Atlas.copper)
                        Text(item.description)
                            .font(.system(size: 12))
                            .foregroundStyle(Atlas.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                AtlasAction(title: "Karşılaştırmayı temizle", symbol: "xmark", secondary: true) {
                    comparing.removeAll()
                    showCompare = false
                }
            }
            .navigationTitle("Karşılaştır")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark.shield.fill").foregroundStyle(Atlas.copper)
            Text("Ürün adları ve fiyatları web API'sinden gelir. Doğrulanmamış ürün, bakiye veya ödeme bilgisi oluşturulmaz.")
                .font(.system(size: 11))
                .foregroundStyle(Atlas.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}

struct AtlasProductArt: View {
    let product: StoreProduct
    let size: CGFloat
    var onDark = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(onDark ? Color.white.opacity(0.13) : Atlas.blueLight)
            if let url = product.imageUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit().padding(6)
                    case .failure:
                        fallback.padding(18)
                    default:
                        ProgressView().tint(Atlas.copper)
                    }
                }
            } else {
                fallback.padding(18)
            }
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: 15)
            .strokeBorder(onDark ? Color.white.opacity(0.22) : Atlas.line))
        .accessibilityLabel("Ürün görseli: \(product.name)")
    }

    private var fallback: some View {
        let name = (product.category + " " + product.name).lowercased()
        let symbol = name.contains("vip") || name.contains("rütbe") ? "crown.fill" :
                     name.contains("kasa") ? "gift.fill" :
                     name.contains("anahtar") ? "key.horizontal.fill" :
                     name.contains("kredi") ? "circle.hexagongrid.fill" : "shippingbox.fill"
        return Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .foregroundStyle(onDark ? Atlas.orange : Atlas.copper)
    }
}

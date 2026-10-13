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
            AtlasMasthead(label: "Blaster Market / REALM")
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
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                AtlasHeading(kicker: "BLASTER MARKET / SEÇKİ", title: "Ekipmanını seç",
                             detail: "Koleksiyonunu oluştur.")
                Spacer(minLength: 0)
                AtlasPill(title: "\(session.products.count) ÜRÜN", symbol: "square.grid.2x2", highlighted: true)
            }
            if let item = featured {
                VStack(alignment: .leading, spacing: 13) {
                    HStack(alignment: .center, spacing: 12) {
                        AtlasProductArt(product: item, size: 104, onDark: true)
                        VStack(alignment: .leading, spacing: 7) {
                            Text("EDITÖRÜN SEÇİMİ")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .tracking(0.8)
                                .foregroundStyle(Atlas.orange)
                            Text(item.name)
                                .font(.system(size: 19, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(item.priceCredits.map { "\($0.formatted()) kredi" } ?? "Fiyat açıklanmadı")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Atlas.orange)
                            Text(item.category.uppercased())
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button { selection = item } label: {
                        HStack {
                            Text("ÜRÜNÜ İNCELE")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .tracking(0.7)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .foregroundStyle(Atlas.navy)
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .background(Atlas.orange, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(LinearGradient(colors: [Atlas.navy, Atlas.deepBlue],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 22))
                .overlay(alignment: .topTrailing) {
                    RealmPortalArt().frame(width: 80, height: 90).opacity(0.18).padding(5)
                        .accessibilityHidden(true)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Atlas.aqua.opacity(0.18)))
            } else {
                AtlasEmpty(title: "Mağaza hazırlanıyor",
                           detail: session.dataError ?? "Ürünler yüklendiğinde burada görünecek.",
                           symbol: "shippingbox")
            }
        }
    }

    private var balance: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Atlas.orange)
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Atlas.navy)
            }
            .frame(width: 43, height: 43)
            VStack(alignment: .leading, spacing: 4) {
                Text("BLASTER CÜZDANI")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(Atlas.muted)
                Text("\((session.profile?.credits ?? 0).formatted()) kredi")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Atlas.ink)
            }
            Spacer(minLength: 0)
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 17))
                .foregroundStyle(Atlas.mint)
        }
        .padding(13)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Atlas.line))
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                AtlasHeading(kicker: "KOLEKSİYON", title: "Ne arıyorsun?",
                             detail: "Ara, kategori seç veya favorilerini göster.")
                Spacer(minLength: 0)
                Button {
                    savedOnly.toggle()
                    Atlas.haptic()
                } label: {
                    Image(systemName: savedOnly ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(savedOnly ? Atlas.copper : Atlas.ink)
                        .frame(width: 40, height: 40)
                        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Atlas.line))
                }
                .accessibilityLabel(savedOnly ? "Tüm ürünler" : "Yalnızca favoriler")
            }
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(Atlas.blue)
                TextField("VIP, kasa, anahtar…", text: $search)
                    .font(.system(size: 13))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Atlas.ink)
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Atlas.muted)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 47)
            .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Atlas.line))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(categories, id: \.self) { item in
                        Button {
                            Atlas.haptic()
                            category = item
                        } label: {
                            Text(item)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(category == item ? .white : Atlas.ink)
                                .padding(.horizontal, 13)
                                .frame(height: 34)
                                .background(category == item ? Atlas.blue : Atlas.paper, in: Capsule())
                                .overlay(Capsule().strokeBorder(category == item ? Atlas.blue : Atlas.line))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            HStack(spacing: 6) {
                Text(savedOnly ? "KAYDEDİLENLER" : "KATALOĞUN TAMAMI")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .tracking(0.75)
                    .foregroundStyle(Atlas.muted)
                Spacer()
                Menu {
                    Button("Önerilen") { order = 0 }
                    Button("En düşük fiyat") { order = 1 }
                    Button("En yüksek fiyat") { order = 2 }
                } label: {
                    Label(order == 0 ? "Sırala" : order == 1 ? "Ucuzdan" : "Pahalıdan",
                          systemImage: "arrow.up.arrow.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Atlas.blue)
                }
            }
        }
    }

    private var catalog: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                AtlasHeading(kicker: "ÜRÜN VİTRİNİ", title: "Koleksiyon")
                Spacer()
                Text("\(visible.count) ürün")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Atlas.muted)
            }
            if session.products.isEmpty {
                AtlasEmpty(title: "Ürünler yükleniyor",
                           detail: session.dataError ?? "Gerçek katalog web API'sinden alınacak.",
                           symbol: "shippingbox")
            } else if visible.isEmpty {
                AtlasEmpty(title: "Eşleşen ürün yok",
                           detail: "Aramayı veya kategori filtresini değiştir.",
                           symbol: "magnifyingglass")
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(visible) { item in productCard(item) }
                }
            }
            if comparing.count == 2 {
                AtlasAction(title: "İki ürünü yan yana karşılaştır",
                            symbol: "rectangle.split.2x1.fill") {
                    showCompare = true
                }
            }
            AtlasAction(title: "Mağaza verilerini yenile",
                        symbol: "arrow.clockwise", secondary: true) {
                Task { await session.reloadPublic() }
            }
        }
    }

    private func productCard(_ item: StoreProduct) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 4) {
                Text(item.category.uppercased())
                    .font(.system(size: 7.5, weight: .black, design: .monospaced))
                    .tracking(0.35)
                    .foregroundStyle(Atlas.copper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Button { toggleFavorite(item.id) } label: {
                    Image(systemName: favorites.contains(item.id) ? "heart.fill" : "heart")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(favorites.contains(item.id) ? Atlas.copper : Atlas.muted)
                        .frame(width: 27, height: 27)
                }
                .accessibilityLabel(favorites.contains(item.id) ? "Favoriden kaldır" : "Favoriye ekle")
            }
            Button { selection = item } label: {
                VStack(alignment: .leading, spacing: 9) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14).fill(Atlas.canvas)
                        AtlasProductArt(product: item, size: 91)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 98)
                    Text(item.name)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
                    Text(item.description)
                        .font(.system(size: 10))
                        .foregroundStyle(Atlas.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 26, alignment: .topLeading)
                    Text(item.priceCredits.map { "\($0.formatted()) KREDİ" } ?? "FİYAT AÇIKLANMADI")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Atlas.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Rectangle().fill(Atlas.line).frame(height: 1)
            HStack(spacing: 8) {
                Button { selection = item } label: {
                    Text("İncele")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Atlas.blue)
                }
                Spacer(minLength: 0)
                Button {
                    if comparing.contains(item.id) { comparing.remove(item.id) }
                    else if comparing.count < 2 { comparing.insert(item.id) }
                    else { comparing = [item.id] }
                } label: {
                    Image(systemName: comparing.contains(item.id) ? "checkmark.square.fill" : "square.split.2x1")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(comparing.contains(item.id) ? Atlas.mint : Atlas.muted)
                }
                .accessibilityLabel("Karşılaştırma seçimi")
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Atlas.line))
        .shadow(color: Atlas.navy.opacity(0.035), radius: 8, x: 0, y: 3)
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

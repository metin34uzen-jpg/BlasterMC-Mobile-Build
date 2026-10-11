import SwiftUI

/// Blaster Market — editorial catalogue with verified products, not generic inventory tiles.
struct StudioMarketView: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var query = ""
    @State private var category = "Tümü"
    @State private var order = 0
    @State private var favoritesOnly = false
    @State private var selected: StoreProduct?
    @State private var compared: Set<Int> = []
    @State private var comparing = false
    @AppStorage("blaster.v10.store.favorites") private var savedRaw = ""

    private var favorites: Set<Int> {
        Set(savedRaw.split(separator: ",").compactMap { Int($0) })
    }
    private var categories: [String] {
        ["Tümü"] + Array(Set(session.products.map(\.category))).sorted()
    }
    private var featured: StoreProduct? {
        session.products.first(where: {
            let c = $0.category.lowercased()
            return c.contains("vip") || c.contains("rütbe")
        }) ?? session.products.first
    }
    private var catalog: [StoreProduct] {
        let result = session.products.filter {
            (category == "Tümü" || $0.category == category) &&
            (!favoritesOnly || favorites.contains($0.id)) &&
            (query.isEmpty ||
             $0.name.localizedStandardContains(query) ||
             $0.description.localizedStandardContains(query) ||
             $0.category.localizedStandardContains(query))
        }
        switch order {
        case 1: return result.sorted { ($0.priceCredits ?? Int.max) < ($1.priceCredits ?? Int.max) }
        case 2: return result.sorted { ($0.priceCredits ?? -1) > ($1.priceCredits ?? -1) }
        default: return result
        }
    }
    private var comparedProducts: [StoreProduct] {
        session.products.filter { compared.contains($0.id) }.sorted { $0.id < $1.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    brand
                    featuredBlock
                    wallet
                    discovery
                    results
                    checkoutNote
                }
                .padding(.horizontal, 18)
                .padding(.top, 17)
                .padding(.bottom, 32)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(StudioBackground())
            .toolbar(.hidden, for: .navigationBar)
            .refreshable { await session.reloadPublic() }
            .sheet(item: $selected) { product in detail(product) }
            .sheet(isPresented: $comparing) { comparisonView }
            .preferredColorScheme(.light)
        }
    }

    private var brand: some View {
        HStack(alignment: .center, spacing: 11) {
            BlasterLogo(size: 47)
            VStack(alignment: .leading, spacing: 4) {
                Text("BLASTER MARKET")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(0.3)
                    .foregroundStyle(Studio.ink)
                Text("OYUN İÇİ KOLEKSİYON")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(Studio.gold)
            }
            Spacer(minLength: 1)
            Image(systemName: "bag.fill")
                .font(.system(size: 18))
                .foregroundStyle(Studio.gold)
                .frame(width:42, height:42)
                .background(Studio.pale, in: RoundedRectangle(cornerRadius: 13))
        }
    }

    // A featured item only when a real product exists. Solid contrast, no overlapping artwork.
    private var featuredBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("BLASTER COLLECTION", systemImage: "star.fill")
                    .font(.system(size: 10, weight: .black))
                    .tracking(0.9)
                    .foregroundStyle(Studio.sunlight)
                Spacer()
                Text("MARKET / 03")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }
            HStack(alignment: .center, spacing: 15) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(featured == nil ? "Koleksiyonunu\nkeşfet." : "ÖNE ÇIKAN\nKOLEKSİYON")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .tracking(-0.7)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(featured?.name ?? "VIP rütbeleri, kasalar ve yeni içerikler")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                    if let product = featured {
                        Text(product.priceCredits.map { "\($0.formatted()) KREDİ" } ??
                             "FİYAT AÇIKLANMADI")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Studio.sunlight)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let product = featured {
                    productArtwork(product, size: 105, bright: false)
                } else {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 53, weight: .thin))
                        .foregroundStyle(Studio.sunlight)
                        .frame(width: 94, height: 100)
                }
            }
            if let product = featured {
                Button {
                    selected = product
                } label: {
                    HStack {
                        Text("ÜRÜNÜ İNCELE")
                            .font(.system(size: 12, weight: .black))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundStyle(Studio.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 43)
                    .background(Studio.sunlight, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(BlasterTapStyle())
            } else {
                Text("Mevcut içerikler mağaza bağlantısı kurulduğunda listelenecek.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Studio.navy, Color(red:0.20, green:0.27, blue:0.39)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(RoundedRectangle(cornerRadius:22).strokeBorder(Studio.sunlight.opacity(0.22)))
    }

    private func productArtwork(_ product: StoreProduct, size: CGFloat, bright: Bool = true) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17)
                .fill(bright ? Studio.pale : Color.white.opacity(0.12))
            if let url = product.imageUrl {
                AsyncImage(url: url) { result in
                    switch result {
                    case .success(let image):
                        image.resizable().scaledToFit().padding(6)
                    case .failure:
                        fallbackProductArt(product).padding(13)
                    default:
                        ProgressView().tint(bright ? Studio.gold : Studio.sunlight)
                    }
                }
            } else {
                fallbackProductArt(product).padding(13)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 17)
                .strokeBorder(bright ? Studio.line : Studio.sunlight.opacity(0.20), lineWidth: 1)
        )
        .accessibilityLabel("Ürün görseli: \(product.name)")
    }

    private func fallbackProductArt(_ product: StoreProduct) -> some View {
        let name = product.category.lowercased() + " " + product.name.lowercased()
        let icon = name.contains("vip") || name.contains("rütbe") ? "crown.fill" :
                   name.contains("anahtar") || name.contains("key") ? "key.horizontal.fill" :
                   name.contains("kasa") ? "gift.fill" :
                   name.contains("kredi") ? "circle.hexagongrid.fill" : "shippingbox.fill"
        return Image(systemName: icon)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Studio.gold)
    }

    private var wallet: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 21))
                .foregroundStyle(Studio.gold)
                .frame(width: 40, height: 40)
                .background(Studio.pale, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text("BLASTER CÜZDANI")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Studio.secondary)
                Text("\((session.profile?.credits ?? 0).formatted()) kredi")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Studio.ink)
            }
            Spacer()
            Image(systemName: "lock.shield")
                .foregroundStyle(Studio.gold)
        }
        .padding(15)
        .background(Studio.paper, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Studio.line))
    }

    private var discovery: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudioSection(kicker: "KATEGORİLER / VİTRİN", title: "Ürünleri keşfet")
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Studio.gold)
                TextField("VIP, kasa veya ürün ara", text: $query)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Studio.secondary)
                    }
                }
            }
            .padding(15)
            .background(Studio.paper, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Studio.line))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { label in
                        Button {
                            Studio.touch()
                            category = label
                        } label: {
                            Text(label)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 16)
                                .frame(height: 38)
                                .foregroundStyle(category == label ? .white : Studio.ink)
                                .background(category == label ? Studio.navy : Studio.paper, in: Capsule())
                                .overlay(Capsule().strokeBorder(Studio.line.opacity(0.5)))
                        }
                        .buttonStyle(BlasterTapStyle())
                    }
                }
            }
            HStack {
                Button {
                    favoritesOnly.toggle()
                } label: {
                    Label("Kaydedilenler", systemImage: favoritesOnly ? "heart.fill" : "heart")
                        .foregroundStyle(favoritesOnly ? Studio.gold : Studio.ink)
                }
                Spacer()
                Menu {
                    Button("Önerilen") { order = 0 }
                    Button("Fiyat: düşükten yükseğe") { order = 1 }
                    Button("Fiyat: yüksekten düşüğe") { order = 2 }
                } label: {
                    Label(order == 1 ? "Artan fiyat" : order == 2 ? "Azalan fiyat" : "Sırala",
                          systemImage: "arrow.up.arrow.down")
                        .foregroundStyle(Studio.ink)
                }
            }
            .font(.system(size: 12, weight: .semibold))
        }
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                StudioSection(kicker: "ÜRÜN KATALOĞU",
                              title: "Tüm koleksiyon",
                              accessory: "\(catalog.count) ürün")
                Spacer(minLength: 0)
            }
            if session.products.isEmpty {
                StudioEmpty(title: "Mağaza ürünleri yüklenemedi",
                            detail: session.dataError ?? "Ürün kataloğu için bağlantı bekleniyor.",
                            symbol: "bag")
            } else if catalog.isEmpty {
                StudioEmpty(title: "Bu filtrede ürün yok",
                            detail: "Başka bir kategori seçebilir veya aramayı değiştirebilirsin.",
                            symbol: "magnifyingglass")
            } else {
                LazyVStack(spacing: 11) {
                    ForEach(catalog) { product in
                        productRow(product)
                    }
                }
            }
            HStack(spacing: 10) {
                StudioCTA(title: "Kataloğu yenile", symbol: "arrow.clockwise", subtle: true) {
                    Task { await session.reloadPublic() }
                }
                StudioCTA(title: "Kıyasla (\(compared.count)/2)",
                          symbol: "square.split.2x1",
                          subtle: true) {
                    comparing = true
                }
                .disabled(compared.count != 2)
            }
        }
    }

    private func productRow(_ product: StoreProduct) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 14) {
                productArtwork(product, size: 93)
                VStack(alignment: .leading, spacing: 7) {
                    Text(product.category.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.75)
                        .foregroundStyle(Studio.gold)
                        .lineLimit(1)
                    Text(product.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Studio.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(product.description)
                        .font(.system(size: 12))
                        .foregroundStyle(Studio.secondary)
                        .lineLimit(2)
                    Text(product.priceCredits.map { "\($0.formatted()) KREDİ" } ?? "FİYAT AÇIKLANMADI")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Studio.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider().overlay(Studio.line)
            HStack(spacing: 12) {
                Button {
                    selected = product
                } label: {
                    Label("Detayları gör", systemImage: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Studio.ink)
                }
                Spacer(minLength: 0)
                Button { toggleSaved(product.id) } label: {
                    Image(systemName: favorites.contains(product.id) ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundStyle(Studio.gold)
                        .frame(width: 40, height: 34)
                }
                .accessibilityLabel(favorites.contains(product.id) ? "Favoriden çıkar" : "Favoriye ekle")
                Button {
                    if compared.contains(product.id) { compared.remove(product.id) }
                    else if compared.count < 2 { compared.insert(product.id) }
                } label: {
                    Image(systemName: compared.contains(product.id) ? "checkmark.square.fill" : "square.split.2x1")
                        .font(.system(size: 15))
                        .foregroundStyle(Studio.gold)
                        .frame(width: 40, height: 34)
                }
                .accessibilityLabel(compared.contains(product.id) ? "Karşılaştırmadan kaldır" : "Karşılaştır")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Studio.paper, in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(Studio.line))
    }

    private func toggleSaved(_ id: Int) {
        var all = favorites
        if all.contains(id) { all.remove(id) } else { all.insert(id) }
        savedRaw = all.sorted().map(String.init).joined(separator: ",")
        Studio.touch()
    }

    private func detail(_ product: StoreProduct) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 14) {
                        productArtwork(product, size: 114)
                        VStack(alignment: .leading, spacing: 7) {
                            Text(product.category.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Studio.gold)
                            Text(product.name)
                                .font(.system(size: 23, weight: .bold, design: .rounded))
                                .foregroundStyle(Studio.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(product.priceCredits.map { "\($0.formatted()) kredi" } ?? "Fiyat açıklanmadı")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Studio.ink)
                        }
                    }
                    Text(product.description)
                        .font(.system(size: 14))
                        .foregroundStyle(Studio.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    StudioCTA(title: favorites.contains(product.id) ? "Favorilerden çıkar" : "Favorilere ekle",
                              symbol: favorites.contains(product.id) ? "heart.slash" : "heart.fill") {
                        toggleSaved(product.id)
                    }
                    Text("Satın alma veya oyun içi teslimat, sunucu tarafında doğrulanmış mobil ödeme olmadan başlatılmaz.")
                        .font(.system(size: 12))
                        .foregroundStyle(Studio.secondary)
                }
                .padding(20)
            }
            .background(StudioBackground())
            .navigationTitle("Ürün ayrıntısı")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private var comparisonView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 13) {
                    StudioSection(kicker: "MARKET / KARŞILAŞTIR", title: "Seçilen ürünler")
                    ForEach(comparedProducts) { product in
                        StudioPanel {
                            Text(product.category.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Studio.gold)
                            Text(product.name)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Studio.ink)
                            Text(product.priceCredits.map { "\($0.formatted()) kredi" } ?? "Fiyat açıklanmadı")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Studio.gold)
                            Text(product.description)
                                .font(.system(size: 12))
                                .foregroundStyle(Studio.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    StudioCTA(title: "Karşılaştırmayı temizle", symbol: "xmark", subtle: true) {
                        compared.removeAll()
                        comparing = false
                    }
                }
                .padding(18)
            }
            .background(StudioBackground())
            .navigationTitle("Karşılaştırma")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private var checkoutNote: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Doğrulanmış mağaza kataloğu", systemImage: "checkmark.shield.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Studio.ink)
            Text("Buradaki ürün ve fiyatlar BlasterMC API'sinden gelir. Bu sürümde mobil ödeme işlemi yapılmaz.")
                .font(.system(size: 11))
                .foregroundStyle(Studio.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }
}

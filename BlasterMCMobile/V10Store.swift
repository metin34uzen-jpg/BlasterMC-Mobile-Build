import SwiftUI

/// v10 store is a verified catalog, not an unimplemented in-app purchase flow.
struct V10StoreView: View {
    @EnvironmentObject private var session: BlasterSession
    @AppStorage("blaster.v10.store.favorites") private var favoriteIDs = ""
    @State private var search = ""
    @State private var category = "Tümü"
    @State private var sortOrder = 0
    @State private var favoritesOnly = false
    @State private var selected: StoreProduct?
    @State private var comparisonIDs: Set<Int> = []
    @State private var showComparison = false

    private var favorites: Set<Int> {
        Set(favoriteIDs.split(separator: ",").compactMap { Int($0) })
    }
    private var categories: [String] {
        ["Tümü"] + Array(Set(session.products.map(\.category))).sorted()
    }
    private var filtered: [StoreProduct] {
        let result = session.products.filter { product in
            (category == "Tümü" || product.category == category) &&
            (!favoritesOnly || favorites.contains(product.id)) &&
            (search.isEmpty || product.name.localizedStandardContains(search) ||
             product.description.localizedStandardContains(search) ||
             product.category.localizedStandardContains(search))
        }
        switch sortOrder {
        case 1:
            return result.sorted { ($0.priceCredits ?? Int.max) < ($1.priceCredits ?? Int.max) }
        case 2:
            return result.sorted { ($0.priceCredits ?? -1) > ($1.priceCredits ?? -1) }
        default:
            return result
        }
    }
    private var compared: [StoreProduct] {
        session.products.filter { comparisonIDs.contains($0.id) }.sorted { $0.id < $1.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    storeHero
                    wallet
                    discovery
                    if session.products.isEmpty {
                        NoticePlaceholder(symbol: "shippingbox.fill",
                                          title: "Koleksiyon yüklenemedi",
                                          message: session.dataError ?? "Gerçek ürün kataloğu henüz erişilebilir değil.")
                    } else if filtered.isEmpty {
                        NoticePlaceholder(symbol: "magnifyingglass",
                                          title: "Eşleşen ürün yok",
                                          message: "Aramayı veya filtreleri değiştirmeyi dene.")
                    } else {
                        HStack {
                            Text("\(filtered.count) DOĞRULANMIŞ ÜRÜN")
                                .font(.system(size: 10, weight: .black))
                                .tracking(1.3)
                                .foregroundStyle(V10.gold)
                            Spacer()
                            Button {
                                showComparison = true
                            } label: {
                                Label("Karşılaştır (\(comparisonIDs.count)/2)",
                                      systemImage: "square.split.2x1")
                                    .font(.caption.weight(.heavy))
                            }
                            .foregroundStyle(V10.ink)
                            .disabled(comparisonIDs.count != 2)
                        }
                        ForEach(filtered) { product in
                            productRow(product)
                        }
                    }
                    V10Plate {
                        Label("Güvenli koleksiyon", systemImage: "checkmark.shield.fill")
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(V10.ink)
                        Text("Fiyatlar BlasterMC'nin gerçek mobil API'sinden gelir. Favoriler ve karşılaştırma yalnızca bu cihazdadır. Satın alma için henüz doğrulanmış bir mobil ödeme/teslimat akışı bulunmuyor.")
                            .font(.caption)
                            .foregroundStyle(BlasterTheme.muted)
                    }
                    GoldButton(title: "ÜRÜNLERİ YENİLE", symbol: "arrow.clockwise") {
                        Task { await session.reloadPublic() }
                    }
                }
                .padding(18)
                .padding(.bottom, 30)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background(PremiumBackground())
            .navigationTitle("Blaster Market")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await session.reloadPublic() }
            .sheet(item: $selected) { product in
                productDetails(product)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showComparison) {
                comparisonSheet
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var storeHero: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 29)
                .fill(LinearGradient(colors: [V10.ink, Color(red: 0.35, green: 0.32, blue: 0.30)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            V10SparkField()
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 128))
                .rotationEffect(.degrees(-14))
                .foregroundStyle(V10.bright.opacity(0.18))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 13)
            VStack(alignment: .leading, spacing: 12) {
                V10Tag(text: "MARKET / COLLECTION 10", symbol: "star.fill", dark: true)
                Spacer(minLength: 9)
                Text("Efsanelerin\nkoleksiyonu.")
                    .font(.system(size: 33, weight: .black, design: .rounded))
                    .tracking(-1)
                    .foregroundStyle(.white)
                Text("VIP dünyası, oyun içi ürünler ve gerçek kredi fiyatları.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(23)
        }
        .frame(height: 233)
        .clipShape(RoundedRectangle(cornerRadius: 29))
        .overlay(RoundedRectangle(cornerRadius: 29)
            .strokeBorder(V10.bright.opacity(0.30)))
    }

    private var wallet: some View {
        V10Plate {
            HStack(spacing: 14) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(V10.gold)
                    .frame(width: 49, height: 49)
                    .background(V10.gold.opacity(0.11), in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 4) {
                    Text("BLASTER CÜZDANI")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.4)
                        .foregroundStyle(BlasterTheme.muted)
                    Text("\((session.profile?.credits ?? 0).formatted()) KREDİ")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(V10.ink)
                }
                Spacer()
                Image(systemName: "lock.shield")
                    .foregroundStyle(V10.gold)
            }
        }
    }

    private var discovery: some View {
        VStack(alignment: .leading, spacing: 13) {
            V10Heading(eyebrow: "DISCOVER / FILTER",
                       title: "Sana göre seç",
                       detail: "Gerçek katalogdan arama, favori ve fiyat sıralaması")
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(V10.gold)
                TextField("Ürün, VIP veya kategori ara", text: $search)
                    .font(.subheadline)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(BlasterTheme.muted)
                    }
                }
            }
            .padding(15)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(V10.line))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { name in
                        Button {
                            V10.tap()
                            withAnimation(.easeInOut(duration: 0.2)) { category = name }
                        } label: {
                            Text(name)
                                .font(.caption.weight(.heavy))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .foregroundStyle(category == name ? .white : V10.ink)
                                .background(category == name ? V10.ink : .white, in: Capsule())
                        }
                        .buttonStyle(BlasterTapStyle())
                    }
                }
            }

            HStack {
                Button {
                    favoritesOnly.toggle()
                } label: {
                    Label("Favoriler", systemImage: favoritesOnly ? "heart.fill" : "heart")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(favoritesOnly ? V10.gold : V10.ink)
                }
                Spacer()
                Picker("Sıralama", selection: $sortOrder) {
                    Text("Önerilen").tag(0)
                    Text("Artan fiyat").tag(1)
                    Text("Azalan fiyat").tag(2)
                }
                .pickerStyle(.menu)
                .font(.caption)
                .tint(V10.ink)
            }
        }
    }

    private func productRow(_ product: StoreProduct) -> some View {
        V10Plate {
            HStack(alignment: .top, spacing: 14) {
                productImage(product, size: 92)
                VStack(alignment: .leading, spacing: 7) {
                    Text(product.category.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.3)
                        .foregroundStyle(V10.gold)
                    Text(product.name)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(V10.ink)
                        .lineLimit(2)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                        .lineLimit(2)
                    Text(product.priceCredits.map { "\($0.formatted()) KREDİ" } ?? "FİYAT BELİRTİLMEDİ")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(V10.gold)
                }
                Spacer(minLength: 0)
            }
            V10Divider()
            HStack(spacing: 12) {
                Button {
                    toggleFavorite(product.id)
                } label: {
                    Label(favorites.contains(product.id) ? "Kaydedildi" : "Kaydet",
                          systemImage: favorites.contains(product.id) ? "heart.fill" : "heart")
                }
                Button {
                    if comparisonIDs.contains(product.id) {
                        comparisonIDs.remove(product.id)
                    } else if comparisonIDs.count < 2 {
                        comparisonIDs.insert(product.id)
                    }
                } label: {
                    Label(comparisonIDs.contains(product.id) ? "Seçildi" : "Karşılaştır",
                          systemImage: "square.split.2x1")
                }
                Spacer(minLength: 0)
                Button {
                    selected = product
                } label: {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.title3)
                }
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(V10.gold)
            .buttonStyle(BlasterTapStyle())
        }
    }

    private func productImage(_ product: StoreProduct, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(V10.gold.opacity(0.13))
            if let url = product.imageUrl {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(V10.gold)
                }
                .padding(8)
            } else {
                Image(systemName: "gift.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(V10.gold)
            }
        }
        .frame(width: size, height: size)
    }

    private func toggleFavorite(_ id: Int) {
        var ids = favorites
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        favoriteIDs = ids.sorted().map(String.init).joined(separator: ",")
        V10.tap()
    }

    private func productDetails(_ product: StoreProduct) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 15) {
                        productImage(product, size: 114)
                        VStack(alignment: .leading, spacing: 6) {
                            V10Tag(text: product.category, symbol: "star.fill")
                            Text(product.name)
                                .font(.title2.weight(.black))
                                .foregroundStyle(V10.ink)
                            Text(product.priceCredits.map { "\($0.formatted()) kredi" } ?? "Fiyat belirtilmedi")
                                .font(.headline)
                                .foregroundStyle(V10.gold)
                        }
                    }
                    V10Divider()
                    Text(product.description)
                        .font(.body)
                        .foregroundStyle(V10.ink)
                    Button {
                        toggleFavorite(product.id)
                    } label: {
                        Label(favorites.contains(product.id) ? "FAVORİLERDEN ÇIKAR" : "FAVORİLERE KAYDET",
                              systemImage: favorites.contains(product.id) ? "heart.slash" : "heart.fill")
                            .font(.subheadline.weight(.heavy))
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(V10.bright, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .foregroundStyle(V10.ink)
                    Text("Bu ekran katalog bilgisi sunar; mobil ödeme ve teslimat işlemi başlatmaz.")
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                }
                .padding(21)
            }
            .background(PremiumBackground())
            .navigationTitle("Ürün detayı")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var comparisonSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    V10Heading(eyebrow: "MARKET / COMPARE",
                               title: "Yan yana incele",
                               detail: "Seçtiğin iki doğrulanmış ürün")
                    ForEach(compared) { product in
                        V10Plate {
                            Text(product.category.uppercased())
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(V10.gold)
                            Text(product.name)
                                .font(.title3.weight(.black))
                                .foregroundStyle(V10.ink)
                            Text(product.priceCredits.map { "\($0.formatted()) kredi" } ?? "Fiyat belirtilmedi")
                                .font(.headline)
                                .foregroundStyle(V10.gold)
                            Text(product.description)
                                .font(.caption)
                                .foregroundStyle(BlasterTheme.muted)
                        }
                    }
                    Button("Karşılaştırmayı sıfırla") {
                        comparisonIDs.removeAll()
                        showComparison = false
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(V10.gold)
                }
                .padding(18)
            }
            .background(PremiumBackground())
            .navigationTitle("Ürün karşılaştırması")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

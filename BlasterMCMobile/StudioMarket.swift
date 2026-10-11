import SwiftUI

struct StudioMarketView:View {
    @EnvironmentObject private var session:BlasterSession
    @State private var query=""
    @State private var category="Tümü"
    @State private var favoriteOnly=false
    @State private var sort=0
    @State private var selected:StoreProduct?
    @State private var comparing:Set<Int>=[]
    @State private var compareOpen=false
    @AppStorage("blaster.v10.store.favorites") private var favoritesRaw=""

    private var favorites:Set<Int> {
        Set(favoritesRaw.split(separator:",").compactMap{Int($0)})
    }
    private var categories:[String] {
        ["Tümü"]+Array(Set(session.products.map(\.category))).sorted()
    }
    private var products:[StoreProduct] {
        let list=session.products.filter {
            (category=="Tümü" || $0.category==category) &&
            (!favoriteOnly || favorites.contains($0.id)) &&
            (query.isEmpty || $0.name.localizedStandardContains(query) ||
             $0.description.localizedStandardContains(query))
        }
        switch sort {
        case 1:return list.sorted { ($0.priceCredits ?? Int.max)<($1.priceCredits ?? Int.max) }
        case 2:return list.sorted { ($0.priceCredits ?? -1)>($1.priceCredits ?? -1) }
        default:return list
        }
    }
    private var comparison:[StoreProduct] {
        session.products.filter{comparing.contains($0.id)}.sorted{$0.id<$1.id}
    }

    var body:some View {
        NavigationStack {
            ScrollView(showsIndicators:false) {
                VStack(alignment:.leading,spacing:19) {
                    StudioSection(kicker:"BLASTER MARKET / KOLEKSİYON",title:"Oyun mağazası")
                    StudioHero(symbol:"bag",height:146) {
                        VStack(alignment:.leading,spacing:6) {
                            Text("BLASTER MARKET")
                                .font(.system(size:10,weight:.bold,design:.monospaced))
                                .foregroundStyle(Studio.sunlight)
                            Text("Oyuncu koleksiyonu.")
                                .font(.system(size:24,weight:.bold,design:.rounded))
                                .foregroundStyle(.white)
                            Text("VIP, kasalar ve özel ürünler.")
                                .font(.system(size:12))
                                .foregroundStyle(.white.opacity(0.76))
                        }
                    }
                    balance
                    filterControls
                    results
                    StudioPanel {
                        Label("Gerçek katalog",systemImage:"checkmark.shield")
                            .font(.system(size:13,weight:.semibold))
                            .foregroundStyle(Studio.ink)
                        Text("Fiyatlar ve ürünler web API'sinden alınır. Güvenli mobil satın alma ve teslimat servisi etkinleşmeden bu uygulama ödeme işlemi başlatmaz.")
                            .font(.system(size:12))
                            .foregroundStyle(Studio.secondary)
                            .fixedSize(horizontal:false,vertical:true)
                    }
                }
                .padding(.horizontal,18)
                .padding(.top,18)
                .padding(.bottom,28)
                .frame(maxWidth:620)
                .frame(maxWidth:.infinity)
            }
            .background(StudioBackground())
            .toolbar(.hidden,for:.navigationBar)
            .refreshable { await session.reloadPublic() }
            .sheet(item:$selected) { product in productDetail(product) }
            .sheet(isPresented:$compareOpen) { compareSheet }
        }
    }

    private var balance:some View {
        StudioPanel(padding:14) {
            HStack(spacing:11) {
                Image(systemName:"circle.hexagongrid.fill")
                    .font(.system(size:22))
                    .foregroundStyle(Studio.gold)
                    .frame(width:36)
                VStack(alignment:.leading,spacing:3) {
                    Text("BLASTER CÜZDANI")
                        .font(.system(size:10,weight:.bold))
                        .foregroundStyle(Studio.secondary)
                    Text("\((session.profile?.credits ?? 0).formatted()) kredi")
                        .font(.system(size:19,weight:.bold,design:.rounded))
                        .foregroundStyle(Studio.ink)
                }
                Spacer()
                Image(systemName:"lock.shield")
                    .foregroundStyle(Studio.gold)
            }
        }
    }

    private var filterControls:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"ÜRÜNLER / KEŞFET",title:"Katalog")
            HStack(spacing:9) {
                Image(systemName:"magnifyingglass").foregroundStyle(Studio.gold)
                TextField("Ürün veya VIP ara",text:$query)
                    .font(.system(size:13))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button { query="" } label: {
                        Image(systemName:"xmark.circle.fill").foregroundStyle(Studio.secondary)
                    }
                }
            }
            .padding(13)
            .background(Studio.paper,in:RoundedRectangle(cornerRadius:12))
            .overlay(RoundedRectangle(cornerRadius:12).strokeBorder(Studio.line))

            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:7) {
                    ForEach(categories,id:\.self) { name in
                        Button {
                            Studio.touch()
                            category=name
                        } label: {
                            Text(name)
                                .font(.system(size:11,weight:.semibold))
                                .padding(.horizontal,13)
                                .padding(.vertical,10)
                                .foregroundStyle(category==name ? .white : Studio.ink)
                                .background(category==name ? Studio.navy : Studio.paper,
                                            in:Capsule())
                                .overlay(Capsule().strokeBorder(Studio.line.opacity(0.5)))
                        }
                        .buttonStyle(BlasterTapStyle())
                    }
                }
            }
            HStack(spacing:12) {
                Button {
                    favoriteOnly.toggle()
                } label: {
                    Label("Favoriler",systemImage:favoriteOnly ? "heart.fill" : "heart")
                        .font(.system(size:12,weight:.semibold))
                        .foregroundStyle(favoriteOnly ? Studio.gold : Studio.ink)
                }
                Spacer()
                Picker("Sıralama",selection:$sort) {
                    Text("Önerilen").tag(0)
                    Text("Fiyat artan").tag(1)
                    Text("Fiyat azalan").tag(2)
                }
                .pickerStyle(.menu)
                .tint(Studio.ink)
                .font(.system(size:12))
                Button {
                    compareOpen=true
                } label: {
                    Label("\(comparing.count)/2",systemImage:"square.split.2x1")
                        .font(.system(size:12,weight:.semibold))
                        .foregroundStyle(Studio.gold)
                }
                .disabled(comparing.count != 2)
            }
        }
    }

    private var results:some View {
        VStack(alignment:.leading,spacing:10) {
            if session.products.isEmpty {
                StudioEmpty(title:"Ürünler henüz yüklenmedi",
                            detail:session.dataError ?? "Web mağazasındaki katalog bekleniyor.",
                            symbol:"bag")
            } else if products.isEmpty {
                StudioEmpty(title:"Eşleşen ürün bulunamadı",
                            detail:"Aramayı veya filtreleri değiştirebilirsin.",
                            symbol:"magnifyingglass")
            } else {
                Text("\(products.count) ürün")
                    .font(.system(size:11,weight:.semibold))
                    .foregroundStyle(Studio.secondary)
                LazyVStack(spacing:9) {
                    ForEach(products) { product in row(product) }
                }
            }
            StudioCTA(title:"Kataloğu yenile",symbol:"arrow.clockwise",subtle:true) {
                Task { await session.reloadPublic() }
            }
        }
    }

    private func artwork(_ product:StoreProduct)->some View {
        ZStack {
            RoundedRectangle(cornerRadius:13)
                .fill(Studio.pale)
            if let image=product.imageUrl {
                AsyncImage(url:image) { img in
                    img.resizable().scaledToFit()
                } placeholder: {
                    Image(systemName: product.category.lowercased().contains("vip") ?
                          "crown.fill" : "shippingbox.fill")
                        .font(.system(size:27))
                        .foregroundStyle(Studio.gold)
                }
                .padding(7)
            } else {
                Image(systemName:product.category.lowercased().contains("vip") ?
                      "crown.fill" : "shippingbox.fill")
                    .font(.system(size:27))
                    .foregroundStyle(Studio.gold)
            }
        }
        .frame(width:70,height:74)
    }

    private func row(_ product:StoreProduct)->some View {
        StudioPanel(padding:14) {
            HStack(alignment:.top,spacing:12) {
                artwork(product)
                VStack(alignment:.leading,spacing:6) {
                    Text(product.category.uppercased())
                        .font(.system(size:9,weight:.bold))
                        .tracking(0.7)
                        .foregroundStyle(Studio.gold)
                        .lineLimit(1)
                    Text(product.name)
                        .font(.system(size:15,weight:.bold))
                        .foregroundStyle(Studio.ink)
                        .fixedSize(horizontal:false,vertical:true)
                    Text(product.description)
                        .font(.system(size:11))
                        .foregroundStyle(Studio.secondary)
                        .lineLimit(2)
                    Text(product.priceCredits.map{"\($0.formatted()) KREDİ"} ??
                         "FİYAT AÇIKLANMADI")
                        .font(.system(size:11,weight:.bold))
                        .foregroundStyle(Studio.gold)
                        .fixedSize(horizontal:false,vertical:true)
                }
                .frame(maxWidth:.infinity,alignment:.leading)
            }
            Divider().overlay(Studio.line)
            HStack(spacing:14) {
                Button { toggleFavorite(product.id) } label: {
                    Label("Kaydet",systemImage:favorites.contains(product.id) ?
                          "heart.fill" : "heart")
                }
                Button {
                    if comparing.contains(product.id) { comparing.remove(product.id) }
                    else if comparing.count<2 { comparing.insert(product.id) }
                } label: {
                    Label("Kıyasla",systemImage:comparing.contains(product.id) ?
                          "checkmark.square.fill" : "square.split.2x1")
                }
                Spacer(minLength:2)
                Button { selected=product } label: {
                    Label("İncele",systemImage:"arrow.up.right")
                }
            }
            .font(.system(size:11,weight:.semibold))
            .foregroundStyle(Studio.gold)
            .buttonStyle(BlasterTapStyle())
        }
    }

    private func toggleFavorite(_ id:Int) {
        var entries=favorites
        if entries.contains(id) { entries.remove(id) }
        else { entries.insert(id) }
        favoritesRaw=entries.sorted().map(String.init).joined(separator:",")
        Studio.touch()
    }

    private func productDetail(_ product:StoreProduct)->some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:17) {
                    artwork(product).frame(maxWidth:.infinity,alignment:.leading)
                    StudioSection(kicker:product.category,title:product.name)
                    Text(product.description)
                        .font(.system(size:14))
                        .foregroundStyle(Studio.secondary)
                        .fixedSize(horizontal:false,vertical:true)
                    Text(product.priceCredits.map{"\($0.formatted()) kredi"} ?? "Fiyat belirtilmedi")
                        .font(.system(size:18,weight:.bold))
                        .foregroundStyle(Studio.gold)
                    StudioCTA(title:favorites.contains(product.id) ?
                              "Favorilerden çıkar" : "Favorilere kaydet",symbol:"heart") {
                        toggleFavorite(product.id)
                    }
                    Text("Bu ekran ödeme başlatmaz.")
                        .font(.caption)
                        .foregroundStyle(Studio.secondary)
                }
                .padding(20)
            }
            .background(StudioBackground())
            .navigationTitle("Ürün ayrıntısı")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium,.large])
    }

    private var compareSheet:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:12) {
                    StudioSection(kicker:"KARŞILAŞTIR",title:"Seçtiğin ürünler")
                    ForEach(comparison) { p in
                        StudioPanel {
                            Text(p.name)
                                .font(.system(size:16,weight:.bold))
                                .foregroundStyle(Studio.ink)
                            Text(p.priceCredits.map{"\($0.formatted()) kredi"} ?? "Fiyat belirtilmedi")
                                .font(.system(size:13,weight:.semibold))
                                .foregroundStyle(Studio.gold)
                            Text(p.description)
                                .font(.system(size:12))
                                .foregroundStyle(Studio.secondary)
                        }
                    }
                    StudioCTA(title:"Karşılaştırmayı temizle",symbol:"xmark",subtle:true) {
                        comparing.removeAll()
                        compareOpen=false
                    }
                }
                .padding(18)
            }
            .background(StudioBackground())
            .navigationTitle("Ürün karşılaştırması")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium,.large])
    }
}

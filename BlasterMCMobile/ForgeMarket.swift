import SwiftUI

// Authentic API catalog, displayed as a Minecraft collector's vault.
struct ForgeMarketView: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var search = ""
    @State private var group = "Tümü"
    @State private var sort = 0
    @State private var selected: StoreProduct?
    @State private var compared: Set<Int> = []
    @State private var showCompare = false
    @State private var showFavorites = false
    @AppStorage("blaster.v10.store.favorites") private var favoritesRaw = ""

    private var favorites: Set<Int> {
        Set(favoritesRaw.split(separator:",").compactMap{Int($0)})
    }
    private var groups: [String] {
        ["Tümü"] + Array(Set(session.products.map(\.category))).sorted()
    }
    private var products: [StoreProduct] {
        let p=session.products.filter {
            (group == "Tümü" || $0.category == group) &&
            (!showFavorites || favorites.contains($0.id)) &&
            (search.isEmpty || $0.name.localizedStandardContains(search) ||
             $0.description.localizedStandardContains(search) ||
             $0.category.localizedStandardContains(search))
        }
        switch sort {
        case 1: return p.sorted{($0.priceCredits ?? Int.max)<($1.priceCredits ?? Int.max)}
        case 2: return p.sorted{($0.priceCredits ?? -1)>($1.priceCredits ?? -1)}
        default: return p
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators:false) {
                VStack(alignment:.leading,spacing:20) {
                    heading
                    vault
                    balance
                    filters
                    catalog
                    legal
                }
                .padding(.horizontal,18)
                .padding(.top,18)
                .padding(.bottom,30)
                .frame(maxWidth:660)
                .frame(maxWidth:.infinity)
            }
            .background(ForgeBackground())
            .toolbar(.hidden,for:.navigationBar)
            .refreshable { await session.reloadPublic() }
            .sheet(item:$selected) { product in productSheet(product) }
            .sheet(isPresented:$showCompare) { compareSheet }
        }
    }

    private var heading:some View {
        HStack(alignment:.center) {
            VStack(alignment:.leading,spacing:6) {
                ForgeLabel(text:"THE MARKET / 02")
                Text("Koleksiyon odası.")
                    .font(.system(size:29,weight:.black,design:.rounded))
                    .tracking(-1)
                    .foregroundStyle(Forge.midnight)
                Text("VIP • Kasa • Özel eşyalar")
                    .font(.caption)
                    .foregroundStyle(Forge.muted)
            }
            Spacer()
            ForgeEmblem(width:48)
        }
    }

    private var vault:some View {
        ZStack(alignment:.leading) {
            ForgeCut(cut:20)
                .fill(LinearGradient(colors:[Forge.midnight,Forge.midnight2],
                                     startPoint:.topLeading,endPoint:.bottomTrailing))
            GeometryReader { g in
                ZStack {
                    Circle().fill(Forge.sun.opacity(0.22))
                        .frame(width:150,height:150)
                        .blur(radius:37)
                    ForgeVoxelIsland()
                        .frame(width:g.size.width*0.80,height:g.size.height*0.88)
                        .offset(x:g.size.width*0.31,y:0)
                }
            }
            LinearGradient(colors:[Forge.midnight.opacity(0.95),Forge.midnight.opacity(0.55),.clear],
                           startPoint:.leading,endPoint:.trailing)
            VStack(alignment:.leading,spacing:9) {
                ForgeLabel(text:"THE VAULT / COLLECTION",onDark:true)
                Spacer(minLength:8)
                Text("SIRADAN\nOLMA.")
                    .font(.system(size:35,weight:.black,design:.rounded))
                    .tracking(-1)
                    .foregroundStyle(.white)
                Text("Gerçek ürünler. Gerçek kredi fiyatları.")
                    .font(.system(size:11,weight:.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal:false,vertical:true)
            }
            .padding(22)
        }
        .frame(height:224)
        .clipShape(ForgeCut(cut:20))
        .overlay(ForgeCut(cut:20).strokeBorder(Forge.sun.opacity(0.37)))
    }

    private var balance:some View {
        HStack(spacing:11) {
            Image(systemName:"circle.hexagongrid.fill")
                .font(.system(size:22))
                .foregroundStyle(Forge.gold)
                .frame(width:39,height:42)
            VStack(alignment:.leading,spacing:3) {
                Text("BLASTER WALLET")
                    .font(.system(size:9,weight:.black,design:.monospaced))
                    .tracking(1)
                    .foregroundStyle(Forge.muted)
                Text("\((session.profile?.credits ?? 0).formatted()) KREDİ")
                    .font(.system(size:21,weight:.black,design:.rounded))
                    .foregroundStyle(Forge.midnight)
            }
            Spacer()
            Image(systemName:"lock.shield.fill")
                .foregroundStyle(Forge.gold)
        }
        .padding(16)
        .background(Forge.white,in:ForgeCut(cut:14))
        .overlay(ForgeCut(cut:14).strokeBorder(Forge.stroke.opacity(0.6)))
    }

    private var filters:some View {
        VStack(alignment:.leading,spacing:12) {
            ForgeHeading(eyebrow:"CURATED FOR YOU",title:"Envanter",
                         subtitle:"Doğrulanmış mağaza kataloğundan seç.")
            HStack(spacing:9) {
                Image(systemName:"magnifyingglass")
                    .foregroundStyle(Forge.gold)
                TextField("VIP, kasa, ürün ara",text:$search)
                    .font(.system(size:13))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !search.isEmpty {
                    Button { search="" } label: {
                        Image(systemName:"xmark.circle.fill")
                            .foregroundStyle(Forge.muted)
                    }
                }
            }
            .padding(15)
            .background(Forge.white,in:ForgeCut(cut:10))
            .overlay(ForgeCut(cut:10).strokeBorder(Forge.stroke.opacity(0.6)))

            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:7) {
                    ForEach(groups,id:\.self) { item in
                        Button {
                            Forge.impact()
                            group=item
                        } label: {
                            ForgePixelChip(title:item,symbol:item == "Tümü" ? "square.grid.2x2.fill" : "tag.fill",
                                           selected:group == item)
                        }
                        .buttonStyle(BlasterTapStyle())
                    }
                }
            }
            HStack {
                Button {
                    Forge.impact()
                    showFavorites.toggle()
                } label: {
                    Label("FAVORİLER",systemImage:showFavorites ? "bookmark.fill" : "bookmark")
                        .font(.system(size:10,weight:.black,design:.monospaced))
                        .foregroundStyle(showFavorites ? Forge.gold : Forge.midnight)
                }
                Spacer()
                Picker("Sırala",selection:$sort) {
                    Text("Önerilen").tag(0)
                    Text("Düşük fiyat").tag(1)
                    Text("Yüksek fiyat").tag(2)
                }
                .pickerStyle(.menu)
                .tint(Forge.midnight)
                .font(.caption)
                Button {
                    showCompare=true
                } label: {
                    Label("\(compared.count)/2",systemImage:"square.split.2x1.fill")
                        .font(.system(size:11,weight:.black,design:.monospaced))
                        .foregroundStyle(Forge.gold)
                }
                .disabled(compared.count != 2)
            }
        }
    }

    private var catalog:some View {
        VStack(alignment:.leading,spacing:11) {
            if session.products.isEmpty {
                ForgeSurface {
                    Label("Mağaza kataloğu bekleniyor",systemImage:"shippingbox.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Forge.midnight)
                    Text(session.dataError ?? "Ürünler BlasterMC API bağlantısıyla görüntülenecek.")
                        .font(.caption)
                        .foregroundStyle(Forge.muted)
                }
            } else if products.isEmpty {
                ForgeSurface {
                    Text("Bu filtreyle eşleşen ürün yok.")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Forge.midnight)
                    ForgeButton(title:"Filtreleri sıfırla",symbol:"arrow.uturn.backward") {
                        group="Tümü";search="";showFavorites=false
                    }
                }
            } else {
                HStack {
                    ForgeLabel(text:"\(products.count) ÜRÜN / LIVE CATALOG")
                    Spacer()
                    Image(systemName:"square.grid.2x2")
                        .foregroundStyle(Forge.gold)
                }
                LazyVGrid(columns:[GridItem(.flexible(),spacing:10),GridItem(.flexible(),spacing:10)],
                          spacing:10) {
                    ForEach(products) { product in
                        productTile(product)
                    }
                }
            }
        }
    }

    private func productTile(_ p:StoreProduct)->some View {
        VStack(alignment:.leading,spacing:9) {
            ZStack(alignment:.topTrailing) {
                ForgeStoreGlyph(category:p.category)
                    .frame(maxWidth:.infinity)
                    .frame(height:115)
                Button { toggleFavorite(p.id) } label: {
                    Image(systemName:favorites.contains(p.id) ? "bookmark.fill" : "bookmark")
                        .font(.system(size:13,weight:.bold))
                        .foregroundStyle(Forge.sun)
                        .padding(10)
                        .background(Forge.midnight.opacity(0.85),in:ForgeCut(cut:7))
                }
                .padding(8)
                .accessibilityLabel(favorites.contains(p.id) ? "Favorilerden kaldır" : "Ürünü kaydet")
            }
            .clipped()
            Text(p.category.uppercased())
                .font(.system(size:9,weight:.black,design:.monospaced))
                .foregroundStyle(Forge.bronze)
                .lineLimit(1)
            Text(p.name)
                .font(.system(size:15,weight:.black,design:.rounded))
                .foregroundStyle(Forge.midnight)
                .lineLimit(2)
                .frame(maxWidth:.infinity,minHeight:35,alignment:.topLeading)
            Text(p.priceCredits.map{"\($0.formatted()) KREDİ"} ?? "FİYAT BELİRTİLMEDİ")
                .font(.system(size:11,weight:.black,design:.monospaced))
                .foregroundStyle(Forge.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            HStack(spacing:6) {
                Button {
                    selected=p
                } label: {
                    Text("İNCELE")
                        .font(.system(size:10,weight:.black,design:.monospaced))
                        .frame(maxWidth:.infinity)
                        .frame(height:36)
                        .foregroundStyle(Forge.midnight)
                        .background(Forge.sun,in:ForgeCut(cut:7))
                }
                Button {
                    if compared.contains(p.id) { compared.remove(p.id) }
                    else if compared.count<2 { compared.insert(p.id) }
                } label: {
                    Image(systemName:compared.contains(p.id) ? "checkmark.square.fill" : "square.split.2x1")
                        .font(.system(size:16))
                        .foregroundStyle(Forge.gold)
                        .frame(width:34,height:36)
                }
                .accessibilityLabel(compared.contains(p.id) ? "Karşılaştırmadan kaldır" : "Karşılaştırmaya ekle")
            }
        }
        .padding(11)
        .background(Forge.white,in:ForgeCut(cut:13))
        .overlay(ForgeCut(cut:13).strokeBorder(Forge.stroke.opacity(0.65),lineWidth:1))
    }

    private func toggleFavorite(_ id:Int) {
        var all=favorites
        if all.contains(id) { all.remove(id) }
        else { all.insert(id) }
        favoritesRaw=all.sorted().map(String.init).joined(separator:",")
        Forge.impact()
    }

    private func productSheet(_ p:StoreProduct)->some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:16) {
                    ForgeStoreGlyph(category:p.category).frame(height:174)
                    ForgeLabel(text:p.category)
                    Text(p.name)
                        .font(.system(size:28,weight:.black,design:.rounded))
                        .foregroundStyle(Forge.midnight)
                    Text(p.priceCredits.map{"\($0.formatted()) KREDİ"} ?? "Fiyat henüz belirtilmedi")
                        .font(.system(size:17,weight:.black,design:.monospaced))
                        .foregroundStyle(Forge.gold)
                    Text(p.description)
                        .font(.body)
                        .foregroundStyle(Forge.midnight)
                        .fixedSize(horizontal:false,vertical:true)
                    ForgeButton(title:favorites.contains(p.id) ? "Favorilerden kaldır" : "Koleksiyonuma kaydet",
                                symbol:favorites.contains(p.id) ? "bookmark.slash" : "bookmark.fill") {
                        toggleFavorite(p.id)
                    }
                    Text("Mobil satın alma ve oyun içi teslimat için doğrulanmış işlem akışı henüz etkin değil.")
                        .font(.caption)
                        .foregroundStyle(Forge.muted)
                }
                .padding(19)
            }
            .background(ForgeBackground())
            .navigationTitle("Koleksiyon detayı")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium,.large])
    }

    private var compareSheet:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:13) {
                    ForgeHeading(eyebrow:"MARKET / COMPARE",title:"Karşılaştırma")
                    ForEach(session.products.filter{compared.contains($0.id)}) { p in
                        ForgeSurface {
                            ForgeLabel(text:p.category)
                            Text(p.name)
                                .font(.title3.weight(.black))
                                .foregroundStyle(Forge.midnight)
                            Text(p.priceCredits.map{"\($0.formatted()) kredi"} ?? "Fiyat belirtilmedi")
                                .foregroundStyle(Forge.gold)
                            Text(p.description)
                                .font(.caption)
                                .foregroundStyle(Forge.muted)
                        }
                    }
                    ForgeButton(title:"Karşılaştırmayı temizle",symbol:"xmark") {
                        compared.removeAll()
                        showCompare=false
                    }
                }
                .padding(18)
            }
            .background(ForgeBackground())
            .navigationTitle("Ürün kıyaslama")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium,.large])
    }

    private var legal:some View {
        VStack(alignment:.leading,spacing:7) {
            Label("Şeffaf mağaza",systemImage:"checkmark.shield.fill")
                .font(.system(size:12,weight:.black))
                .foregroundStyle(Forge.midnight)
            Text("Ürün adı, açıklama ve kredi bedelleri BlasterMC API'sinden alınır. Bu ekran ödeme veya teslimat başlatmaz.")
                .font(.caption)
                .foregroundStyle(Forge.muted)
            ForgeButton(title:"Kataloğu güncelle",symbol:"arrow.clockwise",quiet:true) {
                Task { await session.reloadPublic() }
            }
        }
    }
}

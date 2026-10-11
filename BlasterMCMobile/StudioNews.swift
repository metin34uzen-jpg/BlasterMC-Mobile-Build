import SwiftUI

/// Public news feed: no push permissions or device configuration controls.
struct StudioNewsView:View {
    @EnvironmentObject private var session:BlasterSession
    @Environment(\.dismiss) private var dismiss
    @State private var feed=0
    @State private var search=""
    @State private var savedOnly=false
    @AppStorage("blaster.v10.news.saved") private var savedRaw=""

    private var saved:Set<Int> {
        Set(savedRaw.split(separator:",").compactMap{Int($0)})
    }
    private var stories:[MobileNotice] {
        let base:[MobileNotice]
        switch feed {
        case 1:base=session.announcements
        case 2:base=session.events
        default:base=session.announcements + session.events
        }
        return base.filter {
            (!savedOnly || saved.contains($0.id)) &&
            (search.isEmpty || $0.title.localizedStandardContains(search) ||
             $0.body.localizedStandardContains(search))
        }.sorted(by:{$0.createdAt>$1.createdAt})
    }

    var body:some View {
        NavigationStack {
            ScrollView(showsIndicators:false) {
                VStack(alignment:.leading,spacing:19) {
                    StudioSection(kicker:"HABERLER / BLASTERMC",title:"Topluluk gündemi",
                                  accessory:"\(session.announcements.count + session.events.count) içerik")
                    StudioHero(symbol:"megaphone",height:135) {
                        VStack(alignment:.leading,spacing:6) {
                            Text("BLASTER HABERLER")
                                .font(.system(size:10,weight:.bold,design:.monospaced))
                                .foregroundStyle(Studio.sunlight)
                            Text("Dünyadan haberin olsun.")
                                .font(.system(size:21,weight:.bold,design:.rounded))
                                .foregroundStyle(.white)
                            Text("Duyurular, yenilikler ve etkinlikler.")
                                .font(.system(size:11))
                                .foregroundStyle(.white.opacity(0.77))
                        }
                    }
                    HStack(spacing:7) {
                        tab("Tümü",index:0)
                        tab("Duyuru",index:1)
                        tab("Etkinlik",index:2)
                    }
                    HStack(spacing:9) {
                        Image(systemName:"magnifyingglass")
                            .foregroundStyle(Studio.gold)
                        TextField("Haberlerde ara",text:$search)
                            .font(.system(size:13))
                        Button {
                            savedOnly.toggle()
                        } label: {
                            Image(systemName:savedOnly ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(Studio.gold)
                        }
                        .accessibilityLabel("Kaydedilen haberleri göster")
                    }
                    .padding(13)
                    .background(Studio.paper,in:RoundedRectangle(cornerRadius:12))
                    .overlay(RoundedRectangle(cornerRadius:12).strokeBorder(Studio.line))
                    if stories.isEmpty {
                        StudioEmpty(title:"Haber bulunamadı",
                                    detail:session.dataError ??
                                    "Henüz içerik yok veya seçtiğin filtreyle eşleşmiyor.",
                                    symbol:"text.bubble")
                    } else {
                        ForEach(stories) { story in
                            storyCard(story)
                        }
                    }
                    StudioCTA(title:"İçerikleri yenile",symbol:"arrow.clockwise",subtle:true) {
                        Task { await session.reloadPublic() }
                    }
                }
                .padding(.horizontal,18)
                .padding(.top,20)
                .padding(.bottom,28)
                .frame(maxWidth:620)
                .frame(maxWidth:.infinity)
            }
            .background(StudioBackground())
            .navigationTitle("Blaster Haberler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(Studio.gold)
                }
            }
            .refreshable { await session.reloadPublic() }
        }
    }

    private func tab(_ title:String,index:Int)->some View {
        Button {
            Studio.touch()
            feed=index
        } label: {
            Text(title)
                .font(.system(size:12,weight:.semibold))
                .frame(maxWidth:.infinity,minHeight:39)
                .foregroundStyle(feed == index ? .white : Studio.ink)
                .background(feed == index ? Studio.navy : Studio.paper,
                            in:RoundedRectangle(cornerRadius:11))
                .overlay(RoundedRectangle(cornerRadius:11).strokeBorder(Studio.line.opacity(0.45)))
        }
        .buttonStyle(BlasterTapStyle())
    }

    private func storyCard(_ story:MobileNotice)->some View {
        StudioPanel {
            HStack(alignment:.center,spacing:10) {
                Text(story.category.uppercased())
                    .font(.system(size:10,weight:.bold))
                    .foregroundStyle(Studio.gold)
                Spacer(minLength:0)
                Text(story.createdAt,style:.date)
                    .font(.system(size:10))
                    .foregroundStyle(Studio.secondary)
                Button {
                    var values=saved
                    if values.contains(story.id) { values.remove(story.id) }
                    else { values.insert(story.id) }
                    savedRaw=values.sorted().map(String.init).joined(separator:",")
                    Studio.touch()
                } label: {
                    Image(systemName:saved.contains(story.id) ? "bookmark.fill" : "bookmark")
                        .font(.system(size:15))
                        .foregroundStyle(Studio.gold)
                        .frame(width:28,height:32)
                }
                .accessibilityLabel(saved.contains(story.id) ? "Kaydı kaldır" : "Haberi kaydet")
            }
            Text(story.title)
                .font(.system(size:17,weight:.bold,design:.rounded))
                .foregroundStyle(Studio.ink)
                .fixedSize(horizontal:false,vertical:true)
            Text(story.body)
                .font(.system(size:13))
                .foregroundStyle(Studio.secondary)
                .fixedSize(horizontal:false,vertical:true)
        }
    }
}

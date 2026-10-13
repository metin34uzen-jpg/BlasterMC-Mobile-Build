import SwiftUI

struct AtlasNewsView: View {
    @EnvironmentObject private var session: BlasterSession
    @Environment(\.dismiss) private var dismiss
    @State private var filter = 0
    @State private var query = ""
    @State private var bookmarksOnly = false
    @AppStorage("blaster.v11.news.bookmarks") private var bookmarksRaw = ""

    private var bookmarks: Set<Int> {
        Set(bookmarksRaw.split(separator: ",").compactMap { Int($0) })
    }
    private var stories: [MobileNotice] {
        let items: [MobileNotice]
        switch filter {
        case 1: items = session.announcements
        case 2: items = session.events
        default: items = session.announcements + session.events
        }
        return items.filter {
            (!bookmarksOnly || bookmarks.contains($0.id)) &&
            (query.isEmpty || $0.title.localizedStandardContains(query) ||
             $0.body.localizedStandardContains(query))
        }.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            AtlasScreen {
                AtlasMasthead(label: "Topluluk dergisi / REALM")
                cover
                searchAndFilters
                HStack(alignment: .firstTextBaseline) {
                    AtlasHeading(kicker: "YAYIN AKIŞI", title: "Son hikâyeler")
                    Spacer()
                    Text("\(stories.count) içerik")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Atlas.muted)
                }
                if stories.isEmpty {
                    AtlasEmpty(title: bookmarksOnly ? "Kaydedilmiş haber yok" : "Yeni hikâye bekleniyor",
                               detail: session.dataError ?? "Yeni duyurular ve etkinlikler yayınlandığında burada görünecek.",
                               symbol: "newspaper")
                } else {
                    featuredStory(stories[0])
                    if stories.count > 1 {
                        VStack(spacing: 10) {
                            ForEach(Array(stories.dropFirst())) { story in storyRow(story) }
                        }
                    }
                }
                AtlasAction(title: "Haber akışını yenile",
                            symbol: "arrow.clockwise", secondary: true) {
                    Task { await session.reloadPublic() }
                }
                HStack {
                    Text("BLASTERMC / TOPLULUK")
                    Spacer()
                    Text("REALM 13")
                }
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .tracking(0.7)
                .foregroundStyle(Atlas.muted.opacity(0.8))
                .padding(.horizontal, 3)
            }
            .navigationTitle("Haberler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }.foregroundStyle(Atlas.blue)
                }
            }
            .refreshable { await session.reloadPublic() }
        }
    }

    private var cover: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Atlas.navy, Atlas.deepBlue],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            RealmPortalArt()
                .frame(width: 122, height: 138)
                .opacity(0.43)
                .padding(.trailing, 3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 12) {
                AtlasPill(title: "RESMÎ YAYIN", symbol: "sparkles", highlighted: true)
                Text("Dünyadan\nhaber al.")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Duyurular, etkinlikler ve sunucudan son gelişmeler.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .padding(.trailing, 105)
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var searchAndFilters: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Atlas.blue)
                TextField("Haber, etkinlik veya duyuru ara", text: $query)
                    .font(.system(size: 12))
                    .foregroundStyle(Atlas.ink)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Atlas.muted)
                    }
                }
                Rectangle().fill(Atlas.line).frame(width: 1, height: 23)
                Button {
                    bookmarksOnly.toggle()
                    Atlas.haptic()
                } label: {
                    Image(systemName: bookmarksOnly ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(bookmarksOnly ? Atlas.copper : Atlas.muted)
                        .frame(width: 29, height: 34)
                }
                .accessibilityLabel(bookmarksOnly ? "Tüm haberleri göster" : "Kaydedilen haberleri göster")
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Atlas.line))
            HStack(spacing: 7) {
                filterButton("Tümü", index: 0)
                filterButton("Duyurular", index: 1)
                filterButton("Etkinlikler", index: 2)
            }
        }
    }

    private func filterButton(_ title: String, index: Int) -> some View {
        Button {
            Atlas.haptic()
            filter = index
        } label: {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(filter == index ? .white : Atlas.ink)
                .frame(maxWidth: .infinity, minHeight: 37)
                .background(filter == index ? Atlas.blue : Atlas.paper,
                            in: RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11)
                    .strokeBorder(filter == index ? Atlas.blue : Atlas.line))
        }
        .buttonStyle(.plain)
    }

    private func featuredStory(_ story: MobileNotice) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Atlas.orange).frame(width: 6, height: 6)
                    Text(story.category.uppercased())
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .tracking(0.8)
                        .foregroundStyle(Atlas.orange)
                }
                Spacer()
                Button { toggle(story.id) } label: {
                    Image(systemName: bookmarks.contains(story.id) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 35, height: 35)
                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
                }
                .accessibilityLabel("Haberi kaydet")
            }
            Text(story.title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .tracking(-0.6)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 7)
            Text(story.body)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 9)
            HStack {
                Text(story.createdAt, style: .date)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                Spacer()
                Text("ÖNE ÇIKAN")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .tracking(0.7)
                    .foregroundStyle(Atlas.orange)
            }
            .padding(.top, 17)
        }
        .padding(17)
        .background(LinearGradient(colors: [Atlas.navy, Atlas.deepBlue],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21).strokeBorder(Atlas.aqua.opacity(0.17)))
    }

    private func storyRow(_ story: MobileNotice) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(story.category.localizedCaseInsensitiveContains("etkin") ? Atlas.orange : Atlas.blue)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    AtlasPill(title: story.category, symbol: "newspaper", highlighted: true)
                    Text(story.createdAt, style: .date)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Atlas.muted)
                    Spacer(minLength: 0)
                    Button { toggle(story.id) } label: {
                        Image(systemName: bookmarks.contains(story.id) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(bookmarks.contains(story.id) ? Atlas.copper : Atlas.muted)
                            .frame(width: 30, height: 30)
                    }
                    .accessibilityLabel("Haberi kaydet")
                }
                Text(story.title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(Atlas.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(story.body)
                    .font(.system(size: 11))
                    .foregroundStyle(Atlas.muted)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Atlas.line))
    }

    private func toggle(_ id: Int) {
        var values = bookmarks
        if values.contains(id) { values.remove(id) }
        else { values.insert(id) }
        bookmarksRaw = values.sorted().map(String.init).joined(separator: ",")
        Atlas.haptic()
    }
}

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
                AtlasMasthead(label: "Topluluk / Haberler")
                AtlasBanner(eyebrow: "BLASTER HABERLER") {
                    Text("Dünyadan\nhaberin olsun.")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Duyurular, etkinlikler ve BlasterMC'den son gelişmeler.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.90))
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 8) {
                    filterButton("Tümü", index: 0)
                    filterButton("Duyuru", index: 1)
                    filterButton("Etkinlik", index: 2)
                }
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Atlas.copper)
                    TextField("Haberlerde ara", text: $query)
                        .font(.system(size: 13))
                        .foregroundStyle(Atlas.ink)
                    Button {
                        bookmarksOnly.toggle()
                    } label: {
                        Image(systemName: bookmarksOnly ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(Atlas.copper)
                            .frame(width: 33, height: 34)
                    }
                    .accessibilityLabel("Kaydedilen haberler")
                }
                .padding(12)
                .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Atlas.line))
                AtlasHeading(kicker: "GÜNCEL AKIŞ", title: "Son paylaşımlar",
                             detail: "\(stories.count) içerik")
                if stories.isEmpty {
                    AtlasEmpty(title: "Bu filtrede haber bulunamadı",
                               detail: session.dataError ?? "Henüz yayınlanmış içerik yok.",
                               symbol: "newspaper")
                } else {
                    LazyVStack(spacing: 11) {
                        ForEach(stories) { story in card(story) }
                    }
                }
                AtlasAction(title: "Haberleri yenile", symbol: "arrow.clockwise", secondary: true) {
                    Task { await session.reloadPublic() }
                }
            }
            .navigationTitle("Blaster Haberler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(Atlas.blue)
                }
            }
            .refreshable { await session.reloadPublic() }
        }
    }

    private func filterButton(_ title: String, index: Int) -> some View {
        Button {
            Atlas.haptic()
            filter = index
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(filter == index ? Color.white : Atlas.ink)
                .frame(maxWidth: .infinity, minHeight: 43)
                .background(filter == index ? Atlas.blue : Atlas.paper,
                            in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(filter == index ? Atlas.blue : Atlas.line))
        }
        .buttonStyle(.plain)
    }

    private func card(_ story: MobileNotice) -> some View {
        AtlasCard {
            HStack(spacing: 9) {
                AtlasPill(title: story.category, symbol: "megaphone", highlighted: true)
                Spacer()
                Text(story.createdAt, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(Atlas.muted)
                Button { toggle(story.id) } label: {
                    Image(systemName: bookmarks.contains(story.id) ?
                          "bookmark.fill" : "bookmark")
                        .foregroundStyle(Atlas.copper)
                        .frame(width: 35, height: 35)
                }
                .accessibilityLabel("Haberi kaydet")
            }
            Text(story.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Atlas.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(story.body)
                .font(.system(size: 13))
                .foregroundStyle(Atlas.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func toggle(_ id: Int) {
        var values = bookmarks
        if values.contains(id) { values.remove(id) }
        else { values.insert(id) }
        bookmarksRaw = values.sorted().map(String.init).joined(separator: ",")
        Atlas.haptic()
    }
}

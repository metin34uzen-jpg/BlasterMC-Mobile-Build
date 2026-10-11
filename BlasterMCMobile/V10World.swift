import SwiftUI

/// A client-side exploration guide. Commands are copied to the clipboard;
/// no in-game action is claimed until the actual Minecraft server performs it.
struct V10WorldView: View {
    @ObservedObject var server: ServerStatusModel
    @EnvironmentObject private var session: BlasterSession
    @Environment(\.scenePhase) private var scenePhase
    @State private var realm = 0
    @State private var copied: String?
    @State private var showNews = false

    private let pages: [(name: String, label: String, title: String, detail: String, symbol: String)] = [
        ("SKYBLOCK", "ADA DÜNYASI", "Gökyüzünde\nkendi krallığın.", "Kendi adanı kur, geliştir ve sezonun zirvesi için mücadele et.", "square.stack.3d.up.fill"),
        ("LOBI", "BAŞLANGIÇ NOKTASI", "Her macera\nburada başlar.", "Dünya geçişleri, etkinlikler ve topluluğa açılan ana merkez.", "building.2.crop.circle.fill"),
        ("TOPLULUK", "BİRLİKTE DAHA GÜÇLÜ", "Oyundan çok\ndaha fazlası.", "Haberleri takip et, arkadaşlarınla sunucu adresini paylaş.", "person.3.sequence.fill")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    heading
                    realmTabs
                    spotlight
                    serverAccess
                    starterGuide
                    communityActions
                    footer
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 36)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background(PremiumBackground())
            .navigationTitle("Dünya Merkezi")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showNews) {
                NewsView().environmentObject(session)
            }
            .refreshable {
                await server.refresh()
                await session.reloadPublic()
            }
            .task {
                if !server.hasConfirmedStatus { await server.refresh() }
            }
        }
    }

    private var heading: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BLASTERMC / WORLD ATLAS")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1.8)
                    .foregroundStyle(V10.gold)
                Text("Sınırların ötesi.")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .tracking(-0.9)
                    .foregroundStyle(V10.ink)
                Text("BlasterMC evreninin tüm kapıları burada.")
                    .font(.caption)
                    .foregroundStyle(BlasterTheme.muted)
            }
            Spacer(minLength: 0)
            BlasterLogo(size: 65)
        }
    }

    private var realmTabs: some View {
        HStack(spacing: 7) {
            ForEach(pages.indices, id: \.self) { index in
                Button {
                    V10.tap()
                    withAnimation(.easeInOut(duration: 0.25)) { realm = index }
                } label: {
                    Text(pages[index].name)
                        .font(.system(size: 10, weight: .black))
                        .tracking(0.4)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(realm == index ? BlasterTheme.cream : V10.ink)
                        .background(realm == index ? V10.ink : .white,
                                    in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13)
                            .strokeBorder(V10.gold.opacity(realm == index ? 0.54 : 0.12)))
                }
                .buttonStyle(BlasterTapStyle())
            }
        }
    }

    private var spotlight: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(colors: [
                    V10.ink,
                    Color(red: 0.26, green: 0.31, blue: 0.40),
                    Color(red: 0.40, green: 0.29, blue: 0.19)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
            if realm == 0 {
                SkyWorldView()
                    .opacity(0.57)
                    .transition(.opacity)
            } else {
                Image(systemName: pages[realm].symbol)
                    .font(.system(size: 155, weight: .ultraLight))
                    .foregroundStyle(V10.bright.opacity(0.16))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.trailing, -12)
            }
            LinearGradient(colors: [V10.ink.opacity(0.87), V10.ink.opacity(0.27)],
                           startPoint: .leading, endPoint: .trailing)
            V10SparkField()
            VStack(alignment: .leading, spacing: 11) {
                V10Tag(text: pages[realm].label, symbol: pages[realm].symbol, dark: true)
                Spacer(minLength: 25)
                Text(pages[realm].title)
                    .font(.system(size: 35, weight: .black, design: .rounded))
                    .tracking(-1.1)
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
                Text(pages[realm].detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
            .padding(25)
        }
        .frame(height: 308)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30)
            .strokeBorder(V10.bright.opacity(0.32), lineWidth: 1))
        .id(realm)
    }

    private var serverAccess: some View {
        VStack(alignment: .leading, spacing: 13) {
            V10Heading(eyebrow: "QUICK CONNECT / MINECRAFT",
                       title: "Sunucuya bağlan",
                       detail: "Minecraft Java Edition'da çok oyunculu sunucu adresi")
            V10Plate {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(!server.hasConfirmedStatus || server.isStale ? .orange :
                                      (server.isOnline ? .green : .red))
                                .frame(width: 8, height: 8)
                            Text(server.statusText)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(V10.ink)
                        }
                        Spacer()
                        if server.hasConfirmedStatus {
                            Text("\(server.onlinePlayers) oyuncu")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(V10.gold)
                        }
                    }
                    V10Divider()
                    Text("SUNUCU ADRESİ")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.7)
                        .foregroundStyle(BlasterTheme.muted)
                    Text("oyna.blastermc.com")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .tracking(-0.7)
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                        .foregroundStyle(V10.ink)
                    HStack(spacing: 9) {
                        Button {
                            V10.copy("oyna.blastermc.com")
                            copied = "oyna.blastermc.com"
                        } label: {
                            Label(copied == "oyna.blastermc.com" ? "KOPYALANDI" : "ADRESİ KOPYALA",
                                  systemImage: copied == "oyna.blastermc.com" ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(V10.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(V10.bright, in: RoundedRectangle(cornerRadius: 13))
                        }
                        ShareLink(item: "oyna.blastermc.com") {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundStyle(V10.ink)
                                .frame(width: 48, height: 45)
                                .background(V10.soft, in: RoundedRectangle(cornerRadius: 13))
                        }
                    }
                    .buttonStyle(BlasterTapStyle())
                }
            }
        }
    }

    private var starterGuide: some View {
        VStack(alignment: .leading, spacing: 13) {
            V10Heading(eyebrow: "STARTER / FIELD GUIDE",
                       title: realm == 0 ? "Ada rehberin" : (realm == 1 ? "Lobi rehberin" : "Topluluk rotası"),
                       detail: "İşine yarayan kısayollar ve pratik bilgiler")
            if realm == 0 {
                commandRow("/is", title: "Ada menüsü", subtitle: "BSkyBlock ada komutları")
                commandRow("/is home", title: "Adana dön", subtitle: "Ada evine ışınlanmayı dene")
                commandRow("/is top", title: "Ada sıralaması", subtitle: "Sürümüne göre kullanılabilir")
            } else if realm == 1 {
                commandRow("/lobi", title: "Lobiye git", subtitle: "Sunucu içindeki ana merkeze dönüş")
                infoRow("Çok oyunculu", text: "Sunucu listesinden BlasterMC adresini seç.", symbol: "gamecontroller.fill")
                infoRow("Etkinlikler", text: "Güncel duyurulara Haberler bölümünden eriş.", symbol: "calendar.badge.clock")
            } else {
                infoRow("Oyuncu hesabın", text: "Profilinden Blaster ID ve gerçek kredi bakiyeni görüntüle.", symbol: "person.text.rectangle")
                infoRow("Sezon rekabeti", text: "Sezon sekmesinden liderlik tablosuna göz at.", symbol: "trophy.fill")
                infoRow("Duyurular", text: "Yeni içerikler Haberler ekranında gösterilir.", symbol: "bell.badge")
            }
            Text("Komutlar uygulamada çalıştırılmaz; panoya kopyalanır. Sunucu ayarlarına göre bazı komutlar değişebilir.")
                .font(.caption2)
                .foregroundStyle(BlasterTheme.muted)
        }
    }

    private func commandRow(_ command: String, title: String, subtitle: String) -> some View {
        Button {
            V10.copy(command)
            copied = command
        } label: {
            V10Plate {
                HStack(spacing: 12) {
                    Image(systemName: copied == command ? "checkmark.circle.fill" : "terminal.fill")
                        .font(.title3)
                        .foregroundStyle(V10.gold)
                        .frame(width: 42, height: 42)
                        .background(V10.gold.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(V10.ink)
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(BlasterTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Text(command)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(V10.gold)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(BlasterTapStyle())
        .accessibilityHint("Komutu panoya kopyala")
    }

    private func infoRow(_ title: String, text: String, symbol: String) -> some View {
        V10Plate {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(V10.gold)
                    .frame(width: 38)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(V10.ink)
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                }
            }
        }
    }

    private var communityActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            V10Heading(eyebrow: "CONNECT / COMMUNITY",
                       title: "Her yerden BlasterMC",
                       detail: "Güvenli bağlantılar")
            HStack(spacing: 10) {
                Link(destination: URL(string: "https://blastermc.com")!) {
                    V10LinkTile(name: "Web sitesi", subtitle: "Resmî portal", symbol: "globe")
                }
                Link(destination: URL(string: "https://discord.blastermc.com")!) {
                    V10LinkTile(name: "Discord", subtitle: "Topluluğa katıl", symbol: "person.3.fill")
                }
            }
            Button {
                showNews = true
            } label: {
                V10Plate {
                    HStack {
                        Label("DUYURU MERKEZİNİ AÇ", systemImage: "megaphone.fill")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(V10.ink)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(V10.gold)
                    }
                }
            }
            .buttonStyle(BlasterTapStyle())
        }
    }

    private var footer: some View {
        HStack(spacing: 7) {
            Image(systemName: "shield.checkered")
                .foregroundStyle(V10.gold)
            Text("BLASTERMC  •  WORLD ATLAS v10")
                .font(.system(size: 10, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(BlasterTheme.muted)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct V10LinkTile: View {
    let name: String
    let subtitle: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 23))
                .foregroundStyle(V10.gold)
            Text(name)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(V10.ink)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(BlasterTheme.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 105, alignment: .leading)
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21).strokeBorder(V10.line))
    }
}

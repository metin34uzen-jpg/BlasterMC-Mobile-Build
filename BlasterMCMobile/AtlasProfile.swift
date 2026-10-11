import SwiftUI

struct AtlasProfileView: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var confirmLogout = false
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AtlasScreen {
                    AtlasMasthead(label: "Blaster ID / Profil")
                    identity
                    wallet
                    presence
                    if session.isAdministrator {
                        administrator
                    }
                    security
                    links
                }
                .frame(maxHeight: .infinity)
                .refreshable { await session.reloadProfile() }
                logoutDock
            }
            .background(AtlasBackground())
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("BlasterMC hesabından çıkış yapılsın mı?",
                                isPresented: $confirmLogout,
                                titleVisibility: .visible) {
                Button("Güvenli çıkış yap", role: .destructive) {
                    session.signOut()
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Bu cihazdaki oturum anahtarı silinecek ve oturum sonlandırılacak.")
            }
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "OYUNCU KİMLİĞİ", title: "Senin Blaster ID'n")
            AtlasCard {
                HStack(alignment: .top, spacing: 14) {
                    avatar
                    VStack(alignment: .leading, spacing: 7) {
                        Text("MINECRAFT OYUNCUSU")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Atlas.copper)
                        Text(session.profile?.minecraftName ?? "Oyuncu")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(Atlas.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(session.profile?.rank ?? "Rütbe bekleniyor")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Atlas.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                AtlasRule()
                Text("BLASTER ID")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Atlas.copper)
                Text(session.profile?.blasterId ?? "—")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(Atlas.ink)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    guard let id = session.profile?.blasterId, !id.isEmpty else { return }
                    Atlas.copy(id)
                    copied = true
                } label: {
                    Label(copied ? "Kimlik kopyalandı" : "Blaster ID'yi kopyala",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Atlas.blue)
                        .frame(minHeight: 34)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17).fill(Atlas.blueLight)
            if let url = session.profile?.skinUrl {
                AsyncImage(url: url) { image in image.resizable().scaledToFit() }
                    placeholder: { BlasterLogo(size: 53) }
                    .padding(6)
            } else {
                BlasterLogo(size: 53)
            }
        }
        .frame(width: 84, height: 94)
        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Atlas.line))
    }

    private var wallet: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "OYUNCU CÜZDANI", title: "Kredi bakiyen")
            AtlasCard(tinted: true) {
                HStack(spacing: 12) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Atlas.copper)
                        .frame(width: 42)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\((session.profile?.credits ?? 0).formatted())")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(Atlas.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("BLASTER KREDİ")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Atlas.copper)
                    }
                    Spacer()
                    Image(systemName: "lock.shield").foregroundStyle(Atlas.blue)
                }
            }
        }
    }

    private var presence: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "HESAP DURUMU", title: "Aktiflik bilgilerin")
            presenceRow("Minecraft", symbol: "gamecontroller.fill", value: session.profile?.inGame)
            presenceRow("Web sitesi", symbol: "globe", value: session.profile?.onSite)
        }
    }

    private func presenceRow(_ title: String, symbol: String, value: Bool?) -> some View {
        AtlasCard(inset: 14) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(Atlas.copper)
                    .frame(width: 27)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Atlas.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Circle()
                    .fill(value == true ? Color.green : value == false ? Color.gray : Color.orange)
                    .frame(width: 7, height: 7)
                Text(value == nil ? "Bilinmiyor" : value == true ? "Aktif" : "Çevrimdışı")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Atlas.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // Only the server-supplied isAdmin flag can expose the route.
    private var administrator: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "YETKİLİ ERİŞİM", title: "Yönetim merkezi")
            NavigationLink {
                AtlasAdminView()
                    .environmentObject(session)
            } label: {
                AtlasCard(tinted: true) {
                    HStack(spacing: 12) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 23))
                            .foregroundStyle(Atlas.copper)
                            .frame(width: 40)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("BLASTER CONTROL")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundStyle(Atlas.ink)
                            Text("Servisler ve yönetici bildirimleri")
                                .font(.system(size: 12))
                                .foregroundStyle(Atlas.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Atlas.blue)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var security: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "GÜVENLİK", title: "Oturum koruması")
            AtlasCard {
                Label("Şifre ve oturum güvenliği", systemImage: "checkmark.shield.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Atlas.ink)
                Text("Şifren cihazda tutulmaz. Oturum anahtarı Keychain'de korunur ve 15 dakikalık oturum süresi uygulanır.")
                    .font(.system(size: 12))
                    .foregroundStyle(Atlas.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if let date = session.loggedInAt {
                    Text("Oturum bitişi: \(date.addingTimeInterval(900), style: .time)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Atlas.copper)
                }
                AtlasAction(title: "Hesap bilgilerini yenile",
                            symbol: "arrow.clockwise", secondary: true) {
                    Task { await session.reloadProfile() }
                }
            }
        }
    }

    private var links: some View {
        HStack(spacing: 10) {
            Link(destination: URL(string: "https://blastermc.com")!) {
                Label("Web sitesi", systemImage: "globe")
                    .frame(maxWidth: .infinity, minHeight: 45)
            }
            Link(destination: URL(string: "https://discord.blastermc.com")!) {
                Label("Discord", systemImage: "person.2.fill")
                    .frame(maxWidth: .infinity, minHeight: 45)
            }
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(Atlas.blue)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Atlas.line))
    }

    // Fixed, safe-area aware, above the bottom tab dock. Never below scrolling content.
    private var logoutDock: some View {
        VStack(spacing: 0) {
            AtlasRule()
            Button {
                confirmLogout = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Güvenli çıkış yap")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Atlas.danger)
                .padding(.horizontal, 18)
                .frame(maxWidth: 640, minHeight: 50)
                .frame(maxWidth: .infinity)
                .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
        }
        .background(Atlas.canvas)
    }
}

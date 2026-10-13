import SwiftUI

struct AtlasProfileView: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var confirmLogout = false
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AtlasScreen {
                    AtlasMasthead(label: "Oyuncu kimliği / REALM")
                    identityCard
                    walletPanel
                    presencePanel
                    if session.isAdministrator { administratorPanel }
                    securityPanel
                    accountLinks
                    appSignature
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
                Button("Güvenli çıkış yap", role: .destructive) { session.signOut() }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Bu cihazdaki oturum anahtarı silinecek ve oturum sonlandırılacak.")
            }
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 22)
                    .fill(LinearGradient(colors: [Atlas.navy, Atlas.deepBlue],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                RealmPortalArt()
                    .frame(width: 125, height: 130)
                    .opacity(0.26)
                    .padding(.trailing, 4)
                    .padding(.top, 5)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        AtlasPill(title: "BLASTER ID", symbol: "person.crop.square", highlighted: true)
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Atlas.aqua)
                    }
                    HStack(alignment: .center, spacing: 13) {
                        avatar
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.profile?.minecraftName ?? "Oyuncu")
                                .font(.system(size: 21, weight: .black, design: .rounded))
                                .tracking(-0.5)
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(session.profile?.rank ?? "BlasterMC oyuncusu")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Atlas.orange)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("@\(session.profile?.username ?? "hesap")")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.68))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Rectangle().fill(.white.opacity(0.17)).frame(height: 1)
                    HStack(alignment: .center, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OYUNCU NUMARASI")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .tracking(0.6)
                                .foregroundStyle(.white.opacity(0.65))
                            Text(session.profile?.blasterId ?? "—")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                                .textSelection(.enabled)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Button {
                            guard let id = session.profile?.blasterId, !id.isEmpty else { return }
                            Atlas.copy(id)
                            copied = true
                        } label: {
                            Label(copied ? "KOPYALANDI" : "KOPYALA",
                                  systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundStyle(Atlas.navy)
                                .padding(.horizontal, 10)
                                .frame(height: 32)
                                .background(Atlas.orange, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(17)
            }
            .fixedSize(horizontal: false, vertical: true)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Atlas.aqua.opacity(0.2)))
        }
    }

    private var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Atlas.blueLight)
            if let url = session.profile?.skinUrl {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        BlasterLogo(size: 46)
                    }
                }
                .padding(5)
            } else {
                BlasterLogo(size: 46)
            }
        }
        .frame(width: 76, height: 82)
        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(.white.opacity(0.2)))
    }

    private var walletPanel: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "OYUNCU ENVANTERİ", title: "Cüzdanın")
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Atlas.navy)
                        .frame(width: 37, height: 37)
                        .background(Atlas.orange, in: RoundedRectangle(cornerRadius: 12))
                    Text("\((session.profile?.credits ?? 0).formatted())")
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("BLASTER KREDİ")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .tracking(0.5)
                        .foregroundStyle(Atlas.copper)
                }
                .frame(maxWidth: .infinity, minHeight: 115, alignment: .leading)
                .padding(14)
                .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Atlas.line))
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Atlas.blue)
                        .frame(width: 37, height: 37)
                        .background(Atlas.blueLight, in: RoundedRectangle(cornerRadius: 12))
                    Text(session.loggedInAt.map {
                        $0.addingTimeInterval(900).formatted(date: .omitted, time: .shortened)
                    } ?? "—")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Atlas.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    Text("OTURUM BİTİŞİ")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .tracking(0.5)
                        .foregroundStyle(Atlas.copper)
                }
                .frame(maxWidth: .infinity, minHeight: 115, alignment: .leading)
                .padding(14)
                .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Atlas.line))
            }
        }
    }

    private var presencePanel: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "CANLI DURUM", title: "Neredesin?")
            HStack(spacing: 9) {
                presenceTile("Minecraft", subtitle: "Oyun içi", value: session.profile?.inGame,
                             icon: "gamecontroller.fill")
                presenceTile("BlasterMC", subtitle: "Web hesabı", value: session.profile?.onSite,
                             icon: "globe")
            }
        }
    }

    private func presenceTile(_ title: String, subtitle: String, value: Bool?, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Atlas.blue)
                Spacer()
                Circle()
                    .fill(value == true ? Atlas.mint : value == false ? Atlas.line : Atlas.orange)
                    .frame(width: 8, height: 8)
            }
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(Atlas.ink)
            Text(subtitle)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Atlas.muted)
            Text(value == nil ? "Bilinmiyor" : value == true ? "Çevrimiçi" : "Çevrimdışı")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(value == true ? Atlas.mint : Atlas.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .padding(13)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Atlas.line))
    }

    private var administratorPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            AtlasHeading(kicker: "YETKİLİ ERİŞİM", title: "Kontrol odası")
            NavigationLink {
                AtlasAdminView().environmentObject(session)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13).fill(Atlas.navy)
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(Atlas.orange)
                    }
                    .frame(width: 43, height: 43)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BLASTER CONTROL")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(Atlas.ink)
                        Text("Servis sağlığı ve yönetici bildirimleri")
                            .font(.system(size: 10))
                            .foregroundStyle(Atlas.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Atlas.blue)
                }
                .padding(13)
                .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Atlas.line))
            }
            .buttonStyle(.plain)
        }
    }

    private var securityPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            AtlasHeading(kicker: "HESAP GÜVENLİĞİ", title: "Oturum koruması")
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Atlas.mint)
                    .frame(width: 31)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Oturum anahtarı cihazında korunuyor")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(Atlas.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Şifren cihazda saklanmaz. Oturum anahtarı iOS Keychain'de tutulur ve 15 dakika sonunda sona erer.")
                        .font(.system(size: 11))
                        .foregroundStyle(Atlas.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(15)
            .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(Atlas.line))
            AtlasAction(title: "Hesap bilgilerini yenile",
                        symbol: "arrow.clockwise", secondary: true) {
                Task { await session.reloadProfile() }
            }
        }
    }

    private var accountLinks: some View {
        HStack(spacing: 10) {
            Link(destination: URL(string: "https://blastermc.com")!) {
                Label("Web sitesi", systemImage: "globe")
                    .frame(maxWidth: .infinity, minHeight: 43)
            }
            Link(destination: URL(string: "https://discord.blastermc.com")!) {
                Label("Discord", systemImage: "bubble.left.and.bubble.right")
                    .frame(maxWidth: .infinity, minHeight: 43)
            }
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(Atlas.blue)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Atlas.line))
    }

    private var appSignature: some View {
        HStack(spacing: 8) {
            AtlasPixelSignature()
            VStack(alignment: .leading, spacing: 3) {
                Text("BLASTERMC MOBILE")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(Atlas.ink)
                Text("REALM 13 / Oyuncu deneyimi")
                    .font(.system(size: 9))
                    .foregroundStyle(Atlas.muted)
            }
            Spacer()
            Text("iOS")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(Atlas.copper)
        }
        .padding(.horizontal, 3)
        .padding(.bottom, 4)
    }

    private var logoutDock: some View {
        VStack(spacing: 0) {
            AtlasRule()
            Button { confirmLogout = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Güvenli çıkış yap")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Atlas.danger)
                .padding(.horizontal, 17)
                .frame(maxWidth: 640, minHeight: 48)
                .frame(maxWidth: .infinity)
                .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 13))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
        }
        .background(Atlas.canvas)
    }
}

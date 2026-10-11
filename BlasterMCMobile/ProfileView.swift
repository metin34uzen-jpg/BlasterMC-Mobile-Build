import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: BlasterSession

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    playerHero
                    SectionHeader(title: "Oyuncu kimliğin", caption: "BlasterMC evrenindeki resmî profilin")
                    playerOverview
                    if session.isAdministrator { adminEntry }
                    wallet
                    activity
                    accountSecurity
                    Button {
                        session.signOut()
                    } label: {
                        Label("Güvenli çıkış yap", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(15)
                            .background(BlasterTheme.paper, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(BlasterTapStyle())
                }
                .padding(18)
                .padding(.bottom, 28)
            }
            .background(PremiumBackground())
            .navigationTitle("Oyuncu Profili")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await session.reloadProfile() }
        }
    }

    private var playerHero: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 29)
                .fill(LinearGradient(colors: [
                    BlasterTheme.navy,
                    Color(red: 0.29, green: 0.28, blue: 0.28),
                    BlasterTheme.copper
                ], startPoint: .topLeading, endPoint: .bottomTrailing))

            HStack(alignment: .center, spacing: 15) {
                avatar(size: 98)
                VStack(alignment: .leading, spacing: 8) {
                    Text("BLASTERMC / PLAYER")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(BlasterTheme.amber)
                    Text(session.profile?.minecraftName ?? "Oyuncu")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                    Text(session.profile?.rank ?? "Rütbe bekleniyor")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BlasterTheme.cream)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.12), in: Capsule())
                }
            }
            .padding(21)
        }
        .frame(maxWidth: .infinity)
        .overlay(RoundedRectangle(cornerRadius: 29)
            .strokeBorder(BlasterTheme.amber.opacity(0.25), lineWidth: 1))
        .shadow(color: BlasterTheme.navy.opacity(0.16), radius: 22, y: 11)
    }

    private func avatar(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 21)
                .fill(BlasterTheme.cream.opacity(0.14))
            if let url = session.profile?.skinUrl {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    BlasterLogo(size: size * 0.76)
                }
                .padding(7)
            } else {
                BlasterLogo(size: size * 0.76)
            }
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: 21)
            .strokeBorder(BlasterTheme.amber.opacity(0.45), lineWidth: 1.3))
    }

    private var playerOverview: some View {
        BlasterCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Label("BLASTER ID", systemImage: "person.text.rectangle")
                        .font(.caption.weight(.heavy))
                        .tracking(1)
                        .foregroundStyle(BlasterTheme.gold)
                    Spacer()
                    Text(session.profile?.blasterId ?? "—")
                        .font(.subheadline.monospaced().bold())
                        .foregroundStyle(BlasterTheme.ink)
                }
                Divider().overlay(BlasterTheme.gold.opacity(0.15))
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(BlasterTheme.gold)
                    Text("Doğrulanmış oyuncu hesabı")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var adminEntry: some View {
        NavigationLink {
            AdminCenterView()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(BlasterTheme.amber)
                    .frame(width: 55, height: 55)
                    .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 6) {
                    Text("BLASTER CONTROL")
                        .font(.headline.weight(.black))
                        .tracking(1)
                        .foregroundStyle(.white)
                    Text("Yönetici paneli • Sunucu • Web • Discord")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer(minLength: 2)
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(BlasterTheme.amber)
            }
            .padding(19)
            .background(BlasterTheme.navy, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22)
                .strokeBorder(BlasterTheme.amber.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(BlasterTapStyle())
    }

    private var wallet: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Blaster Cüzdanı", caption: "Gerçek bakiyen, gerçek hesabından")
            BlasterCard {
                HStack(spacing: 13) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 35))
                        .foregroundStyle(BlasterTheme.gold)
                        .frame(width: 61, height: 61)
                        .background(BlasterTheme.cream, in: RoundedRectangle(cornerRadius: 17))
                    VStack(alignment: .leading, spacing: 5) {
                        Text("MEVCUT KREDİ")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1.3)
                            .foregroundStyle(BlasterTheme.muted)
                        Text((session.profile?.credits ?? 0).formatted())
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(BlasterTheme.navy)
                    }
                    Spacer()
                    BlasterLogo(size: 39)
                }
            }
        }
    }

    private var activity: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Aktiflik Merkezi", caption: "Oyun ve web hesabı durumların")
            HStack(spacing: 11) {
                presenceCard(title: "Minecraft", symbol: "gamecontroller.fill",
                             active: session.profile?.inGame)
                presenceCard(title: "Web Hesabı", symbol: "globe",
                             active: session.profile?.onSite)
            }
        }
    }

    private func presenceCard(title: String, symbol: String, active: Bool?) -> some View {
        BlasterCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(BlasterTheme.gold)
                Text(title).font(.subheadline.weight(.bold))
                HStack(spacing: 6) {
                    Circle()
                        .fill(active == true ? Color.green : Color.gray)
                        .frame(width: 7, height: 7)
                    Text(active == nil ? "Bilinmiyor" : (active == true ? "Aktif" : "Çevrimdışı"))
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                }
            }
        }
    }

    private var accountSecurity: some View {
        BlasterCard {
            VStack(alignment: .leading, spacing: 13) {
                Label("Hesap güvenliği", systemImage: "lock.shield.fill")
                    .font(.headline)
                    .foregroundStyle(BlasterTheme.ink)
                Text("Oturumun girişten 15 dakika sonra otomatik sonlandırılır. Şifren kaydedilmez; anahtar iPhone'un güvenli alanında tutulur.")
                    .font(.caption)
                    .foregroundStyle(BlasterTheme.muted)
                if let login = session.loggedInAt {
                    Label("Oturum bitişi: \(login.addingTimeInterval(900), style: .time)",
                          systemImage: "clock")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BlasterTheme.gold)
                }
                GoldButton(title: "HESAP BİLGİLERİMİ YENİLE", symbol: "arrow.clockwise") {
                    Task { await session.reloadProfile() }
                }
            }
        }
    }
}

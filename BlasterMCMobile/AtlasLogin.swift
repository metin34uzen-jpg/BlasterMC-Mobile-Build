import SwiftUI

struct AtlasSplash: View {
    @State private var ready = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Atlas.navy, Atlas.deepBlue, Atlas.blue],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            RealmPortalArt()
                .frame(width: 280, height: 320)
                .opacity(0.6)
                .offset(y: -45)
                .accessibilityHidden(true)
            VStack(spacing: 13) {
                BlasterLogo(size: 93)
                    .opacity(ready ? 1 : 0.65)
                    .scaleEffect(ready ? 1 : 0.9)
                    .shadow(color: Atlas.aqua.opacity(0.24), radius: 18)
                Text("BLASTERMC")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .tracking(2.0)
                    .foregroundStyle(.white)
                Text("YOUR WORLD. YOUR LEGACY.")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(Atlas.orange)
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index == 0 ? Atlas.orange : .white.opacity(0.35))
                            .frame(width: index == 0 ? 24 : 6, height: 4)
                    }
                }
                .padding(.top, 7)
            }
            .padding(30)
            .offset(y: 80)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) { ready = true }
        }
    }
}

struct AtlasLoginView: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var username = ""
    @State private var password = ""
    @State private var code = ""
    @State private var reveal = false
    @FocusState private var focus: Field?
    private enum Field: Hashable { case user, password, code }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                loginCover
                form
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Atlas.mint)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hesabın güvende")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(Atlas.ink)
                        Text("Giriş bilgilerin BlasterMC API'sinde doğrulanır. Şifren cihazda tutulmaz; oturum anahtarı iOS Keychain'de korunur.")
                            .font(.system(size: 10))
                            .foregroundStyle(Atlas.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 18)
            }
            .padding(.horizontal, 17)
            .padding(.top, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(AtlasBackground())
        .scrollDismissesKeyboard(.interactively)
    }

    private var loginCover: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Atlas.navy, Atlas.deepBlue],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            RealmPortalArt()
                .frame(width: 118, height: 135)
                .opacity(0.45)
                .padding(.trailing, 3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 9) {
                    BlasterLogo(size: 42)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("BLASTERMC")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .tracking(0.3)
                            .foregroundStyle(.white)
                        Text("MOBILE / REALM 13")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .tracking(0.8)
                            .foregroundStyle(Atlas.orange)
                    }
                }
                Text(session.mfaChallenge == nil ? "Dünyana\ngiriş yap." : "Hesabını\ndoğrula.")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .tracking(-0.7)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(session.mfaChallenge == nil ?
                     "SkyBlock, sezonun ve topluluğun seni bekliyor." :
                     "Authenticator veya kurtarma kodunu kullan.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .padding(.trailing, 95)
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            AtlasHeading(kicker: session.mfaChallenge == nil ? "BLASTER ID" : "İKİ AŞAMALI DOĞRULAMA",
                         title: session.mfaChallenge == nil ? "Tekrar hoş geldin" : "Güvenlik kontrolü",
                         detail: session.mfaChallenge == nil ?
                         "Oyuncu hesabınla güvenli biçimde devam et." :
                         "Devam etmek için doğrulama kodunu gir.")
            if session.mfaChallenge == nil {
                input("KULLANICI ADI", symbol: "person.crop.circle") {
                    TextField("Minecraft kullanıcı adın", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .user)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                }
                input("ŞİFRE", symbol: "lock.fill") {
                    HStack(spacing: 8) {
                        Group {
                            if reveal { TextField("Şifren", text: $password) }
                            else { SecureField("Şifren", text: $password) }
                        }
                        .textContentType(.password)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await signIn() } }
                        Button { reveal.toggle() } label: {
                            Image(systemName: reveal ? "eye.slash" : "eye")
                                .foregroundStyle(Atlas.blue)
                        }
                        .accessibilityLabel(reveal ? "Şifreyi gizle" : "Şifreyi göster")
                    }
                }
            } else {
                input("DOĞRULAMA KODU", symbol: "checkmark.shield.fill") {
                    TextField("Authenticator kodu", text: $code)
                        .textContentType(.oneTimeCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .code)
                        .submitLabel(.go)
                        .onSubmit { Task { await verify() } }
                }
            }
            if let error = session.error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Atlas.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                focus = nil
                Task {
                    if session.mfaChallenge == nil { await signIn() }
                    else { await verify() }
                }
            } label: {
                HStack {
                    Text(session.isBusy ? "DOĞRULANIYOR…" :
                         session.mfaChallenge == nil ? "GÜVENLİ GİRİŞ YAP" : "KODU DOĞRULA")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(0.5)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .black))
                        .frame(width: 30, height: 30)
                        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 15)
                .frame(height: 51)
                .background(Atlas.blue, in: RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .disabled(session.isBusy)
        }
        .padding(18)
        .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21).strokeBorder(Atlas.line))
        .shadow(color: Atlas.navy.opacity(0.045), radius: 13, x: 0, y: 4)
    }

    private func input<Content: View>(_ label: String, symbol: String,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(label, systemImage: symbol)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(Atlas.copper)
            content()
                .font(.system(size: 13))
                .foregroundStyle(Atlas.ink)
                .tint(Atlas.blue)
                .padding(.horizontal, 13)
                .frame(minHeight: 46)
                .background(Atlas.canvas, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Atlas.line))
        }
    }

    private func signIn() async {
        await session.signIn(username: username, password: password)
        password = ""
    }
    private func verify() async {
        await session.verifyMFA(code: code)
        code = ""
    }
}

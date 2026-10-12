import SwiftUI

struct AtlasSplash: View {
    @State private var ready = false

    var body: some View {
        ZStack {
            Atlas.blue.ignoresSafeArea()
            VStack(spacing: 17) {
                AtlasPixelSignature()
                    .scaleEffect(1.7)
                    .padding(.bottom, 12)
                BlasterLogo(size: 104)
                    .opacity(ready ? 1 : 0.55)
                    .scaleEffect(ready ? 1 : 0.94)
                Text("BLASTERMC")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .tracking(2.1)
                    .foregroundStyle(.white)
                Text("MOBILE  /  AURORA 12")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Atlas.orange)
                Capsule().fill(Atlas.orange).frame(width: 68, height: 3)
            }
            .padding(30)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { ready = true }
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
            VStack(alignment: .leading, spacing: 20) {
                AtlasMasthead(label: "Güvenli giriş / AURORA")
                AtlasBanner(eyebrow: "BLASTERMC  /  PLAYER ACCESS") {
                    Text("Yeni bir dünya.\nTek bir hesap.")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("SkyBlock, sezon, mağaza ve topluluğun tek bir girişte.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.89))
                        .fixedSize(horizontal: false, vertical: true)
                }
                form
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(Atlas.copper)
                    Text("Giriş bilgilerin doğrudan BlasterMC API'sinde doğrulanır. Şifren cihazda saklanmaz; oturum anahtarı Keychain ile korunur.")
                        .font(.system(size: 11))
                        .foregroundStyle(Atlas.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 5)
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 32)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(AtlasBackground())
        .scrollDismissesKeyboard(.interactively)
    }

    private var form: some View {
        AtlasCard(inset: 19, spacing: 17) {
            AtlasHeading(kicker: session.mfaChallenge == nil ? "BLASTER ID" : "İKİ AŞAMALI KORUMA",
                         title: session.mfaChallenge == nil ? "Hesabına giriş yap" : "Doğrulama kodu",
                         detail: session.mfaChallenge == nil ?
                         "Kullanıcı adın ve şifrenle devam et." :
                         "Authenticator veya kurtarma kodunu gir.")
            if session.mfaChallenge == nil {
                input("MINECRAFT KULLANICI ADI", symbol: "person.crop.circle") {
                    TextField("Oyuncu adın", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .user)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                }
                input("ŞİFRE", symbol: "lock") {
                    HStack(spacing: 8) {
                        Group {
                            if reveal {
                                TextField("Şifren", text: $password)
                            } else {
                                SecureField("Şifren", text: $password)
                            }
                        }
                        .textContentType(.password)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await signIn() } }
                        Button { reveal.toggle() } label: {
                            Image(systemName: reveal ? "eye.slash" : "eye")
                                .foregroundStyle(Atlas.copper)
                        }
                        .accessibilityLabel(reveal ? "Şifreyi gizle" : "Şifreyi göster")
                    }
                }
            } else {
                input("DOĞRULAMA KODU", symbol: "checkmark.shield") {
                    TextField("Kod", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .code)
                        .submitLabel(.go)
                        .onSubmit { Task { await verify() } }
                }
            }
            if let error = session.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 12))
                    .foregroundStyle(Atlas.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
            AtlasAction(title: session.isBusy ? "Doğrulanıyor…" :
                        session.mfaChallenge == nil ? "Güvenli giriş yap" : "Kodu doğrula",
                        symbol: "arrow.right") {
                focus = nil
                Task {
                    if session.mfaChallenge == nil { await signIn() }
                    else { await verify() }
                }
            }
            .disabled(session.isBusy)
        }
    }

    private func input<Content: View>(_ label: String, symbol: String,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: symbol)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(Atlas.copper)
            content()
                .font(.system(size: 14))
                .foregroundStyle(Atlas.ink)
                .tint(Atlas.blue)
                .padding(14)
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

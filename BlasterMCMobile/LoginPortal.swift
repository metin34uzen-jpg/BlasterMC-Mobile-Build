import SwiftUI

struct IntroScreen: View {
    @State private var floating = false

    var body: some View {
        ZStack {
            BlasterTheme.navy.ignoresSafeArea()
            SkyWorldView()
                .opacity(0.31)
                .ignoresSafeArea()
            RadialGradient(colors: [BlasterTheme.gold.opacity(0.24), .clear],
                           center: .center, startRadius: 55, endRadius: 360)
                .ignoresSafeArea()

            VStack(spacing: 19) {
                ZStack {
                    Circle()
                        .strokeBorder(BlasterTheme.amber.opacity(0.35), lineWidth: 1)
                        .frame(width: 220, height: 220)
                        .scaleEffect(floating ? 1.06 : 0.85)
                    Circle()
                        .strokeBorder(BlasterTheme.amber.opacity(0.17), lineWidth: 2)
                        .frame(width: 245, height: 245)
                        .scaleEffect(floating ? 1.0 : 0.82)
                    BlasterLogo(size: 180)
                        .scaleEffect(floating ? 1.04 : 0.78)
                        .opacity(floating ? 1 : 0.3)
                        .shadow(color: BlasterTheme.amber.opacity(0.26), radius: 18)
                }
                Text("BLASTERMC")
                    .font(.system(size: 33, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(BlasterTheme.cream)
                Text("WORLD EXPERIENCE  /  V10")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(BlasterTheme.amber)
                Capsule()
                    .fill(BlasterTheme.amber.opacity(0.25))
                    .frame(width: 115, height: 3)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(BlasterTheme.amber)
                            .frame(width: floating ? 115 : 7, height: 3)
                    }
                    .padding(.top, 10)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.95)) { floating = true }
        }
    }
}

struct LoginPortal: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var username = ""
    @State private var password = ""
    @State private var code = ""
    @State private var shimmer = false
    @FocusState private var field: Focus?
    private enum Focus: Hashable { case name, password, code }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    brand
                    welcome
                    credentials
                    safety
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, max(24, geometry.safeAreaInsets.top + 20))
                .padding(.bottom, 50)
            }
            .scrollDismissesKeyboard(.interactively)
            .background {
                ZStack {
                    BlasterTheme.canvas
                    Circle()
                        .fill(BlasterTheme.amber.opacity(0.18))
                        .frame(width: 320, height: 320)
                        .blur(radius: 65)
                        .offset(x: shimmer ? 150 : -110, y: -210)
                    Circle()
                        .fill(BlasterTheme.gold.opacity(0.10))
                        .frame(width: 260, height: 260)
                        .blur(radius: 78)
                        .offset(x: shimmer ? -135 : 120, y: 320)
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { shimmer = true }
        }
    }

    private var brand: some View {
        HStack(spacing: 12) {
            BlasterLogo(size: 57)
                .shadow(color: BlasterTheme.gold.opacity(0.22), radius: 16, y: 6)
            VStack(alignment: .leading, spacing: 3) {
                Text("BLASTERMC")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(1.7)
                Text("WORLD EXPERIENCE 10")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(BlasterTheme.gold)
            }
            Spacer()
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(BlasterTheme.gold)
        }
    }

    private var welcome: some View {
        PremiumBanner(
            eyebrow: "✦  GÜVENLİ OYUNCU PORTALI",
            title: "Yeni bir evrene\ngiriş yap.",
            subtitle: "Dünya merkezine, gerçek oyuncu verilerine ve sezon arenasına tek kapıdan ulaş.",
            symbol: "gamecontroller.fill"
        )
    }

    private var credentials: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(session.mfaChallenge == nil ? "HESABINA GİRİŞ YAP" : "HESABINI DOĞRULA")
                .font(.caption.weight(.heavy))
                .tracking(1.6)
                .foregroundStyle(BlasterTheme.ink)
            if session.mfaChallenge == nil {
                entry(icon: "person.crop.circle", label: "Minecraft kullanıcı adı") {
                    TextField("Oyuncu adın", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($field, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { field = .password }
                }
                entry(icon: "lock.shield", label: "Şifre") {
                    SecureField("Güvenli şifre", text: $password)
                        .textContentType(.password)
                        .focused($field, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await signIn() } }
                }
            } else {
                Text("Hesabındaki iki aşamalı doğrulama koruması aktif.")
                    .font(.caption)
                    .foregroundStyle(BlasterTheme.muted)
                entry(icon: "checkmark.shield", label: "Doğrulama kodu") {
                    TextField("Authenticator / kurtarma kodu", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($field, equals: .code)
                        .submitLabel(.go)
                        .onSubmit { Task { await verify() } }
                }
            }
            if let error = session.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            GoldButton(title: session.isBusy ? "DOĞRULANIYOR…" :
                       (session.mfaChallenge == nil ? "DÜNYAMA GİRİŞ YAP" : "KODU ONAYLA"),
                       symbol: "arrow.right") {
                Task {
                    if session.mfaChallenge == nil { await signIn() }
                    else { await verify() }
                }
            }
            .disabled(session.isBusy)
            Text("Oturum güvenliği için 15 dakika sonunda yeniden giriş istenir.")
                .font(.caption2)
                .foregroundStyle(BlasterTheme.muted)
                .frame(maxWidth: .infinity)
        }
        .padding(22)
        .background(BlasterTheme.paper, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(BlasterTheme.gold.opacity(0.20), lineWidth: 1)
        }
        .shadow(color: BlasterTheme.navy.opacity(0.09), radius: 24, y: 12)
    }

    private func entry<Content: View>(icon: String, label: String,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(BlasterTheme.muted)
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(BlasterTheme.gold)
                content()
                    .font(.subheadline)
                    .foregroundStyle(BlasterTheme.ink)
            }
            .padding(15)
            .background(BlasterTheme.canvas, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var safety: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(BlasterTheme.gold)
            Text("Resmî BlasterMC hesabınla güvenli giriş. Şifren kaydedilmez; iki aşamalı doğrulama korunur.")
                .font(.caption)
                .foregroundStyle(BlasterTheme.muted)
        }
    }

    private func signIn() async {
        field = nil
        await session.signIn(username: username, password: password)
        password = ""
    }

    private func verify() async {
        field = nil
        await session.verifyMFA(code: code)
        if session.isSignedIn { code = "" }
    }
}

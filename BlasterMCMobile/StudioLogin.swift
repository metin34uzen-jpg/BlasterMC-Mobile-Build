import SwiftUI

struct StudioSplash:View {
    @State private var fade=false
    var body:some View {
        ZStack {
            Studio.navy.ignoresSafeArea()
            VStack(spacing:18) {
                BlasterLogo(size:116)
                    .opacity(fade ? 1 : 0.30)
                    .scaleEffect(fade ? 1 : 0.94)
                Text("BLASTERMC")
                    .font(.system(size:29,weight:.black,design:.rounded))
                    .tracking(2)
                    .foregroundStyle(.white)
                Text("MOBILE / 10.2")
                    .font(.system(size:11,weight:.bold,design:.monospaced))
                    .tracking(2)
                    .foregroundStyle(Studio.sunlight)
                Capsule().fill(Studio.sunlight.opacity(0.42))
                    .frame(width:110,height:3)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration:0.6)) { fade=true }
        }
    }
}

struct StudioLoginView:View {
    @EnvironmentObject private var session:BlasterSession
    @State private var username=""
    @State private var password=""
    @State private var code=""
    @State private var showPassword=false
    @FocusState private var focused:Field?
    private enum Field:Hashable {case username,password,code}

    var body:some View {
        ScrollView(showsIndicators:false) {
            VStack(alignment:.leading,spacing:18) {
                masthead
                StudioHero(symbol:"lock.shield",height:155) {
                    VStack(alignment:.leading,spacing:7) {
                        Text("GÜVENLİ OYUNCU GİRİŞİ")
                            .font(.system(size:10,weight:.bold,design:.monospaced))
                            .foregroundStyle(Studio.sunlight)
                        Text("Dünyana hoş geldin.")
                            .font(.system(size:24,weight:.bold,design:.rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal:false,vertical:true)
                        Text("BlasterMC hesabınla devam et.")
                            .font(.system(size:12))
                            .foregroundStyle(.white.opacity(0.77))
                    }
                }
                loginCard
                HStack(alignment:.top,spacing:9) {
                    Image(systemName:"checkmark.shield.fill")
                        .foregroundStyle(Studio.gold)
                    Text("Hesabın BlasterMC sunucusunda doğrulanır. Şifren saklanmaz, oturum anahtarın Keychain ile korunur ve 15 dakikada sona erer.")
                        .font(.system(size:11))
                        .foregroundStyle(Studio.secondary)
                        .fixedSize(horizontal:false,vertical:true)
                }
                .padding(.horizontal,6)
            }
            .padding(.horizontal,20)
            .padding(.top,20)
            .padding(.bottom,32)
            .frame(maxWidth:560)
            .frame(maxWidth:.infinity)
        }
        .background(StudioBackground())
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement:.keyboard) {
                Spacer()
                Button("Bitti") { focused=nil }
            }
        }
    }

    private var masthead:some View {
        HStack(spacing:11) {
            BlasterLogo(size:52)
            VStack(alignment:.leading,spacing:4) {
                Text("BLASTERMC")
                    .font(.system(size:20,weight:.black,design:.rounded))
                    .foregroundStyle(Studio.ink)
                Text("MOBILE PLAYER PORTAL")
                    .font(.system(size:10,weight:.semibold,design:.monospaced))
                    .foregroundStyle(Studio.gold)
            }
            Spacer()
            Image(systemName:"lock.shield")
                .foregroundStyle(Studio.gold)
        }
    }

    private var loginCard:some View {
        StudioPanel {
            Text(session.mfaChallenge==nil ? "Hesabına giriş yap" : "İki aşamalı doğrulama")
                .font(.system(size:19,weight:.bold,design:.rounded))
                .foregroundStyle(Studio.ink)
            if session.mfaChallenge==nil {
                field("MINECRAFT KULLANICI ADI",symbol:"person.fill") {
                    TextField("Oyuncu adın",text:$username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused,equals:.username)
                        .submitLabel(.next)
                        .onSubmit { focused = .password }
                }
                field("ŞİFRE",symbol:"lock") {
                    HStack(spacing:8) {
                        Group {
                            if showPassword {
                                TextField("Şifren",text:$password)
                            } else {
                                SecureField("Şifren",text:$password)
                            }
                        }
                        .textContentType(.password)
                        .focused($focused,equals:.password)
                        .submitLabel(.go)
                        .onSubmit { Task { await signIn() } }
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName:showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(Studio.gold)
                        }
                        .accessibilityLabel(showPassword ? "Şifreyi gizle" : "Şifreyi göster")
                    }
                }
            } else {
                Text("Authenticator veya kurtarma kodunu gir.")
                    .font(.system(size:12))
                    .foregroundStyle(Studio.secondary)
                field("DOĞRULAMA KODU",symbol:"checkmark.shield") {
                    TextField("Kod",text:$code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focused,equals:.code)
                        .submitLabel(.go)
                        .onSubmit { Task { await verify() } }
                }
            }
            if let error=session.error {
                Label(error,systemImage:"exclamationmark.triangle")
                    .font(.system(size:12))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal:false,vertical:true)
            }
            StudioCTA(title:session.isBusy ? "Doğrulanıyor…" :
                      (session.mfaChallenge==nil ? "Giriş yap" : "Kodu doğrula"),
                      symbol:"arrow.right") {
                focused=nil
                Task {
                    if session.mfaChallenge==nil { await signIn() }
                    else { await verify() }
                }
            }
            .disabled(session.isBusy)
        }
    }

    private func field<Content:View>(_ title:String,symbol:String,
                                     @ViewBuilder content:()->Content)->some View {
        VStack(alignment:.leading,spacing:7) {
            Label(title,systemImage:symbol)
                .font(.system(size:10,weight:.bold))
                .foregroundStyle(Studio.secondary)
            content()
                .font(.system(size:14))
                .tint(Studio.gold)
                .padding(13)
                .background(Studio.background,in:RoundedRectangle(cornerRadius:11))
                .overlay(RoundedRectangle(cornerRadius:11).strokeBorder(Studio.line))
        }
    }

    private func signIn() async {
        await session.signIn(username:username,password:password)
        password=""
    }
    private func verify() async {
        await session.verifyMFA(code:code)
        code=""
    }
}

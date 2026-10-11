import SwiftUI

struct ForgeArrivalSplash: View {
    @State private var lit = false

    var body: some View {
        ZStack {
            Forge.midnight.ignoresSafeArea()
            GeometryReader { geo in
                ForgeVoxelIsland()
                    .frame(width:geo.size.width*1.2,height:geo.size.height*0.62)
                    .position(x:geo.size.width*0.50,y:geo.size.height*0.42)
                    .opacity(lit ? 1 : 0.25)
                    .scaleEffect(lit ? 1 : 0.88)
            }
            LinearGradient(colors:[Forge.midnight.opacity(0.24),
                                   Forge.midnight.opacity(0.42),Forge.midnight],
                           startPoint:.top,endPoint:.bottom)
            VStack(spacing:13) {
                Spacer()
                ForgeEmblem(width:86)
                    .shadow(color:Forge.sun.opacity(0.26),radius:21)
                Text("BLASTERMC")
                    .font(.system(size:34,weight:.black,design:.rounded))
                    .tracking(2.1)
                    .foregroundStyle(.white)
                ForgeLabel(text:"YOUR WORLD / REFORGED",onDark:true)
                Rectangle()
                    .fill(Forge.sun)
                    .frame(width:lit ? 135 : 12,height:3)
                    .animation(.easeOut(duration:0.8),value:lit)
                    .padding(.top,8)
                Spacer().frame(height:80)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration:0.85)) { lit=true }
        }
    }
}

struct ForgeLoginPortal: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var username=""
    @State private var password=""
    @State private var code=""
    @State private var showPassword=false
    @FocusState private var focused: Field?
    private enum Field: Hashable { case username,password,code }

    var body: some View {
        ScrollView(showsIndicators:false) {
            VStack(alignment:.leading,spacing:18) {
                brand
                poster
                credentials
                assurance
            }
            .padding(.horizontal,20)
            .padding(.top,20)
            .padding(.bottom,36)
            .frame(maxWidth:580)
            .frame(maxWidth:.infinity)
        }
        .background(ForgeBackground())
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement:.keyboard) {
                Spacer()
                Button("Bitti") { focused=nil }
            }
        }
    }

    private var brand:some View {
        HStack(spacing:11) {
            ForgeEmblem(width:48)
            VStack(alignment:.leading,spacing:3) {
                Text("BLASTERMC")
                    .font(.system(size:19,weight:.black,design:.rounded))
                    .tracking(1)
                    .foregroundStyle(Forge.midnight)
                Text("THE OVERWORLD / SIGN IN")
                    .font(.system(size:9,weight:.heavy,design:.monospaced))
                    .foregroundStyle(Forge.bronze)
            }
            Spacer()
            Image(systemName:"checkmark.shield.fill")
                .foregroundStyle(Forge.gold)
        }
    }

    private var poster:some View {
        ZStack(alignment:.topLeading) {
            ForgeCut(cut:22).fill(Forge.midnight)
            GeometryReader { geo in
                ForgeVoxelIsland()
                    .frame(width:geo.size.width,height:geo.size.height*1.02)
                    .offset(x:geo.size.width*0.22)
                    .opacity(0.82)
            }
            LinearGradient(colors:[Forge.midnight.opacity(0.88),Forge.midnight.opacity(0.43),.clear],
                           startPoint:.leading,endPoint:.trailing)
            VStack(alignment:.leading,spacing:9) {
                ForgeLabel(text:"THE GATE IS OPEN",onDark:true)
                Spacer()
                Text("DÜNYANA\nGERİ DÖN.")
                    .font(.system(size:34,weight:.black,design:.rounded))
                    .tracking(-0.9)
                    .foregroundStyle(.white)
                Text("BlasterMC evreninin kapıları seni bekliyor.")
                    .font(.system(size:11,weight:.medium))
                    .foregroundStyle(.white.opacity(0.84))
            }
            .padding(22)
        }
        .frame(height:235)
        .clipShape(ForgeCut(cut:22))
        .overlay(ForgeCut(cut:22).strokeBorder(Forge.sun.opacity(0.40)))
    }

    private var credentials:some View {
        VStack(alignment:.leading,spacing:14) {
            ForgeLabel(text:session.mfaChallenge == nil ?
                       "ACCOUNT / AUTHENTICATION" : "ACCOUNT / TWO STEP VERIFICATION")
            Text(session.mfaChallenge == nil ? "Hesabına giriş yap." : "Kimliğini doğrula.")
                .font(.system(size:23,weight:.black,design:.rounded))
                .foregroundStyle(Forge.midnight)
            if session.mfaChallenge == nil {
                fieldGroup("MINECRAFT KULLANICI ADI",symbol:"person.fill") {
                    TextField("Oyuncu adın",text:$username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused,equals:.username)
                        .submitLabel(.next)
                        .onSubmit { focused = .password }
                }
                fieldGroup("ŞİFRE",symbol:"lock.shield") {
                    HStack(spacing:7) {
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
                        .onSubmit { Task { await session.signIn(username:username,password:password) } }
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName:showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(Forge.gold)
                        }
                        .accessibilityLabel(showPassword ? "Şifreyi gizle" : "Şifreyi göster")
                    }
                }
            } else {
                fieldGroup("İKİ AŞAMALI DOĞRULAMA KODU",symbol:"checkmark.shield.fill") {
                    TextField("Doğrulama kodu",text:$code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focused,equals:.code)
                        .submitLabel(.go)
                        .onSubmit { Task { await session.verifyMFA(code:code) } }
                }
            }
            if let error=session.error {
                Label(error,systemImage:"exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            ForgeButton(title:session.isBusy ? "İşlem sürüyor..." :
                        session.mfaChallenge == nil ? "Dünyama giriş yap" : "Kodu doğrula",
                        symbol:"arrow.up.right") {
                focused=nil
                Task {
                    if session.mfaChallenge == nil {
                        await session.signIn(username:username,password:password)
                        password=""
                    } else {
                        await session.verifyMFA(code:code)
                        code=""
                    }
                }
            }
            .disabled(session.isBusy)
        }
        .padding(18)
        .background(Forge.white,in:ForgeCut(cut:16))
        .overlay(ForgeCut(cut:16).strokeBorder(Forge.stroke.opacity(0.7)))
    }

    private func fieldGroup<Content:View>(_ title:String,symbol:String,
                                          @ViewBuilder content:()->Content)->some View {
        VStack(alignment:.leading,spacing:8) {
            Label(title,systemImage:symbol)
                .font(.system(size:10,weight:.black,design:.monospaced))
                .foregroundStyle(Forge.bronze)
            content()
                .font(.subheadline)
                .tint(Forge.gold)
                .padding(14)
                .background(Forge.base,in:ForgeCut(cut:9))
                .overlay(ForgeCut(cut:9).strokeBorder(Forge.stroke.opacity(0.60)))
        }
    }

    private var assurance:some View {
        HStack(alignment:.top,spacing:10) {
            Image(systemName:"lock.shield.fill")
                .font(.system(size:19))
                .foregroundStyle(Forge.gold)
            Text("Giriş bilgilerin BlasterMC API üzerinden doğrulanır. Oturum anahtarı iPhone Keychain ile korunur ve oturum 15 dakika içinde sona erer.")
                .font(.system(size:11))
                .foregroundStyle(Forge.muted)
                .fixedSize(horizontal:false,vertical:true)
        }
        .padding(.horizontal,6)
    }
}

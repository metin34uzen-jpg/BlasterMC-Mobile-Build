import SwiftUI

struct ForgeProfileView: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var copiedID = false
    @State private var showSignOut = false

    private var presence: [(String, Bool?)] {
        [("MINECRAFT", session.profile?.inGame),("WEB", session.profile?.onSite)]
    }

    var body:some View {
        NavigationStack {
            ScrollView(showsIndicators:false) {
                VStack(alignment:.leading,spacing:19) {
                    heading
                    identity
                    wallet
                    onlineStatus
                    if session.isAdministrator { adminPortal }
                    security
                    external
                    logOut
                }
                .padding(.horizontal,18)
                .padding(.top,18)
                .padding(.bottom,30)
                .frame(maxWidth:660)
                .frame(maxWidth:.infinity)
            }
            .background(ForgeBackground())
            .navigationBarHidden(true)
            .refreshable { await session.reloadProfile() }
            .confirmationDialog("BlasterMC hesabından çıkış yapılsın mı?",
                                isPresented:$showSignOut,titleVisibility:.visible) {
                Button("Güvenli çıkış yap",role:.destructive) {
                    session.signOut()
                }
            }
        }
    }

    private var heading:some View {
        HStack {
            VStack(alignment:.leading,spacing:5) {
                ForgeLabel(text:"THE PLAYER / 04")
                Text("Oyuncu kimliğin.")
                    .font(.system(size:29,weight:.black,design:.rounded))
                    .tracking(-1)
                    .foregroundStyle(Forge.midnight)
                Text("BlasterMC'deki resmî hesabın")
                    .font(.caption)
                    .foregroundStyle(Forge.muted)
            }
            Spacer()
            ForgeEmblem(width:55)
        }
    }

    private var identity:some View {
        ZStack(alignment:.topLeading) {
            ForgeCut(cut:21)
                .fill(LinearGradient(colors:[Forge.midnight,Forge.midnight2,
                     Color(red:0.38,green:0.31,blue:0.29)],
                     startPoint:.topLeading,endPoint:.bottomTrailing))
            GeometryReader { g in
                ForgeVoxelIsland()
                    .frame(width:g.size.width*0.77,height:g.size.height*0.94)
                    .offset(x:g.size.width*0.42,y:5)
                    .opacity(0.37)
            }
            LinearGradient(colors:[Forge.midnight.opacity(0.86),.clear],
                           startPoint:.leading,endPoint:.trailing)
            VStack(alignment:.leading,spacing:14) {
                HStack {
                    ForgeLabel(text:"OFFICIAL PLAYER PASSPORT",onDark:true)
                    Spacer()
                    Image(systemName:"checkmark.shield.fill")
                        .font(.system(size:17))
                        .foregroundStyle(Forge.sun)
                }
                HStack(spacing:13) {
                    ZStack {
                        ForgeCut(cut:11).fill(Forge.sun.opacity(0.14))
                        if let skin=session.profile?.skinUrl {
                            AsyncImage(url:skin) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                BlasterLogo(size:58)
                            }
                            .padding(8)
                        } else {
                            BlasterLogo(size:58)
                        }
                    }
                    .frame(width:83,height:88)
                    .overlay(ForgeCut(cut:11).strokeBorder(Forge.sun.opacity(0.51)))
                    VStack(alignment:.leading,spacing:8) {
                        Text(session.profile?.minecraftName ?? "Oyuncu")
                            .font(.system(size:23,weight:.black,design:.rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                        Text(session.profile?.rank ?? "Rütbe sorgulanıyor")
                            .font(.system(size:11,weight:.heavy,design:.monospaced))
                            .foregroundStyle(Forge.sun)
                            .lineLimit(1)
                        HStack(spacing:5) {
                            Image(systemName:"checkmark.seal.fill")
                                .foregroundStyle(Forge.sun)
                            Text("BLASTERMC ÜYESİ")
                                .foregroundStyle(.white.opacity(0.82))
                        }
                        .font(.system(size:9,weight:.bold,design:.monospaced))
                    }
                }
                Rectangle().fill(Forge.sun.opacity(0.26)).frame(height:1)
                HStack {
                    VStack(alignment:.leading,spacing:4) {
                        Text("BLASTER ID")
                            .font(.system(size:9,weight:.black,design:.monospaced))
                            .foregroundStyle(Forge.sun)
                        Text(session.profile?.blasterId ?? "—")
                            .font(.system(size:15,weight:.black,design:.monospaced))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    Spacer()
                    Button {
                        guard let id=session.profile?.blasterId,!id.isEmpty else { return }
                        Forge.copy(id)
                        copiedID=true
                    } label: {
                        Label(copiedID ? "ALINDI" : "KOPYALA",
                              systemImage:copiedID ? "checkmark" : "doc.on.doc")
                            .font(.system(size:10,weight:.black,design:.monospaced))
                            .foregroundStyle(Forge.midnight)
                            .padding(11)
                            .background(Forge.sun,in:ForgeCut(cut:8))
                    }
                    .buttonStyle(BlasterTapStyle())
                }
            }
            .padding(19)
        }
        .frame(height:260)
        .clipShape(ForgeCut(cut:21))
        .overlay(ForgeCut(cut:21).strokeBorder(Forge.sun.opacity(0.40)))
    }

    private var wallet:some View {
        VStack(alignment:.leading,spacing:11) {
            ForgeHeading(eyebrow:"ACCOUNT / ECONOMY",title:"Blaster cüzdanı")
            ForgeSurface {
                HStack(spacing:13) {
                    Image(systemName:"circle.hexagongrid.fill")
                        .font(.system(size:29))
                        .foregroundStyle(Forge.gold)
                        .frame(width:52,height:55)
                        .background(Forge.gold.opacity(0.1),in:ForgeCut(cut:10))
                    VStack(alignment:.leading,spacing:5) {
                        Text("MEVCUT KREDİ")
                            .font(.system(size:10,weight:.black,design:.monospaced))
                            .foregroundStyle(Forge.muted)
                        Text((session.profile?.credits ?? 0).formatted())
                            .font(.system(size:29,weight:.black,design:.rounded))
                            .foregroundStyle(Forge.midnight)
                    }
                    Spacer()
                    Image(systemName:"lock.shield.fill")
                        .foregroundStyle(Forge.gold)
                }
            }
        }
    }

    private var onlineStatus:some View {
        VStack(alignment:.leading,spacing:11) {
            ForgeHeading(eyebrow:"NETWORK / PRESENCE",title:"Aktiflik durumu")
            HStack(spacing:10) {
                ForEach(presence,id:\.0) { pair in
                    let name = pair.0
                    let active = pair.1
                    ForgeSurface {
                        HStack(spacing:7) {
                            Circle().fill(active == true ? Color.green :
                                          active == false ? Color.gray : Color.orange)
                                .frame(width:7,height:7)
                            Text(name)
                                .font(.system(size:11,weight:.black,design:.monospaced))
                                .foregroundStyle(Forge.midnight)
                        }
                        Text(active == nil ? "Bilinmiyor" : active == true ? "Aktif" : "Çevrimdışı")
                            .font(.system(size:11))
                            .foregroundStyle(Forge.muted)
                    }
                }
            }
        }
    }

    private var adminPortal:some View {
        VStack(alignment:.leading,spacing:11) {
            ForgeHeading(eyebrow:"AUTHORIZED / CONTROL",title:"Komuta merkezi")
            NavigationLink {
                AdminCenterView()
            } label: {
                ForgeSurface(dark:true) {
                    HStack(spacing:13) {
                        Image(systemName:"crown.fill")
                            .font(.system(size:27))
                            .foregroundStyle(Forge.sun)
                            .frame(width:56,height:57)
                            .background(Forge.sun.opacity(0.09),in:ForgeCut(cut:10))
                        VStack(alignment:.leading,spacing:5) {
                            ForgeLabel(text:"ADMINISTRATION",onDark:true)
                            Text("BLASTER CONTROL")
                                .font(.system(size:17,weight:.black,design:.rounded))
                                .foregroundStyle(.white)
                            Text("Sunucu • Web • Discord • Bildirim")
                                .font(.system(size:10))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(2)
                        }
                        Spacer(minLength:0)
                        Image(systemName:"arrow.up.right")
                            .foregroundStyle(Forge.sun)
                    }
                }
            }
            .buttonStyle(BlasterTapStyle())
        }
    }

    private var security:some View {
        VStack(alignment:.leading,spacing:11) {
            ForgeHeading(eyebrow:"IDENTITY / SECURITY",title:"Güvenlik merkezi")
            ForgeSurface {
                Label("Oturum güvenliği etkin",systemImage:"checkmark.shield.fill")
                    .font(.system(size:13,weight:.heavy))
                    .foregroundStyle(Forge.midnight)
                Text("Erişim anahtarın iPhone Keychain içinde saklanır. Oturum 15 dakika sonunda güvenlik amacıyla sonlandırılır.")
                    .font(.caption)
                    .foregroundStyle(Forge.muted)
                if let login=session.loggedInAt {
                    HStack(spacing:8) {
                        Image(systemName:"clock")
                            .foregroundStyle(Forge.gold)
                        Text("Oturum bitişi \(login.addingTimeInterval(900),style:.time)")
                            .font(.system(size:11,weight:.semibold,design:.monospaced))
                            .foregroundStyle(Forge.midnight)
                    }
                }
                ForgeButton(title:"Hesabımı yenile",symbol:"arrow.clockwise",quiet:true) {
                    Task { await session.reloadProfile() }
                }
            }
        }
    }

    private var external:some View {
        HStack(spacing:10) {
            Link(destination:URL(string:"https://blastermc.com")!) {
                Label("WEB PORTAL",systemImage:"globe")
                    .font(.system(size:10,weight:.black,design:.monospaced))
                    .foregroundStyle(Forge.midnight)
                    .frame(maxWidth:.infinity)
                    .frame(height:45)
                    .background(Forge.white,in:ForgeCut(cut:10))
            }
            Link(destination:URL(string:"https://discord.blastermc.com")!) {
                Label("DISCORD",systemImage:"person.3.fill")
                    .font(.system(size:10,weight:.black,design:.monospaced))
                    .foregroundStyle(Forge.midnight)
                    .frame(maxWidth:.infinity)
                    .frame(height:45)
                    .background(Forge.white,in:ForgeCut(cut:10))
            }
        }
    }

    private var logOut:some View {
        Button {
            showSignOut=true
        } label: {
            Label("GÜVENLİ ÇIKIŞ YAP",systemImage:"rectangle.portrait.and.arrow.right")
                .font(.system(size:11,weight:.black,design:.monospaced))
                .foregroundStyle(Color(red:0.65,green:0.21,blue:0.17))
                .frame(maxWidth:.infinity)
                .frame(height:47)
                .background(Forge.white,in:ForgeCut(cut:10))
                .overlay(ForgeCut(cut:10).strokeBorder(Forge.stroke))
        }
    }
}

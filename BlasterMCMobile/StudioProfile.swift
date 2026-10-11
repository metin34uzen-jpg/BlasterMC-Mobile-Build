import SwiftUI

/// Adaptive player profile: no fixed text heights, safe-area dock and a persistent logout action.
struct StudioProfileView:View {
    @EnvironmentObject private var session:BlasterSession
    @State private var confirmLogout=false
    @State private var copiedID=false

    var body:some View {
        NavigationStack {
            VStack(spacing:0) {
                ScrollView(showsIndicators:false) {
                    VStack(alignment:.leading,spacing:20) {
                        StudioSection(kicker:"BLASTER ID / HESABIN",title:"Oyuncu profilin")
                        identity
                        financial
                        activity
                        if session.isAdministrator { adminAccess }
                        protection
                        usefulLinks
                    }
                    .padding(.horizontal,18)
                    .padding(.top,18)
                    .padding(.bottom,24)
                    .frame(maxWidth:620)
                    .frame(maxWidth:.infinity)
                }
                .frame(maxHeight:.infinity)
                .refreshable { await session.reloadProfile() }
                logoutBar
            }
            .background(StudioBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden,for:.navigationBar)
            .confirmationDialog("BlasterMC hesabından çıkış yapılsın mı?",
                                isPresented:$confirmLogout,
                                titleVisibility:.visible) {
                Button("Güvenli çıkış yap",role:.destructive) {
                    session.signOut()
                }
                Button("Vazgeç",role:.cancel){}
            } message: {
                Text("Bu cihazdaki oturum sonlandırılacak.")
            }
        }
    }

    private var identity:some View {
        StudioPanel {
            VStack(alignment:.leading,spacing:15) {
                HStack(alignment:.top,spacing:13) {
                    avatar
                    VStack(alignment:.leading,spacing:6) {
                        Text("MINECRAFT OYUNCUSU")
                            .font(.system(size:10,weight:.bold))
                            .foregroundStyle(Studio.gold)
                            .tracking(0.8)
                        Text(session.profile?.minecraftName ?? "Oyuncu")
                            .font(.system(size:23,weight:.bold,design:.rounded))
                            .foregroundStyle(Studio.ink)
                            .fixedSize(horizontal:false,vertical:true)
                            .minimumScaleFactor(0.80)
                        Text(session.profile?.rank ?? "Rütbe bilgisi bekleniyor")
                            .font(.system(size:13,weight:.semibold))
                            .foregroundStyle(Studio.secondary)
                            .fixedSize(horizontal:false,vertical:true)
                    }
                    .frame(maxWidth:.infinity,alignment:.leading)
                }
                Divider().overlay(Studio.line)
                VStack(alignment:.leading,spacing:8) {
                    Text("BLASTER ID")
                        .font(.system(size:10,weight:.bold,design:.monospaced))
                        .foregroundStyle(Studio.secondary)
                    Text(session.profile?.blasterId ?? "—")
                        .font(.system(size:15,weight:.semibold,design:.monospaced))
                        .foregroundStyle(Studio.ink)
                        .textSelection(.enabled)
                        .fixedSize(horizontal:false,vertical:true)
                        .frame(maxWidth:.infinity,alignment:.leading)
                    Button {
                        if let id=session.profile?.blasterId,!id.isEmpty {
                            Studio.copy(id)
                            copiedID=true
                        }
                    } label: {
                        Label(copiedID ? "Kopyalandı" : "Blaster ID'yi kopyala",
                              systemImage:copiedID ? "checkmark" : "doc.on.doc")
                            .font(.system(size:12,weight:.semibold))
                            .foregroundStyle(Studio.gold)
                            .padding(.vertical,5)
                    }
                    .buttonStyle(BlasterTapStyle())
                }
            }
        }
    }

    private var avatar:some View {
        ZStack {
            RoundedRectangle(cornerRadius:15)
                .fill(Studio.pale)
            if let skin=session.profile?.skinUrl {
                AsyncImage(url:skin) { image in
                    image.resizable().scaledToFit()
                } placeholder:{ BlasterLogo(size:49) }
                .padding(6)
            } else { BlasterLogo(size:49) }
        }
        .frame(width:74,height:82)
        .overlay(RoundedRectangle(cornerRadius:15).strokeBorder(Studio.line))
        .accessibilityLabel("Minecraft oyuncu görünümü")
    }

    private var financial:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"CÜZDAN / DOĞRULANMIŞ",title:"Kredi bakiyen")
            StudioPanel {
                HStack(spacing:12) {
                    Image(systemName:"circle.hexagongrid.fill")
                        .font(.system(size:26))
                        .foregroundStyle(Studio.gold)
                        .frame(width:45,height:45)
                        .background(Studio.pale,in:RoundedRectangle(cornerRadius:12))
                    VStack(alignment:.leading,spacing:4) {
                        Text((session.profile?.credits ?? 0).formatted())
                            .font(.system(size:27,weight:.bold,design:.rounded))
                            .foregroundStyle(Studio.ink)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("BLASTER KREDİ")
                            .font(.system(size:10,weight:.bold))
                            .tracking(0.8)
                            .foregroundStyle(Studio.secondary)
                    }
                    Spacer(minLength:0)
                    Image(systemName:"lock.shield")
                        .foregroundStyle(Studio.gold)
                }
            }
        }
    }

    private var activity:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"CANLI / HESAP DURUMU",title:"Aktiflik")
            VStack(spacing:9) {
                presence("Minecraft",value:session.profile?.inGame,symbol:"gamecontroller.fill")
                presence("Web hesabın",value:session.profile?.onSite,symbol:"globe")
            }
        }
    }

    private func presence(_ name:String,value:Bool?,symbol:String)->some View {
        StudioPanel(padding:14) {
            HStack(spacing:11) {
                Image(systemName:symbol)
                    .foregroundStyle(Studio.gold)
                    .frame(width:24)
                Text(name)
                    .font(.system(size:13,weight:.semibold))
                    .foregroundStyle(Studio.ink)
                    .fixedSize(horizontal:false,vertical:true)
                Spacer(minLength:4)
                HStack(spacing:5) {
                    Circle()
                        .fill(value == true ? Color.green : value == false ? Color.gray : Color.orange)
                        .frame(width:7,height:7)
                    Text(value == nil ? "Bilinmiyor" : value == true ? "Aktif" : "Çevrimdışı")
                        .font(.system(size:11,weight:.medium))
                        .foregroundStyle(Studio.secondary)
                }
            }
        }
    }

    private var adminAccess:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"YETKİLİ / ERİŞİM",title:"Yönetim paneli")
            NavigationLink {
                StudioAdminCenterView()
            } label: {
                StudioPanel(dark:true) {
                    HStack(spacing:12) {
                        Image(systemName:"shield.lefthalf.filled")
                            .font(.system(size:23))
                            .foregroundStyle(Studio.sunlight)
                            .frame(width:40)
                        VStack(alignment:.leading,spacing:5) {
                            Text("BLASTER CONTROL")
                                .font(.system(size:15,weight:.bold))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal:false,vertical:true)
                            Text("Sunucu, web, Discord ve bildirim yönetimi")
                                .font(.system(size:12))
                                .foregroundStyle(.white.opacity(0.78))
                                .fixedSize(horizontal:false,vertical:true)
                        }
                        Spacer(minLength:3)
                        Image(systemName:"chevron.right")
                            .font(.system(size:13,weight:.bold))
                            .foregroundStyle(Studio.sunlight)
                    }
                }
            }
            .buttonStyle(BlasterTapStyle())
        }
    }

    private var protection:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"GÜVENLİK / OTURUM",title:"Hesap güvenliği")
            StudioPanel {
                Label("Güvenli bağlantı ve Keychain",systemImage:"checkmark.shield")
                    .font(.system(size:13,weight:.semibold))
                    .foregroundStyle(Studio.ink)
                    .fixedSize(horizontal:false,vertical:true)
                Text("Şifren uygulamada saklanmaz. Oturum anahtarı iPhone'un güvenli alanında tutulur ve 15 dakika sonunda oturum sonlanır.")
                    .font(.system(size:12))
                    .foregroundStyle(Studio.secondary)
                    .fixedSize(horizontal:false,vertical:true)
                if let login=session.loggedInAt {
                    Text("Oturum sonu: \(login.addingTimeInterval(900),style:.time)")
                        .font(.system(size:12,weight:.semibold))
                        .foregroundStyle(Studio.gold)
                }
                StudioCTA(title:"Bilgilerimi yenile",symbol:"arrow.clockwise",subtle:true) {
                    Task { await session.reloadProfile() }
                }
            }
        }
    }

    private var usefulLinks:some View {
        HStack(spacing:10) {
            Link(destination:URL(string:"https://blastermc.com")!) {
                Label("Web sitesi",systemImage:"globe")
                    .font(.system(size:12,weight:.semibold))
                    .frame(maxWidth:.infinity,minHeight:44)
                    .foregroundStyle(Studio.ink)
                    .background(Studio.paper,in:RoundedRectangle(cornerRadius:13))
                    .overlay(RoundedRectangle(cornerRadius:13).strokeBorder(Studio.line))
            }
            Link(destination:URL(string:"https://discord.blastermc.com")!) {
                Label("Discord",systemImage:"person.2.fill")
                    .font(.system(size:12,weight:.semibold))
                    .frame(maxWidth:.infinity,minHeight:44)
                    .foregroundStyle(Studio.ink)
                    .background(Studio.paper,in:RoundedRectangle(cornerRadius:13))
                    .overlay(RoundedRectangle(cornerRadius:13).strokeBorder(Studio.line))
            }
        }
    }

    // Persistent above the bottom navigation instead of being clipped below scroll content.
    private var logoutBar:some View {
        VStack(spacing:0) {
            Rectangle().fill(Studio.line).frame(height:1)
            Button {
                confirmLogout=true
            } label: {
                HStack(spacing:10) {
                    Image(systemName:"rectangle.portrait.and.arrow.right")
                    Text("Güvenli çıkış yap")
                    Spacer()
                    Image(systemName:"chevron.right")
                }
                .font(.system(size:13,weight:.semibold))
                .foregroundStyle(Color(red:0.64,green:0.22,blue:0.21))
                .padding(.horizontal,16)
                .frame(maxWidth:620,minHeight:46)
                .background(Color.white,in:RoundedRectangle(cornerRadius:12))
                .overlay(RoundedRectangle(cornerRadius:12).strokeBorder(Studio.line))
            }
            .buttonStyle(BlasterTapStyle())
            .padding(.horizontal,18)
            .padding(.vertical,9)
        }
        .background(Studio.background)
    }
}

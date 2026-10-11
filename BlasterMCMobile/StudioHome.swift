import SwiftUI

struct StudioHomeView:View {
    @EnvironmentObject private var session:BlasterSession
    @ObservedObject var server:ServerStatusModel
    let open:(Int)->Void
    let active:Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var showNews=false
    @State private var copied=false

    var body:some View {
        ScrollView(showsIndicators:false) {
            VStack(alignment:.leading,spacing:21) {
                heading
                hero
                live
                player
                menu
                latest
            }
            .padding(.horizontal,18)
            .padding(.top,16)
            .padding(.bottom,28)
            .frame(maxWidth:620)
            .frame(maxWidth:.infinity)
        }
        .background(StudioBackground())
        .sheet(isPresented:$showNews) { NewsView().environmentObject(session) }
        .task(id:active && scenePhase == .active) {
            guard active && scenePhase == .active else { return }
            while !Task.isCancelled {
                await server.refresh()
                do { try await Task.sleep(for:.seconds(5)) }
                catch { break }
            }
        }
        .refreshable {
            async let a:Void=server.refresh()
            async let b:Void=session.reloadPublic()
            async let c:Void=session.reloadProfile()
            _=await(a,b,c)
        }
    }

    private var heading:some View {
        HStack(spacing:12) {
            BlasterLogo(size:48)
            VStack(alignment:.leading,spacing:3) {
                Text("BLASTERMC")
                    .font(.system(size:20,weight:.black,design:.rounded))
                    .tracking(0.5)
                    .foregroundStyle(Studio.ink)
                Text("OYUNCU MERKEZİ  /  10.2")
                    .font(.system(size:10,weight:.semibold,design:.monospaced))
                    .foregroundStyle(Studio.gold)
            }
            Spacer(minLength:5)
            Button {
                Studio.touch()
                showNews=true
            } label: {
                Image(systemName:"bell")
                    .font(.system(size:18,weight:.medium))
                    .foregroundStyle(Studio.ink)
                    .frame(width:42,height:42)
                    .background(Studio.paper,in:Circle())
                    .overlay(Circle().strokeBorder(Studio.line))
            }
            .accessibilityLabel("Blaster Haberler")
        }
    }

    private var hero:some View {
        StudioHero(symbol:"gamecontroller",height:196) {
            VStack(alignment:.leading,spacing:8) {
                Text("BLASTERMC / MOBILE")
                    .font(.system(size:10,weight:.heavy,design:.monospaced))
                    .tracking(1.2)
                    .foregroundStyle(Studio.sunlight)
                Text("Oyun dünyan,\nher an yanında.")
                    .font(.system(size:29,weight:.black,design:.rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                Text("SkyBlock, mağaza ve sezon tek merkezde.")
                    .font(.system(size:12,weight:.medium))
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal:false,vertical:true)
                Spacer(minLength:0)
                Button {
                    Studio.touch()
                    open(1)
                } label: {
                    Label("DÜNYAYI KEŞFET",systemImage:"arrow.up.right")
                        .font(.system(size:11,weight:.black))
                        .foregroundStyle(Studio.ink)
                        .padding(.horizontal,13)
                        .padding(.vertical,10)
                        .background(Studio.sunlight,in:Capsule())
                }
                .buttonStyle(BlasterTapStyle())
            }
        }
    }

    private var live:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"CANLI / BLASTER NETWORK",title:"Sunucu durumu")
            StudioPanel {
                HStack(alignment:.top,spacing:14) {
                    VStack(alignment:.leading,spacing:6) {
                        HStack(spacing:7) {
                            Circle()
                                .fill(!server.hasConfirmedStatus || server.isStale ?
                                      Color.orange : (server.isOnline ? .green : .red))
                                .frame(width:7,height:7)
                            Text(server.statusText)
                                .font(.system(size:12,weight:.semibold))
                                .foregroundStyle(Studio.secondary)
                        }
                        Text(server.hasConfirmedStatus ? server.onlinePlayers.formatted() : "—")
                            .font(.system(size:38,weight:.bold,design:.rounded))
                            .monospacedDigit()
                            .foregroundStyle(Studio.ink)
                        Text("OYUNCU ÇEVRİMİÇİ")
                            .font(.system(size:9,weight:.bold))
                            .tracking(0.7)
                            .foregroundStyle(Studio.secondary)
                    }
                    Spacer(minLength:2)
                    VStack(alignment:.trailing,spacing:8) {
                        Text("JAVA EDITION")
                            .font(.system(size:10,weight:.semibold,design:.monospaced))
                            .foregroundStyle(Studio.gold)
                        Text("oyna.blastermc.com")
                            .font(.system(size:12,weight:.semibold,design:.monospaced))
                            .foregroundStyle(Studio.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                        Button {
                            Studio.copy("oyna.blastermc.com")
                            copied=true
                        } label: {
                            Label(copied ? "Kopyalandı" : "IP kopyala",
                                  systemImage:copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size:11,weight:.semibold))
                                .foregroundStyle(Studio.ink)
                                .padding(.horizontal,12)
                                .padding(.vertical,9)
                                .background(Studio.pale,in:Capsule())
                        }
                        .buttonStyle(BlasterTapStyle())
                    }
                    .frame(maxWidth:165,alignment:.trailing)
                }
                if let verified=server.lastSuccess {
                    Divider().overlay(Studio.line)
                    Text("Son kontrol \(verified,style:.time) · \(server.sourceName)")
                        .font(.system(size:10))
                        .foregroundStyle(Studio.secondary)
                }
            }
        }
    }

    private var player:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"OYUNCU / SENİN HESABIN",title:"Kimliğin")
            Button {
                Studio.touch()
                open(4)
            } label: {
                StudioPanel {
                    HStack(spacing:13) {
                        ZStack {
                            RoundedRectangle(cornerRadius:13)
                                .fill(Studio.pale)
                            if let url=session.profile?.skinUrl {
                                AsyncImage(url:url) { image in
                                    image.resizable().scaledToFit()
                                } placeholder:{ BlasterLogo(size:42) }
                                .padding(5)
                            } else { BlasterLogo(size:42) }
                        }
                        .frame(width:54,height:58)
                        VStack(alignment:.leading,spacing:4) {
                            Text(session.profile?.minecraftName ?? "Oyuncu")
                                .font(.system(size:17,weight:.bold))
                                .foregroundStyle(Studio.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Text(session.profile?.rank ?? "Oyuncu hesabı")
                                .font(.system(size:11,weight:.medium))
                                .foregroundStyle(Studio.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength:3)
                        VStack(alignment:.trailing,spacing:3) {
                            Text((session.profile?.credits ?? 0).formatted())
                                .font(.system(size:21,weight:.bold,design:.rounded))
                                .foregroundStyle(Studio.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.66)
                            Text("KREDİ")
                                .font(.system(size:10,weight:.bold))
                                .foregroundStyle(Studio.gold)
                        }
                    }
                }
            }
            .buttonStyle(BlasterTapStyle())
        }
    }

    private var menu:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"KEŞFET / BLASTERMC",title:"Nereye gitmek istersin?")
            HStack(spacing:10) {
                tile("Dünya","SkyBlock ve lobi","globe.europe.africa.fill",index:1)
                tile("Mağaza","Ürünler ve VIP","bag.fill",index:2)
            }
            HStack(spacing:10) {
                tile("Sezon","Liderlik ve ödül","trophy.fill",index:3)
                Button { showNews=true } label: {
                    tileBody("Haberler","Etkinlik ve duyuru","megaphone.fill")
                }
                .buttonStyle(BlasterTapStyle())
            }
        }
    }
    private func tile(_ title:String,_ detail:String,_ symbol:String,index:Int)->some View {
        Button {
            Studio.touch()
            open(index)
        } label:{tileBody(title,detail,symbol)}
            .buttonStyle(BlasterTapStyle())
    }
    private func tileBody(_ title:String,_ detail:String,_ symbol:String)->some View {
        StudioPanel {
            Image(systemName:symbol)
                .font(.system(size:20))
                .foregroundStyle(Studio.gold)
                .padding(.bottom,4)
            Text(title)
                .font(.system(size:15,weight:.bold))
                .foregroundStyle(Studio.ink)
            Text(detail)
                .font(.system(size:11))
                .foregroundStyle(Studio.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth:.infinity,minHeight:113,alignment:.leading)
    }

    private var latest:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"TOPLULUK / GÜNDEM",title:"Blaster Haberler")
            if let first=(session.announcements + session.events)
                .sorted(by:{$0.createdAt>$1.createdAt}).first {
                Button { showNews=true } label: {
                    StudioPanel {
                        Text(first.category.uppercased())
                            .font(.system(size:10,weight:.bold))
                            .foregroundStyle(Studio.gold)
                        Text(first.title)
                            .font(.system(size:16,weight:.bold))
                            .foregroundStyle(Studio.ink)
                            .multilineTextAlignment(.leading)
                        Text(first.body)
                            .font(.system(size:12))
                            .foregroundStyle(Studio.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(BlasterTapStyle())
            } else {
                StudioEmpty(title:"Henüz duyuru bulunmuyor",
                            detail:session.dataError ?? "Yeni içerikler burada listelenecek.",
                            symbol:"megaphone")
            }
        }
    }
}

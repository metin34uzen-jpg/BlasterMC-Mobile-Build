import SwiftUI

// Full editorial front page, composed for a real player's account.
struct ForgeHomeView: View {
    @EnvironmentObject private var session: BlasterSession
    @ObservedObject var server: ServerStatusModel
    let open: (Int) -> Void
    let active: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var showNews = false
    @State private var copied = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                masthead
                adventure
                liveStrip
                passport
                spotlight
                dispatches
                footer
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 30)
            .frame(maxWidth: 660)
            .frame(maxWidth: .infinity)
        }
        .background(ForgeBackground())
        .sheet(isPresented: $showNews) {
            NewsView().environmentObject(session)
        }
        .task(id: active && scenePhase == .active) {
            guard active && scenePhase == .active else { return }
            while !Task.isCancelled {
                await server.refresh()
                do { try await Task.sleep(for: .seconds(5)) }
                catch { break }
            }
        }
        .refreshable {
            async let a: Void = server.refresh()
            async let b: Void = session.reloadPublic()
            async let c: Void = session.reloadProfile()
            _ = await (a,b,c)
        }
    }

    private var masthead: some View {
        HStack(spacing: 10) {
            ForgeEmblem(width: 43)
            VStack(alignment: .leading, spacing: 2) {
                Text("BLASTERMC")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Forge.midnight)
                Text("THE OVERWORLD / MOBILE")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .tracking(0.9)
                    .foregroundStyle(Forge.bronze)
            }
            Spacer()
            Button {
                Forge.impact()
                showNews = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    ForgeCut(cut: 10).fill(Forge.white)
                        .frame(width: 44, height: 44)
                        .overlay(ForgeCut(cut: 10).strokeBorder(Forge.stroke, lineWidth: 1))
                    Image(systemName: "bell.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Forge.midnight)
                        .frame(width: 44, height: 44)
                    if !session.announcements.isEmpty {
                        Circle().fill(Forge.gold)
                            .frame(width: 8, height: 8)
                            .offset(x:-6,y:6)
                    }
                }
            }
            .buttonStyle(BlasterTapStyle())
            .accessibilityLabel("Duyuru merkezini aç")
        }
    }

    private var adventure: some View {
        ZStack(alignment: .topLeading) {
            ForgeCut(cut: 23)
                .fill(LinearGradient(colors:[
                    Forge.midnight,Color(red:0.16,green:0.25,blue:0.38),
                    Color(red:0.28,green:0.30,blue:0.35)
                ],startPoint:.topLeading,endPoint:.bottomTrailing))
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Forge.sun.opacity(0.26))
                        .frame(width:225,height:225)
                        .blur(radius:50)
                        .offset(x:geo.size.width * 0.18,y:-60)
                    ForgeVoxelIsland()
                        .frame(width: geo.size.width * 0.85,
                               height: geo.size.height * 0.87)
                        .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.trailing)
                        .offset(x:22,y:6)
                }
            }
            .clipped()
            LinearGradient(colors:[Forge.midnight.opacity(0.88), Forge.midnight.opacity(0.48),.clear],
                           startPoint:.leading,endPoint:.trailing)
            VStack(alignment:.leading,spacing:9) {
                ForgeLabel(text:"NEW ERA / WORLD REFORGED",onDark:true)
                Spacer(minLength:2)
                Text("DÜNYAN\nBURADA\nBAŞLAR.")
                    .font(.system(size:35,weight:.black,design:.rounded))
                    .tracking(-1.2)
                    .foregroundStyle(.white)
                    .lineSpacing(-3)
                    .minimumScaleFactor(0.79)
                Text("Senin adan. Senin hikâyen.")
                    .font(.system(size:12,weight:.semibold))
                    .foregroundStyle(.white.opacity(0.81))
                HStack {
                    Button {
                        Forge.impact()
                        open(1)
                    } label: {
                        HStack(spacing:8) {
                            Text("DÜNYAYA GİR")
                            Image(systemName:"arrow.up.right")
                        }
                        .font(.system(size:11,weight:.black,design:.monospaced))
                        .foregroundStyle(Forge.midnight)
                        .padding(.horizontal,14)
                        .padding(.vertical,13)
                        .background(ForgeCut(cut:9).fill(Forge.sun))
                    }
                    .buttonStyle(BlasterTapStyle())
                    Spacer()
                    Text("01 / 05")
                        .font(.system(size:10,weight:.heavy,design:.monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top,8)
            }
            .padding(23)
        }
        .frame(height:292)
        .clipShape(ForgeCut(cut:23))
        .overlay(ForgeCut(cut:23).strokeBorder(Forge.sun.opacity(0.44),lineWidth:1))
        .shadow(color:Forge.midnight.opacity(0.21),radius:18,y:10)
        .accessibilityElement(children:.contain)
    }

    private var liveStrip: some View {
        VStack(alignment:.leading,spacing:11) {
            HStack(spacing:7) {
                Circle().fill(server.isStale ? .orange : server.isOnline ? .green : .red)
                    .frame(width:7,height:7)
                Text("BLASTER NETWORK")
                    .font(.system(size:10,weight:.black,design:.monospaced))
                    .tracking(1.1)
                    .foregroundStyle(Forge.midnight)
                Spacer()
                Text(server.statusText.uppercased())
                    .font(.system(size:10,weight:.heavy,design:.monospaced))
                    .foregroundStyle(Forge.bronze)
            }
            HStack(alignment:.center,spacing:10) {
                VStack(alignment:.leading,spacing:5) {
                    Text(server.hasConfirmedStatus ? server.onlinePlayers.formatted() : "—")
                        .font(.system(size:38,weight:.black,design:.rounded))
                        .contentTransition(.numericText())
                        .foregroundStyle(Forge.midnight)
                    Text("OYUNCU ÇEVRİMİÇİ")
                        .font(.system(size:9,weight:.black,design:.monospaced))
                        .tracking(0.8)
                        .foregroundStyle(Forge.muted)
                }
                Spacer()
                Rectangle().fill(Forge.stroke).frame(width:1,height:45)
                Spacer()
                VStack(alignment:.leading,spacing:5) {
                    Text("JAVA EDITION")
                        .font(.system(size:12,weight:.black,design:.monospaced))
                        .foregroundStyle(Forge.midnight)
                    Text("oyna.blastermc.com")
                        .font(.system(size:11,weight:.semibold,design:.monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(Forge.muted)
                }
                Button {
                    Forge.copy("oyna.blastermc.com")
                    copied = true
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size:14,weight:.bold))
                        .frame(width:40,height:40)
                        .foregroundStyle(Forge.midnight)
                        .background(Forge.sun,in:ForgeCut(cut:9))
                }
                .buttonStyle(BlasterTapStyle())
                .accessibilityLabel("Sunucu IP adresini kopyala")
            }
            if let success = server.lastSuccess {
                Text("Son doğrulama \(success,style:.time) • \(server.sourceName)")
                    .font(.system(size:9,weight:.medium,design:.monospaced))
                    .foregroundStyle(Forge.muted)
            } else {
                Text("Gerçek sunucu durumu bekleniyor.")
                    .font(.caption2)
                    .foregroundStyle(Forge.muted)
            }
        }
        .padding(16)
        .background(Forge.white,in:ForgeCut(cut:15))
        .overlay(ForgeCut(cut:15).strokeBorder(Forge.stroke.opacity(0.65),lineWidth:1))
    }

    private var passport: some View {
        VStack(alignment:.leading,spacing:12) {
            ForgeHeading(eyebrow:"YOUR IDENTITY / 02",
                         title:"Oyuncu kartın",
                         subtitle:"Gerçek hesabın, gerçek bakiyen.")
            Button { open(4) } label: {
                ForgeSurface(dark:true) {
                    HStack(spacing:14) {
                        ZStack {
                            ForgeCut(cut:9).fill(Forge.sun.opacity(0.12))
                            if let skin = session.profile?.skinUrl {
                                AsyncImage(url:skin) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    BlasterLogo(size:52)
                                }
                                .padding(6)
                            } else { BlasterLogo(size:52) }
                        }
                        .frame(width:68,height:72)
                        .overlay(ForgeCut(cut:9).strokeBorder(Forge.sun.opacity(0.3),lineWidth:1))
                        VStack(alignment:.leading,spacing:7) {
                            ForgeLabel(text:"BLASTER CITIZEN",onDark:true)
                            Text(session.profile?.minecraftName ?? "Oyuncu")
                                .font(.system(size:19,weight:.black,design:.rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(session.profile?.rank ?? "Rütbe bilgisi bekleniyor")
                                .font(.system(size:11,weight:.semibold))
                                .foregroundStyle(.white.opacity(0.65))
                                .lineLimit(1)
                        }
                        Spacer(minLength:2)
                        VStack(alignment:.trailing,spacing:7) {
                            Image(systemName:"circle.hexagongrid.fill")
                                .foregroundStyle(Forge.sun)
                            Text((session.profile?.credits ?? 0).formatted())
                                .font(.system(size:19,weight:.black,design:.rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("KREDİ")
                                .font(.system(size:9,weight:.bold,design:.monospaced))
                                .foregroundStyle(Forge.sun)
                        }
                    }
                }
            }
            .buttonStyle(BlasterTapStyle())
        }
    }

    private var spotlight: some View {
        VStack(alignment:.leading,spacing:12) {
            ForgeHeading(eyebrow:"SELECT YOUR PATH / 03",
                         title:"Bir sonraki adım",
                         subtitle:"Dünyanın farklı köşelerine geç.")
            HStack(spacing:10) {
                action("SEZON","Zirve ve ödüller","trophy.fill",idx:3)
                action("MARKET","VIP koleksiyonu","crown.fill",idx:2)
            }
        }
    }

    private func action(_ title:String,_ text:String,_ symbol:String,idx:Int) -> some View {
        Button {
            Forge.impact()
            open(idx)
        } label: {
            VStack(alignment:.leading,spacing:11) {
                Image(systemName:symbol)
                    .font(.system(size:23,weight:.medium))
                    .foregroundStyle(Forge.gold)
                Spacer(minLength:4)
                Text(title)
                    .font(.system(size:13,weight:.black,design:.monospaced))
                    .tracking(0.3)
                    .foregroundStyle(Forge.midnight)
                Text(text)
                    .font(.system(size:11))
                    .foregroundStyle(Forge.muted)
                    .lineLimit(2)
                HStack {
                    Spacer()
                    Image(systemName:"arrow.up.right")
                        .foregroundStyle(Forge.gold)
                }
            }
            .frame(maxWidth:.infinity,minHeight:116,alignment:.leading)
            .padding(16)
            .background(Forge.white,in:ForgeCut(cut:15))
            .overlay(ForgeCut(cut:15).strokeBorder(Forge.stroke.opacity(0.63),lineWidth:1))
        }
        .buttonStyle(BlasterTapStyle())
    }

    private var dispatches: some View {
        VStack(alignment:.leading,spacing:12) {
            HStack {
                ForgeHeading(eyebrow:"THE SIGNAL / 04",title:"Son gelişmeler")
                Spacer()
                Button("HEPSİ →") { showNews = true }
                    .font(.system(size:10,weight:.black,design:.monospaced))
                    .foregroundStyle(Forge.bronze)
            }
            if let notice = (session.announcements+session.events).sorted(by:{$0.createdAt>$1.createdAt}).first {
                Button { showNews = true } label: {
                    ForgeSurface {
                        ForgeLabel(text:notice.category)
                        Text(notice.title)
                            .font(.system(size:18,weight:.black,design:.rounded))
                            .foregroundStyle(Forge.midnight)
                        Text(notice.body)
                            .font(.system(size:12))
                            .foregroundStyle(Forge.muted)
                            .lineLimit(3)
                        Text(notice.createdAt,style:.date)
                            .font(.system(size:10,weight:.bold,design:.monospaced))
                            .foregroundStyle(Forge.bronze)
                    }
                }
                .buttonStyle(BlasterTapStyle())
            } else {
                ForgeSurface {
                    Label("Yeni duyuru bekleniyor",systemImage:"waveform.path")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Forge.midnight)
                    Text("BlasterMC haberleri sunucudan geldiğinde burada gösterilir.")
                        .font(.caption)
                        .foregroundStyle(Forge.muted)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing:8) {
            Rectangle().fill(Forge.gold).frame(width:19,height:2)
            Text("BLASTERMC  /  BUILT FOR THE OVERWORLD")
                .font(.system(size:9,weight:.black,design:.monospaced))
                .foregroundStyle(Forge.muted)
        }
        .frame(maxWidth:.infinity)
        .padding(.top,8)
    }
}

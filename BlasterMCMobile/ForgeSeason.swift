import SwiftUI

struct ForgeSeasonView: View {
    @EnvironmentObject private var session: BlasterSession
    @State private var query=""
    @State private var selectedSection=0

    private var rankings:[SeasonRanking] {
        (session.season?.rankings ?? []).filter {
            query.isEmpty ||
            $0.ownerUsername.localizedStandardContains(query) ||
            $0.islandName.localizedStandardContains(query)
        }
    }

    var body:some View {
        ScrollView(showsIndicators:false) {
            VStack(alignment:.leading,spacing:20) {
                heading
                arena
                podium
                sectionPicker
                if selectedSection==0 {
                    table
                } else {
                    rewards
                    schedule
                }
                footer
            }
            .padding(.horizontal,18)
            .padding(.top,18)
            .padding(.bottom,28)
            .frame(maxWidth:660)
            .frame(maxWidth:.infinity)
        }
        .background(ForgeBackground())
        .refreshable { await session.reloadSeason() }
        .task { await session.reloadSeason() }
    }

    private var heading:some View {
        HStack(alignment:.center) {
            VStack(alignment:.leading,spacing:6) {
                ForgeLabel(text:"THE ARENA / 03")
                Text("Zirve senin olsun.")
                    .font(.system(size:29,weight:.black,design:.rounded))
                    .tracking(-1)
                    .foregroundStyle(Forge.midnight)
                Text("SkyBlock adalarının gerçek sıralaması")
                    .font(.caption)
                    .foregroundStyle(Forge.muted)
            }
            Spacer()
            Image(systemName:"trophy.fill")
                .font(.system(size:31,weight:.light))
                .foregroundStyle(Forge.gold)
                .frame(width:50,height:50)
                .background(Forge.white,in:ForgeCut(cut:10))
                .overlay(ForgeCut(cut:10).strokeBorder(Forge.stroke))
        }
    }

    private var arena:some View {
        ZStack(alignment:.topLeading) {
            ForgeCut(cut:21).fill(LinearGradient(
                colors:[Forge.midnight,Color(red:0.27,green:0.25,blue:0.27),Forge.bronze],
                startPoint:.topLeading,endPoint:.bottomTrailing))
            GeometryReader { g in
                ZStack {
                    Circle().fill(Forge.sun.opacity(0.19))
                        .frame(width:190,height:190)
                        .blur(radius:45)
                        .offset(x:g.size.width*0.28,y:-35)
                    ForgeVoxelIsland()
                        .frame(width:g.size.width*0.91,height:g.size.height*0.93)
                        .offset(x:g.size.width*0.22,y:10)
                }
            }
            LinearGradient(colors:[Forge.midnight.opacity(0.92),Forge.midnight.opacity(0.40),.clear],
                           startPoint:.leading,endPoint:.trailing)
            VStack(alignment:.leading,spacing:10) {
                ForgeLabel(text:"SKYBLOCK / LEADERBOARD",onDark:true)
                Spacer()
                Text("KRALLIKLAR\nYARIŞI.")
                    .font(.system(size:34,weight:.black,design:.rounded))
                    .tracking(-0.9)
                    .foregroundStyle(.white)
                Text(session.season?.title ?? "BlasterMC Sezon Arenası")
                    .font(.system(size:11,weight:.bold))
                    .foregroundStyle(Forge.sun)
                    .lineLimit(2)
            }
            .padding(22)
        }
        .frame(height:237)
        .clipShape(ForgeCut(cut:21))
        .overlay(ForgeCut(cut:21).strokeBorder(Forge.sun.opacity(0.37)))
    }

    private var podium:some View {
        VStack(alignment:.leading,spacing:12) {
            ForgeHeading(eyebrow:"THE CHAMPIONS",title:"Onur kürsüsü",
                         subtitle:"Sıralama ve ada değerleri sunucu verileridir.")
            let top=Array((session.season?.rankings ?? []).prefix(3))
            if top.isEmpty {
                ForgeSurface {
                    Label("Doğrulanmış sıralama bekleniyor",systemImage:"chart.bar.xaxis")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Forge.midnight)
                    Text("Sunucudan gerçek oyuncu ve ada verileri gelmeden kürsü doldurulmaz.")
                        .font(.caption)
                        .foregroundStyle(Forge.muted)
                }
            } else {
                ForEach(top) { rank in
                    HStack(spacing:13) {
                        ZStack {
                            ForgeCut(cut:8)
                                .fill(rank.rankPosition==1 ? Forge.sun : Forge.midnight)
                            Text("#\(rank.rankPosition)")
                                .font(.system(size:21,weight:.black,design:.monospaced))
                                .foregroundStyle(rank.rankPosition==1 ? Forge.midnight : Forge.sun)
                        }
                        .frame(width:51,height:58)
                        VStack(alignment:.leading,spacing:5) {
                            Text(rank.ownerUsername)
                                .font(.system(size:17,weight:.black,design:.rounded))
                                .foregroundStyle(Forge.midnight)
                                .lineLimit(1)
                            Text(rank.islandName)
                                .font(.caption)
                                .foregroundStyle(Forge.muted)
                                .lineLimit(1)
                        }
                        Spacer(minLength:0)
                        VStack(alignment:.trailing,spacing:4) {
                            Text(rank.islandValue.formatted())
                                .font(.system(size:16,weight:.black,design:.monospaced))
                                .foregroundStyle(Forge.bronze)
                            Text("ADA DEĞERİ")
                                .font(.system(size:9,weight:.black,design:.monospaced))
                                .foregroundStyle(Forge.muted)
                        }
                    }
                    .padding(11)
                    .background(Forge.white,in:ForgeCut(cut:12))
                    .overlay(ForgeCut(cut:12).strokeBorder(Forge.stroke.opacity(0.70)))
                }
            }
        }
    }

    private var sectionPicker:some View {
        HStack(spacing:7) {
            Button {
                Forge.impact()
                selectedSection=0
            } label: {
                ForgePixelChip(title:"TÜM SIRALAMA",symbol:"list.number",selected:selectedSection==0)
                    .frame(maxWidth:.infinity)
            }
            Button {
                Forge.impact()
                selectedSection=1
            } label: {
                ForgePixelChip(title:"ÖDÜLLER / TAKVİM",symbol:"gift.fill",selected:selectedSection==1)
                    .frame(maxWidth:.infinity)
            }
        }
        .buttonStyle(BlasterTapStyle())
    }

    private var table:some View {
        VStack(alignment:.leading,spacing:12) {
            ForgeHeading(eyebrow:"LIVE / ALL ISLANDS",title:"Ada sıralaması")
            HStack(spacing:9) {
                Image(systemName:"magnifyingglass")
                    .foregroundStyle(Forge.gold)
                TextField("Oyuncu veya ada adını ara",text:$query)
                    .font(.subheadline)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button { query="" } label: {
                        Image(systemName:"xmark.circle.fill")
                            .foregroundStyle(Forge.muted)
                    }
                }
            }
            .padding(14)
            .background(Forge.white,in:ForgeCut(cut:10))
            .overlay(ForgeCut(cut:10).strokeBorder(Forge.stroke.opacity(0.6)))
            if rankings.isEmpty {
                ForgeSurface {
                    Text(session.season?.rankings?.isEmpty == false ?
                         "Aramanla eşleşen bir ada bulunamadı." :
                         "Liderlik tablosu verisi bekleniyor.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Forge.midnight)
                }
            } else {
                ForEach(rankings) { item in
                    HStack(spacing:11) {
                        Text(String(format:"%02d",item.rankPosition))
                            .font(.system(size:15,weight:.black,design:.monospaced))
                            .foregroundStyle(Forge.gold)
                            .frame(width:36,alignment:.leading)
                        VStack(alignment:.leading,spacing:4) {
                            Text(item.ownerUsername)
                                .font(.system(size:13,weight:.heavy))
                                .foregroundStyle(Forge.midnight)
                            Text(item.islandName)
                                .font(.caption2)
                                .foregroundStyle(Forge.muted)
                                .lineLimit(1)
                        }
                        Spacer(minLength:0)
                        Text(item.islandValue.formatted())
                            .font(.system(size:12,weight:.black,design:.monospaced))
                            .foregroundStyle(Forge.midnight)
                    }
                    .padding(14)
                    .background(Forge.white,in:ForgeCut(cut:10))
                    .overlay(ForgeCut(cut:10).strokeBorder(Forge.stroke.opacity(0.6)))
                }
            }
        }
    }

    private var rewards:some View {
        VStack(alignment:.leading,spacing:12) {
            ForgeHeading(eyebrow:"SEASON / REWARDS",title:"Sezon ganimetleri",
                         subtitle:"Sadece resmî olarak açıklanmış ödüller.")
            if let entries=session.season?.rewards,!entries.isEmpty {
                ForEach(entries) { entry in
                    ForgeSurface {
                        HStack(alignment:.top,spacing:12) {
                            ForgeStoreGlyph(category:"kasa")
                                .frame(width:67,height:75)
                            VStack(alignment:.leading,spacing:6) {
                                Text(entry.title)
                                    .font(.system(size:17,weight:.black,design:.rounded))
                                    .foregroundStyle(Forge.midnight)
                                Text(entry.description)
                                    .font(.caption)
                                    .foregroundStyle(Forge.muted)
                                if entry.isClaimed==true {
                                    Label("Teslim edildi",systemImage:"checkmark.seal.fill")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Forge.gold)
                                }
                            }
                        }
                    }
                }
            } else {
                ForgeSurface {
                    Label("Ödüller henüz açıklanmadı",systemImage:"gift.fill")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(Forge.midnight)
                    Text("Sahte ödül veya teslimat durumu gösterilmez.")
                        .font(.caption)
                        .foregroundStyle(Forge.muted)
                }
            }
        }
    }

    private var schedule:some View {
        VStack(alignment:.leading,spacing:11) {
            ForgeHeading(eyebrow:"SEASON / TIMELINE",title:"Sezon takvimi")
            if let events=session.season?.milestones,!events.isEmpty {
                ForEach(events) { event in
                    HStack(alignment:.top,spacing:12) {
                        Rectangle().fill(Forge.gold).frame(width:3)
                        VStack(alignment:.leading,spacing:5) {
                            Text(event.title)
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(Forge.midnight)
                            Text(event.date ?? "Tarih açıklanmadı")
                                .font(.caption)
                                .foregroundStyle(Forge.muted)
                        }
                        Spacer()
                    }
                    .frame(minHeight:52)
                    .padding(12)
                    .background(Forge.white,in:ForgeCut(cut:10))
                }
            } else {
                ForgeSurface {
                    Text("Resmî sezon tarihleri bekleniyor.")
                        .font(.caption)
                        .foregroundStyle(Forge.muted)
                }
            }
        }
    }

    private var footer:some View {
        VStack(alignment:.leading,spacing:10) {
            if let updated=session.season?.updatedAt {
                Text("Son güncelleme: \(updated,style:.relative)")
                    .font(.caption2)
                    .foregroundStyle(Forge.muted)
            }
            if let message=session.dataError {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(Forge.muted)
            }
            ForgeButton(title:"Sezon verilerini yenile",symbol:"arrow.clockwise") {
                Task { await session.reloadSeason() }
            }
        }
    }
}

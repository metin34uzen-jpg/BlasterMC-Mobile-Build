import SwiftUI

struct StudioSeasonView:View {
    @EnvironmentObject private var session:BlasterSession
    @State private var page=0
    @State private var search=""

    private var filtered:[SeasonRanking] {
        (session.season?.rankings ?? []).filter {
            search.isEmpty || $0.ownerUsername.localizedStandardContains(search) ||
            $0.islandName.localizedStandardContains(search)
        }
    }

    var body:some View {
        ScrollView(showsIndicators:false) {
            VStack(alignment:.leading,spacing:19) {
                StudioSection(kicker:"SKYBLOCK / SEZON",title:"Sezon arenası")
                StudioHero(symbol:"trophy",height:155) {
                    VStack(alignment:.leading,spacing:7) {
                        Text("BLASTERMC / SEASON")
                            .font(.system(size:10,weight:.bold,design:.monospaced))
                            .foregroundStyle(Studio.sunlight)
                        Text("Zirveye giden yol.")
                            .font(.system(size:25,weight:.bold,design:.rounded))
                            .foregroundStyle(.white)
                        Text(session.season?.title ?? "Ada sıralaması ve sezon ödülleri")
                            .font(.system(size:11))
                            .foregroundStyle(.white.opacity(0.80))
                            .lineLimit(2)
                    }
                }
                standings
                HStack(spacing:8) {
                    tab("Liderlik tablosu",number:0)
                    tab("Ödüller ve takvim",number:1)
                }
                if page==0 {
                    leaderboard
                } else {
                    rewards
                    milestones
                }
                StudioCTA(title:"Sezon verilerini yenile",symbol:"arrow.clockwise",subtle:true) {
                    Task { await session.reloadSeason() }
                }
                if let error=session.dataError {
                    Text(error)
                        .font(.system(size:11))
                        .foregroundStyle(Studio.secondary)
                        .fixedSize(horizontal:false,vertical:true)
                }
            }
            .padding(.horizontal,18)
            .padding(.top,18)
            .padding(.bottom,28)
            .frame(maxWidth:620)
            .frame(maxWidth:.infinity)
        }
        .background(StudioBackground())
        .task { await session.reloadSeason() }
        .refreshable { await session.reloadSeason() }
    }

    private func tab(_ title:String,number:Int)->some View {
        Button {
            Studio.touch()
            page=number
        } label: {
            Text(title)
                .font(.system(size:11,weight:.semibold))
                .frame(maxWidth:.infinity,minHeight:42)
                .foregroundStyle(page==number ? .white : Studio.ink)
                .background(page==number ? Studio.navy : Studio.paper,
                            in:RoundedRectangle(cornerRadius:12))
                .overlay(RoundedRectangle(cornerRadius:12).strokeBorder(Studio.line.opacity(0.6)))
        }
        .buttonStyle(BlasterTapStyle())
    }

    private var standings:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"CANLI / SIRALAMA",title:"İlk üç ada")
            if let leaders=session.season?.rankings,!leaders.isEmpty {
                ForEach(Array(leaders.prefix(3))) { rank in
                    rankingRow(rank,podium:true)
                }
            } else {
                StudioEmpty(title:"Sıralama bilgisi bekleniyor",
                            detail:"Yalnızca sunucunun doğruladığı ada değerleri gösterilir.",
                            symbol:"chart.bar")
            }
        }
    }

    private func rankingRow(_ entry:SeasonRanking,podium:Bool)->some View {
        StudioPanel(padding:14) {
            HStack(alignment:.center,spacing:12) {
                Text("#\(entry.rankPosition)")
                    .font(.system(size:17,weight:.bold,design:.rounded))
                    .foregroundStyle(podium ? Studio.gold : Studio.ink)
                    .frame(width:38)
                VStack(alignment:.leading,spacing:5) {
                    Text(entry.ownerUsername)
                        .font(.system(size:14,weight:.semibold))
                        .foregroundStyle(Studio.ink)
                        .fixedSize(horizontal:false,vertical:true)
                    Text(entry.islandName)
                        .font(.system(size:11))
                        .foregroundStyle(Studio.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth:.infinity,alignment:.leading)
                VStack(alignment:.trailing,spacing:4) {
                    Text(entry.islandValue.formatted())
                        .font(.system(size:14,weight:.bold,design:.rounded))
                        .foregroundStyle(Studio.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("ADA DEĞERİ")
                        .font(.system(size:9,weight:.semibold))
                        .foregroundStyle(Studio.gold)
                        .lineLimit(1)
                }
            }
        }
    }

    private var leaderboard:some View {
        VStack(alignment:.leading,spacing:10) {
            StudioSection(kicker:"OYUNCULAR / LİSTE",title:"Liderlik tablosu")
            HStack(spacing:9) {
                Image(systemName:"magnifyingglass").foregroundStyle(Studio.gold)
                TextField("Oyuncu veya ada ara",text:$search)
                    .font(.system(size:13))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !search.isEmpty {
                    Button { search="" } label: {
                        Image(systemName:"xmark.circle.fill").foregroundStyle(Studio.secondary)
                    }
                }
            }
            .padding(13)
            .background(Studio.paper,in:RoundedRectangle(cornerRadius:12))
            .overlay(RoundedRectangle(cornerRadius:12).strokeBorder(Studio.line))
            if filtered.isEmpty {
                StudioEmpty(title:"Ada bulunamadı",
                            detail:"Sıralama henüz gelmemiş olabilir veya aramanın eşleşmesi yok.",
                            symbol:"magnifyingglass")
            } else {
                LazyVStack(spacing:8) {
                    ForEach(filtered) { rank in
                        rankingRow(rank,podium:rank.rankPosition<=3)
                    }
                }
            }
        }
    }

    private var rewards:some View {
        VStack(alignment:.leading,spacing:10) {
            StudioSection(kicker:"RESMÎ / ÖDÜLLER",title:"Sezon kazanımları")
            if let entries=session.season?.rewards,!entries.isEmpty {
                ForEach(entries) { entry in
                    StudioPanel {
                        HStack(alignment:.top,spacing:12) {
                            Image(systemName:"gift.fill")
                                .font(.system(size:21))
                                .foregroundStyle(Studio.gold)
                                .frame(width:33)
                            VStack(alignment:.leading,spacing:6) {
                                Text(entry.title)
                                    .font(.system(size:15,weight:.semibold))
                                    .foregroundStyle(Studio.ink)
                                    .fixedSize(horizontal:false,vertical:true)
                                Text(entry.description)
                                    .font(.system(size:12))
                                    .foregroundStyle(Studio.secondary)
                                    .fixedSize(horizontal:false,vertical:true)
                                if entry.isClaimed==true {
                                    Label("Teslim edildi",systemImage:"checkmark.seal.fill")
                                        .font(.system(size:11,weight:.semibold))
                                        .foregroundStyle(Studio.gold)
                                }
                            }
                        }
                    }
                }
            } else {
                StudioEmpty(title:"Ödüller açıklanmadı",
                            detail:"Sunucuda yayımlanmayan bir ödülü göstermiyoruz.",
                            symbol:"gift")
            }
        }
    }

    private var milestones:some View {
        VStack(alignment:.leading,spacing:10) {
            StudioSection(kicker:"SEZON / TAKVİM",title:"Önemli tarihler")
            if let events=session.season?.milestones,!events.isEmpty {
                ForEach(events) { event in
                    StudioPanel(padding:14) {
                        Text(event.title)
                            .font(.system(size:14,weight:.semibold))
                            .foregroundStyle(Studio.ink)
                        Text(event.date ?? "Tarih açıklanmadı")
                            .font(.system(size:11))
                            .foregroundStyle(Studio.secondary)
                    }
                }
            } else {
                StudioEmpty(title:"Takvim bekleniyor",
                            detail:"Resmî tarihler web API'sinden alınacak.",
                            symbol:"calendar")
            }
        }
    }
}

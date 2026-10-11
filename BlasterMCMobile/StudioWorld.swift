import SwiftUI

struct StudioWorldView:View {
    @ObservedObject var server:ServerStatusModel
    @State private var section=0
    @State private var copied=""
    private let names=["SkyBlock","Lobi","Topluluk"]

    var body:some View {
        ScrollView(showsIndicators:false) {
            VStack(alignment:.leading,spacing:20) {
                StudioSection(kicker:"DÜNYA / BLASTERMC",title:"Oyun rehberi")
                StudioHero(symbol:"globe.europe.africa",height:160) {
                    VStack(alignment:.leading,spacing:7) {
                        Text("BLASTERMC WORLD")
                            .font(.system(size:10,weight:.bold,design:.monospaced))
                            .foregroundStyle(Studio.sunlight)
                        Text("Macera burada başlıyor.")
                            .font(.system(size:25,weight:.bold,design:.rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal:false,vertical:true)
                        Text("SkyBlock · Lobi · Topluluk")
                            .font(.system(size:11))
                            .foregroundStyle(.white.opacity(0.77))
                    }
                }
                picker
                description
                shortcuts
                ipCard
            }
            .padding(.horizontal,18)
            .padding(.top,18)
            .padding(.bottom,30)
            .frame(maxWidth:620)
            .frame(maxWidth:.infinity)
        }
        .background(StudioBackground())
        .refreshable { await server.refresh() }
    }

    private var picker:some View {
        HStack(spacing:8) {
            ForEach(0..<3,id:\.self) { index in
                Button {
                    Studio.touch()
                    section=index
                } label: {
                    Text(names[index])
                        .font(.system(size:12,weight:.semibold))
                        .frame(maxWidth:.infinity,minHeight:42)
                        .foregroundStyle(section == index ? .white : Studio.ink)
                        .background(section == index ? Studio.navy : Studio.paper,
                                    in:RoundedRectangle(cornerRadius:12))
                        .overlay(RoundedRectangle(cornerRadius:12)
                            .strokeBorder(Studio.line.opacity(0.65)))
                }
                .buttonStyle(BlasterTapStyle())
            }
        }
    }

    private var description:some View {
        StudioPanel {
            HStack(alignment:.top,spacing:12) {
                Image(systemName:section == 0 ? "square.stack.3d.up" :
                      section == 1 ? "house" : "person.3")
                    .font(.system(size:22))
                    .foregroundStyle(Studio.gold)
                    .frame(width:30)
                VStack(alignment:.leading,spacing:7) {
                    Text(section == 0 ? "Kendi adanı kur." :
                         section == 1 ? "Ana merkezine dön." : "Topluluğa katıl.")
                        .font(.system(size:17,weight:.bold))
                        .foregroundStyle(Studio.ink)
                        .fixedSize(horizontal:false,vertical:true)
                    Text(section == 0 ?
                         "SkyBlock adanı geliştirmek ve ada komutlarını öğrenmek için aşağıdaki kısayolları kullan." :
                         section == 1 ?
                         "Sunucuya bağlandıktan sonra lobi komutuyla ana merkeze geri dönebilirsin." :
                         "BlasterMC'nin resmî web sitesine ve Discord topluluğuna eriş.")
                        .font(.system(size:12))
                        .foregroundStyle(Studio.secondary)
                        .fixedSize(horizontal:false,vertical:true)
                }
            }
        }
    }

    private var shortcuts:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"REHBER / KISAYOLLAR",
                          title:section == 2 ? "Bağlantılar" : "Oyun komutları")
            if section==0 {
                command("/is",name:"Ada menüsü")
                command("/is home",name:"Adana dön")
                command("/is top",name:"Ada sıralaması")
            } else if section==1 {
                command("/lobi",name:"Lobiye ışınlan")
                command("/is",name:"SkyBlock adan")
            } else {
                Link(destination:URL(string:"https://blastermc.com")!) {
                    linkRow("Web sitesi","Resmî BlasterMC portalı",symbol:"globe")
                }
                Link(destination:URL(string:"https://discord.blastermc.com")!) {
                    linkRow("Discord","Resmî topluluk adresi",symbol:"person.2.fill")
                }
            }
            if section != 2 {
                Text("Komutlar yalnızca kopyalanır; uygulama Minecraft içinde işlem yapmaz. Sunucu yapılandırmasına bağlı olarak değişebilir.")
                    .font(.system(size:11))
                    .foregroundStyle(Studio.secondary)
                    .fixedSize(horizontal:false,vertical:true)
            }
        }
    }

    private func linkRow(_ title:String,_ caption:String,symbol:String)->some View {
        StudioPanel(padding:14) {
            HStack(spacing:12) {
                Image(systemName:symbol)
                    .foregroundStyle(Studio.gold)
                    .frame(width:26)
                VStack(alignment:.leading,spacing:4) {
                    Text(title)
                        .font(.system(size:14,weight:.semibold))
                        .foregroundStyle(Studio.ink)
                    Text(caption)
                        .font(.system(size:11))
                        .foregroundStyle(Studio.secondary)
                }
                Spacer()
                Image(systemName:"arrow.up.right").foregroundStyle(Studio.gold)
            }
        }
    }

    private func command(_ value:String,name:String)->some View {
        Button {
            Studio.copy(value)
            copied=value
        } label: {
            StudioPanel(padding:14) {
                HStack(spacing:12) {
                    VStack(alignment:.leading,spacing:4) {
                        Text(name)
                            .font(.system(size:14,weight:.semibold))
                            .foregroundStyle(Studio.ink)
                        Text(value)
                            .font(.system(size:11,weight:.semibold,design:.monospaced))
                            .foregroundStyle(Studio.gold)
                    }
                    Spacer()
                    Label(copied == value ? "Kopyalandı" : "Kopyala",
                          systemImage:copied == value ? "checkmark" : "doc.on.doc")
                        .font(.system(size:11,weight:.semibold))
                        .foregroundStyle(Studio.secondary)
                }
            }
        }
        .buttonStyle(BlasterTapStyle())
    }

    private var ipCard:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"CANLI / SUNUCU",title:"Bağlanmaya hazır")
            StudioPanel {
                HStack {
                    Circle().fill(server.isStale ? .orange :
                                  (server.isOnline ? .green : .gray))
                        .frame(width:8,height:8)
                    Text(server.statusText)
                        .font(.system(size:12,weight:.medium))
                        .foregroundStyle(Studio.secondary)
                    Spacer()
                    if server.hasConfirmedStatus {
                        Text("\(server.onlinePlayers) oyuncu")
                            .font(.system(size:12,weight:.semibold))
                            .foregroundStyle(Studio.ink)
                    }
                }
                Text("oyna.blastermc.com")
                    .font(.system(size:18,weight:.bold,design:.monospaced))
                    .foregroundStyle(Studio.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                StudioCTA(title:copied == "ip" ? "Adres kopyalandı" : "Sunucu adresini kopyala",
                          symbol:copied == "ip" ? "checkmark" : "doc.on.doc") {
                    Studio.copy("oyna.blastermc.com")
                    copied="ip"
                }
            }
        }
    }
}

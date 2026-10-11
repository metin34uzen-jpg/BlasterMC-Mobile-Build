import SwiftUI

struct ForgeWorldView: View {
    @EnvironmentObject private var session: BlasterSession
    @ObservedObject var server: ServerStatusModel
    @State private var chapter = 0
    @State private var copiedCommand: String?
    @State private var news = false

    private let chapters = ["SKYBLOCK", "LOBİ", "TOPLULUK"]

    var body: some View {
        ScrollView(showsIndicators:false) {
            VStack(alignment:.leading,spacing:20) {
                heading
                atlas
                chapterSelector
                fieldGuide
                commands
                connection
            }
            .padding(.horizontal,18)
            .padding(.top,18)
            .padding(.bottom,30)
            .frame(maxWidth:660)
            .frame(maxWidth:.infinity)
        }
        .background(ForgeBackground())
        .sheet(isPresented:$news) { NewsView().environmentObject(session) }
        .refreshable { await server.refresh() }
    }

    private var heading: some View {
        HStack(alignment:.center) {
            VStack(alignment:.leading,spacing:5) {
                ForgeLabel(text:"WORLD ATLAS / 01")
                Text("Dünyanı keşfet.")
                    .font(.system(size:29,weight:.black,design:.rounded))
                    .tracking(-1.1)
                    .foregroundStyle(Forge.midnight)
                Text("BlasterMC'nin oyun rehberi")
                    .font(.caption)
                    .foregroundStyle(Forge.muted)
            }
            Spacer(minLength:3)
            ForgeEmblem(width:53)
        }
    }

    private var atlas: some View {
        ZStack(alignment:.topLeading) {
            ForgeCut(cut:21)
                .fill(LinearGradient(colors:[Forge.midnight,Forge.midnight2],
                                     startPoint:.topLeading,endPoint:.bottomTrailing))
            GeometryReader { g in
                ForgeVoxelIsland()
                    .frame(width:g.size.width*0.95,height:g.size.height*0.99)
                    .offset(x:g.size.width*0.13,y:3)
                    .opacity(0.96)
            }
            LinearGradient(colors:[Forge.midnight.opacity(0.88),Forge.midnight.opacity(0.30),.clear],
                           startPoint:.leading,endPoint:.trailing)
            VStack(alignment:.leading,spacing:8) {
                ForgeLabel(text:"EXPEDITION / \(chapter+1) OF 3",onDark:true)
                Spacer()
                Text(chapter == 0 ? "GÖKYÜZÜNDE\nYÜKSEL." :
                     chapter == 1 ? "YOLCULUK\nBURADA BAŞLAR." :
                     "BİRLİKTE\nGÜÇLÜYÜZ.")
                    .font(.system(size:28,weight:.black,design:.rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal:false,vertical:true)
                Text(chapter == 0 ? "SkyBlock dünyası" :
                     chapter == 1 ? "BlasterMC giriş merkezi" :
                     "BlasterMC topluluğu")
                    .font(.system(size:11,weight:.bold))
                    .foregroundStyle(Forge.sun)
            }
            .padding(21)
        }
        .frame(height:229)
        .clipShape(ForgeCut(cut:21))
        .overlay(ForgeCut(cut:21).strokeBorder(Forge.sun.opacity(0.32)))
    }

    private var chapterSelector: some View {
        HStack(spacing:7) {
            ForEach(0..<3,id:\.self) { i in
                Button {
                    Forge.impact()
                    withAnimation(.easeInOut(duration:0.23)) { chapter=i }
                } label: {
                    ForgePixelChip(title:chapters[i],symbol:i == 0 ? "square.stack.3d.up.fill" :
                                   i == 1 ? "building.columns.fill" : "person.3.fill",
                                   selected:chapter == i)
                        .frame(maxWidth:.infinity)
                }
                .buttonStyle(BlasterTapStyle())
            }
        }
    }

    private var fieldGuide: some View {
        ForgeSurface {
            ForgeLabel(text:"FIELD NOTES / GUIDE")
            Text(chapter == 0 ? "Kendi adanı kur." :
                 chapter == 1 ? "Ana merkezine dön." :
                 "Topluluğa bağlan.")
                .font(.system(size:22,weight:.black,design:.rounded))
                .foregroundStyle(Forge.midnight)
            Text(chapter == 0 ?
                 "BSkyBlock adana ışınlan, adanı büyüt ve sezon sıralamasını takip et. Kullanılabilir komutlar sunucu yapılandırmasına bağlıdır." :
                 chapter == 1 ?
                 "Lobi, oyun dünyalarına geçiş için ana duraktır. Minecraft sohbetinde /lobi yazarak erişebilirsin." :
                 "Oyuncu duyurularını, etkinlikleri ve topluluk paylaşımlarını resmî kanallardan takip edebilirsin.")
                .font(.system(size:13))
                .foregroundStyle(Forge.muted)
                .fixedSize(horizontal:false,vertical:true)
        }
    }

    private var commands: some View {
        VStack(alignment:.leading,spacing:11) {
            ForgeHeading(eyebrow:"GAMEPLAY / COMMANDS",
                         title:chapter == 2 ? "Topluluk bağlantıları" : "Komut rehberi",
                         subtitle:chapter == 2 ? "Resmî BlasterMC kanallarına açılır." : "Komutlar panoya kopyalanır; iOS'tan çalıştırılmaz.")
            if chapter == 0 {
                command("/is","Ada menüsü","BSkyBlock komut menüsü")
                command("/is home","Evine dön","Ada ev noktasına git")
                command("/is top","Ada sıralaması","Sunucu sürümüne göre değişebilir")
            } else if chapter == 1 {
                command("/lobi","Lobiye dön","Ana merkeze git")
                command("/is","SkyBlock","Ada menüsünü aç")
            } else {
                Link(destination:URL(string:"https://blastermc.com")!) {
                    linked("WEB SİTESİ","Resmî BlasterMC portalı","globe")
                }
                Link(destination:URL(string:"https://discord.blastermc.com")!) {
                    linked("DISCORD","Topluluk sunucusu","person.3")
                }
                Button { news=true } label: {
                    linked("HABER MERKEZİ","Duyuruları ve etkinlikleri oku","megaphone.fill")
                }
            }
        }
    }

    private func command(_ value:String,_ title:String,_ subtitle:String) -> some View {
        Button {
            Forge.copy(value)
            copiedCommand=value
        } label: {
            HStack(spacing:13) {
                Text(value)
                    .font(.system(size:13,weight:.black,design:.monospaced))
                    .foregroundStyle(Forge.midnight)
                    .frame(width:86,alignment:.leading)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Rectangle().fill(Forge.stroke).frame(width:1,height:35)
                VStack(alignment:.leading,spacing:3) {
                    Text(title)
                        .font(.system(size:13,weight:.heavy))
                        .foregroundStyle(Forge.midnight)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(Forge.muted)
                        .lineLimit(2)
                }
                Spacer(minLength:1)
                Image(systemName:copiedCommand == value ? "checkmark.circle.fill" : "doc.on.doc")
                    .foregroundStyle(Forge.gold)
            }
            .padding(14)
            .background(Forge.white,in:ForgeCut(cut:11))
            .overlay(ForgeCut(cut:11).strokeBorder(Forge.stroke.opacity(0.65)))
        }
        .buttonStyle(BlasterTapStyle())
        .accessibilityHint("Minecraft komutunu kopyala")
    }

    private func linked(_ title:String,_ subtitle:String,_ icon:String)->some View {
        HStack(spacing:13) {
            Image(systemName:icon)
                .foregroundStyle(Forge.gold)
                .frame(width:32)
            VStack(alignment:.leading,spacing:4) {
                Text(title)
                    .font(.system(size:12,weight:.black,design:.monospaced))
                    .foregroundStyle(Forge.midnight)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Forge.muted)
            }
            Spacer()
            Image(systemName:"arrow.up.right")
                .foregroundStyle(Forge.gold)
        }
        .padding(15)
        .background(Forge.white,in:ForgeCut(cut:12))
        .overlay(ForgeCut(cut:12).strokeBorder(Forge.stroke.opacity(0.65)))
    }

    private var connection: some View {
        ForgeSurface(dark:true) {
            ForgeLabel(text:"READY TO PLAY",onDark:true)
            HStack {
                VStack(alignment:.leading,spacing:5) {
                    Text("oyna.blastermc.com")
                        .font(.system(size:16,weight:.black,design:.monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .foregroundStyle(.white)
                    Text("Minecraft Java • \(server.statusText)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer(minLength:4)
                Button {
                    Forge.copy("oyna.blastermc.com")
                    copiedCommand="ip"
                } label: {
                    Label(copiedCommand == "ip" ? "ALINDI" : "KOPYALA",
                          systemImage:copiedCommand == "ip" ? "checkmark" : "doc.on.doc")
                        .font(.system(size:10,weight:.black))
                        .foregroundStyle(Forge.midnight)
                        .padding(11)
                        .background(Forge.sun,in:ForgeCut(cut:8))
                }
                .buttonStyle(BlasterTapStyle())
            }
        }
    }
}

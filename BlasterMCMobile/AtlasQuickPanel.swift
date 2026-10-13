import SwiftUI

/// Player toolbox: real, local actions only. Commands are copied, never
/// represented as remote execution, and all links point to known Blaster URLs.
struct AtlasQuickPanel: View {
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var copied: String?
    private let commands: [(String, String, String)] = [
        ("/is", "Ada menüsü", "SkyBlock ada seçeneklerini aç"),
        ("/is home", "Adama dön", "Kendi SkyBlock adana ışınlan"),
        ("/is top", "Ada sıralaması", "En iyi adaları görüntüle"),
        ("/lobi", "Ana lobi", "BlasterMC ana lobisine dön")
    ]
    private var visible: [(String, String, String)] {
        commands.filter {
            search.isEmpty || $0.0.localizedStandardContains(search) ||
            $0.1.localizedStandardContains(search) ||
            $0.2.localizedStandardContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            AtlasScreen {
                AtlasBanner(eyebrow: "BLASTERMC / KOMUT MERKEZİ") {
                    Text("Her şey\nelinin altında.")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Sunucu IP'si, oyun komutları ve topluluk bağlantıları.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.91))
                        .fixedSize(horizontal: false, vertical: true)
                }
                AtlasHeading(kicker: "SUNUCU", title: "Bağlan")
                AtlasCard(tinted: true) {
                    Text("MINECRAFT ADRESİ")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Atlas.copper)
                    Text("oyna.blastermc.com")
                        .font(.system(size: 21, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Atlas.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    AtlasAction(title: copied == "ip" ? "Kopyalandı" : "Sunucu IP'sini kopyala",
                                symbol: copied == "ip" ? "checkmark" : "doc.on.doc") {
                        Atlas.copy("oyna.blastermc.com")
                        copied = "ip"
                    }
                }
                AtlasHeading(kicker: "OYUN İÇİ", title: "Komut kitaplığı",
                             detail: "Komuta dokun, oyunda sohbet kutusuna yapıştır.")
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Atlas.copper)
                    TextField("Komut ara", text: $search)
                        .font(.system(size: 14))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(14)
                .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Atlas.line))
                if visible.isEmpty {
                    AtlasEmpty(title: "Komut bulunamadı",
                               detail: "Farklı bir komut adıyla yeniden ara.",
                               symbol: "magnifyingglass")
                } else {
                    ForEach(visible.indices, id: \.self) { index in
                        let command = visible[index]
                        Button {
                            Atlas.copy(command.0)
                            copied = command.0
                        } label: {
                            AtlasCard(inset: 14) {
                                HStack(spacing: 12) {
                                    Image(systemName: "terminal.fill")
                                        .font(.system(size: 17))
                                        .foregroundStyle(Atlas.blue)
                                        .frame(width: 30)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(command.1)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(Atlas.ink)
                                        Text(command.2)
                                            .font(.system(size: 11))
                                            .foregroundStyle(Atlas.muted)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text(command.0)
                                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                            .foregroundStyle(Atlas.copper)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: copied == command.0 ? "checkmark" : "doc.on.doc")
                                        .foregroundStyle(Atlas.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                AtlasHeading(kicker: "TOPLULUK", title: "BlasterMC bağlantıları")
                HStack(spacing: 10) {
                    Link(destination: URL(string: "https://blastermc.com")!) {
                        Label("Web", systemImage: "globe")
                            .frame(maxWidth: .infinity, minHeight: 47)
                    }
                    Link(destination: URL(string: "https://discord.blastermc.com")!) {
                        Label("Discord", systemImage: "bubble.left.and.bubble.right")
                            .frame(maxWidth: .infinity, minHeight: 47)
                    }
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Atlas.blue)
                .background(Atlas.paper, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Atlas.line))
                Text("Komutlar yalnızca kopyalanır; oyun içinde çalışmaları sunucu yapılandırmasına bağlıdır.")
                    .font(.system(size: 11))
                    .foregroundStyle(Atlas.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .navigationTitle("Komut merkezi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(Atlas.blue)
                }
            }
        }
    }
}

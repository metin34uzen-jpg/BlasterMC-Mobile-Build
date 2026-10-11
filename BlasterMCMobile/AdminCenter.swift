import SwiftUI

struct ServiceHealth: Identifiable, Decodable {
    let key: String
    let label: String
    let state: String
    let detail: String
    var id: String { key }
}

struct PushStats: Decodable {
    let enabled: Bool
    let queued: Int
    let sent: Int
}

struct AdminHealth: Decodable {
    let checkedAt: String
    let services: [ServiceHealth]
    let push: PushStats
}

@MainActor
final class AdminCenterModel: ObservableObject {
    @Published var health: AdminHealth?
    @Published var isWorking = false
    @Published var error: String?
    @Published var result: String?

    func refresh(token: String?) async {
        guard let token else { error = "Yönetici oturumu bulunamadı"; return }
        isWorking = true
        defer { isWorking = false }
        do {
            let response: AdminHealth = try await AppAPI().fetch("admin/health", token: token)
            health = response
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func send(token: String?, title: String, body: String) async {
        guard let token else { error = "Yetkili oturum bulunamadı"; return }
        guard (3...90).contains(title.count), (5...500).contains(body.count) else {
            error = "Başlık 3–90, mesaj 5–500 karakter olmalı."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            let payload = try JSONSerialization.data(withJSONObject: [
                "title": title, "body": body, "audience": "all"
            ])
            let response: PushSendResult = try await AppAPI().send(
                "admin/push/send", method: "POST", token: token, body: payload
            )
            result = response.message
            error = nil
            await refresh(token: token)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct PushSendResult: Decodable {
    let message: String
}

struct AdminCenterView: View {
    @EnvironmentObject private var session: BlasterSession
    @StateObject private var model = AdminCenterModel()
    @StateObject private var push = PushCoordinator.shared
    @FocusState private var focusedField: EditorField?
    private enum EditorField: Hashable { case title, body }
    @State private var title = ""
    @State private var message = ""
    @State private var confirm = false
    @State private var pulse = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                banner
                SectionHeader(title: "Sistem sağlığı", caption: "Yalnızca doğrulanabilen canlı veriler")
                if let health = model.health {
                    ForEach(health.services) { item in
                        healthCard(item)
                    }
                    pushOverview(health.push)
                } else {
                    NoticePlaceholder(symbol: "waveform.path.ecg",
                                      title: "Durum bilgisi bekleniyor",
                                      message: model.error ?? "Yönetici API'sinden canlı durum sorgulanıyor.")
                }
                GoldButton(title: model.isWorking ? "Kontrol ediliyor" : "Tüm servisleri yenile",
                           symbol: "arrow.clockwise") {
                    Task { await model.refresh(token: session.bearerToken) }
                }
                .disabled(model.isWorking)
                SectionHeader(title: "Toplu bildirim", caption: "Kayıtlı BlasterMC cihazlarına gönder")
                composer
                localTest
                if let error = model.error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if let result = model.result {
                    Label(result, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.ink)
                }
            }
            .padding(18)
        }
        .background {
            PremiumBackground()
                .onTapGesture { focusedField = nil }
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Bitti") { focusedField = nil }
                    .fontWeight(.semibold)
            }
        }
        .navigationTitle("Yönetici Merkezi")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Refresh every 30 seconds while the administrator screen remains visible.
            while !Task.isCancelled {
                await model.refresh(token: session.bearerToken)
                do { try await Task.sleep(for: .seconds(30)) }
                catch { break }
            }
        }
        .refreshable { await model.refresh(token: session.bearerToken) }
        .alert("Bildirim gönderilsin mi?", isPresented: $confirm) {
            Button("Vazgeç", role: .cancel) {}
            Button("Gönder") {
                Task {
                    await model.send(token: session.bearerToken, title: title, body: message)
                    if model.error == nil { title = ""; message = "" }
                }
            }
        } message: {
            Text("Bu bildirim sunucudaki kayıtlı cihazların tamamı için gönderim kuyruğuna alınacak.")
        }
    }

    private var banner: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [
                    BlasterTheme.navy,
                    Color(red: 0.26, green: 0.25, blue: 0.30),
                    BlasterTheme.copper
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
            SkyWorldView()
                .opacity(0.40)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            HStack(spacing: 17) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(BlasterTheme.amber)
                    .scaleEffect(pulse ? 1.09 : 0.94)
                    .frame(width: 61, height: 65)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 17))
                VStack(alignment: .leading, spacing: 8) {
                    Text("YÖNETİM MERKEZİ")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.6)
                        .foregroundStyle(BlasterTheme.amber)
                    Text("BLASTER CONTROL")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .tracking(-0.6)
                        .foregroundStyle(.white)
                    Text("Minecraft • Web • Discord")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 0)
            }
            .padding(21)
        }
        .frame(minHeight: 155)
        .overlay(RoundedRectangle(cornerRadius: 28)
            .strokeBorder(BlasterTheme.amber.opacity(0.34), lineWidth: 1))
        .shadow(color: BlasterTheme.navy.opacity(0.19), radius: 20, y: 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private func healthCard(_ item: ServiceHealth) -> some View {
        BlasterCard {
            HStack(spacing: 15) {
                Image(systemName: symbol(item.key))
                    .font(.title3)
                    .foregroundStyle(BlasterTheme.gold)
                    .frame(width: 45, height: 45)
                    .background(BlasterTheme.cream, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.label).font(.headline)
                    Text(item.detail).font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                }
                Spacer()
                Text(stateTitle(item.state))
                    .font(.caption2.weight(.black))
                    .tracking(0.6)
                    .foregroundStyle(statusColor(item.state))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(statusColor(item.state).opacity(0.11), in: Capsule())
            }
        }
    }

    private func symbol(_ key: String) -> String {
        switch key {
        case "minecraft": return "gamecontroller.fill"
        case "website": return "globe.americas.fill"
        case "discord": return "bubble.left.and.bubble.right.fill"
        default: return "server.rack"
        }
    }

    private func stateTitle(_ state: String) -> String {
        switch state {
        case "online": return "AKTİF"
        case "offline": return "KAPALI"
        default: return "BELİRSİZ"
        }
    }

    private func statusColor(_ state: String) -> Color {
        switch state {
        case "online": return .green
        case "offline": return .red
        default: return .orange
        }
    }

    private func pushOverview(_ stats: PushStats) -> some View {
        BlasterCard {
            Label("APNs gönderim servisi", systemImage: "paperplane.fill")
                .font(.headline)
            Text(stats.enabled ? "Uzaktan APNs gönderimi yapılandırılmış" :
                 "Uzaktan APNs gönderimi etkin değil. iPhone'daki yerel test bildirimi bundan bağımsız çalışır.")
                .font(.caption)
                .foregroundStyle(BlasterTheme.muted)
            HStack {
                Text("Kuyruk: \(stats.queued)")
                Spacer()
                Text("Gönderilen: \(stats.sent)")
            }
            .font(.caption.bold())
            .foregroundStyle(BlasterTheme.gold)
        }
    }

    private var composer: some View {
        BlasterCard {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Bildirim başlığı", text: $title)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .body }
                    .textInputAutocapitalization(.sentences)
                    .padding(12)
                    .background(BlasterTheme.canvas, in: RoundedRectangle(cornerRadius: 12))
                TextField("Bildirim mesajı", text: $message, axis: .vertical)
                    .focused($focusedField, equals: .body)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(BlasterTheme.canvas, in: RoundedRectangle(cornerRadius: 12))
                HStack {
                    Text("Toplu duyuru • Önce onay ister")
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                    Spacer()
                    Button("Klavyeyi kapat") { focusedField = nil }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BlasterTheme.gold)
                }
                GoldButton(title: "Bildirimi sıraya al", symbol: "paperplane.fill") {
                    focusedField = nil
                    Task {
                        try? await Task.sleep(for: .milliseconds(220))
                        confirm = true
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).count < 3 ||
                          message.trimmingCharacters(in: .whitespaces).count < 5 ||
                          model.isWorking || model.health?.push.enabled != true)
            }
        }
    }
    private var localTest: some View {
        BlasterCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "bell.and.waves.left.and.right.fill")
                        .font(.title3)
                        .foregroundStyle(BlasterTheme.gold)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("iPhone Bildirim Testi")
                            .font(.headline)
                        Text("3 saniye sonra yerel test • Ücretsiz Apple hesabında çalışabilir")
                            .font(.caption)
                            .foregroundStyle(BlasterTheme.muted)
                    }
                }
                Text(push.permissionDescription)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(push.permissionGranted ? Color.green : .orange)
                GoldButton(title: "3 SANİYE SONRA TEST BİLDİRİMİ",
                           symbol: "bell.badge.fill") {
                    focusedField = nil
                    Task { await push.scheduleLocalTest() }
                }
                if let result = push.localTestResult {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(BlasterTheme.muted)
                }
                Divider()
                Text("Bu test APNs kullanmaz; uygulama kapalıyken veya açıkken iOS yerel bildiriminin çalışmasını sınar. Uzaktan toplu gönderim ayrı APNs yetkisi gerektirir.")
                    .font(.caption2)
                    .foregroundStyle(BlasterTheme.muted)
            }
        }
    }

}

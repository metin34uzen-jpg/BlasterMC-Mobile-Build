import SwiftUI

/// Administrator UI is hidden from members, checked again at entry, and all
/// privileged requests go through the server's authenticated admin endpoints.
struct AtlasAdminView: View {
    @EnvironmentObject private var session: BlasterSession
    @StateObject private var model = AdminCenterModel()
    @StateObject private var push = PushCoordinator.shared
    @State private var title = ""
    @State private var message = ""
    @State private var confirmSend = false
    @FocusState private var field: Input?
    private enum Input: Hashable { case title, message }

    var body: some View {
        Group {
            if session.isAdministrator {
                authorized
            } else {
                AtlasEmpty(title: "Yetkili erişim gerekli",
                           detail: "Bu ekran yalnızca sunucu tarafından yönetici olarak doğrulanan hesaplarda açılır.",
                           symbol: "lock.shield")
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AtlasBackground())
            }
        }
        .navigationTitle("Blaster Control")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var authorized: some View {
        AtlasScreen {
            AtlasBanner(eyebrow: "BLASTER CONTROL / REALM") {
                Text("Kontrol\nodası.")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Servislerin, bildirimlerin ve BlasterMC operasyonlarının tek merkezi.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.89))
                    .fixedSize(horizontal: false, vertical: true)
            }
            health
            notifications
            compose
            if let error = model.error {
                AtlasEmpty(title: "İşlem tamamlanamadı", detail: error,
                           symbol: "exclamationmark.triangle.fill")
            }
            if let result = model.result {
                AtlasCard(tinted: true) {
                    Label(result, systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Atlas.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Bitti") { field = nil }
            }
        }
        .sheet(isPresented: $push.showSettingsPrompt) {
            NotificationSettingsPrompt(push: push)
        }
        .task {
            guard session.isAdministrator else { return }
            while !Task.isCancelled && session.isAdministrator {
                await model.refresh(token: session.bearerToken)
                await push.refreshPermissionStatus()
                do { try await Task.sleep(for: .seconds(30)) }
                catch { break }
            }
        }
        .refreshable {
            guard session.isAdministrator else { return }
            await model.refresh(token: session.bearerToken)
            await push.refreshPermissionStatus()
        }
        .alert("Toplu bildirim gönderilsin mi?", isPresented: $confirmSend) {
            Button("Vazgeç", role: .cancel) {}
            Button("Gönder") {
                guard session.isAdministrator, model.health?.push.enabled == true else { return }
                Task {
                    await model.send(token: session.bearerToken,
                                     title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                     body: message.trimmingCharacters(in: .whitespacesAndNewlines))
                    if model.error == nil {
                        title = ""
                        message = ""
                    }
                }
            }
        } message: {
            Text("Bu bildirim, sunucunun izin verdiği kayıtlı cihazlar için gönderim kuyruğuna alınır.")
        }
    }

    private var health: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "01 / SERVİSLER", title: "Sistem sağlığı",
                         detail: "Yalnızca yönetim API'sinden gelen durumlar")
            if let health = model.health {
                ForEach(health.services) { service in
                    AtlasCard(inset: 14) {
                        HStack(alignment: .top, spacing: 11) {
                            Image(systemName: icon(service.key))
                                .font(.system(size: 20))
                                .foregroundStyle(Atlas.copper)
                                .frame(width: 29)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(service.label)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Atlas.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(service.detail)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Atlas.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .trailing, spacing: 5) {
                                Circle()
                                    .fill(service.state == "online" ? Color.green :
                                          service.state == "offline" ? Color.red : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text(service.state == "online" ? "Aktif" :
                                     service.state == "offline" ? "Kapalı" : "Belirsiz")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Atlas.muted)
                            }
                        }
                    }
                }
            } else {
                AtlasEmpty(title: "Servis bilgisi bekleniyor",
                           detail: model.error ?? "Yönetim API'sine bağlanılıyor.",
                           symbol: "waveform.path.ecg")
            }
            AtlasAction(title: model.isWorking ? "Kontrol ediliyor…" : "Servisleri yenile",
                        symbol: "arrow.clockwise", secondary: true) {
                Task { await model.refresh(token: session.bearerToken) }
            }
            .disabled(model.isWorking)
        }
    }

    private func icon(_ key: String) -> String {
        switch key {
        case "minecraft": return "gamecontroller.fill"
        case "website": return "globe"
        case "discord": return "bubble.left.and.bubble.right.fill"
        default: return "server.rack"
        }
    }

    private var notifications: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "02 / YETKİLİ AYARLARI", title: "Bildirim merkezi",
                         detail: "Haberler ekranında bildirim yönetimi bulunmaz.")
            AtlasCard {
                Label("iPhone bildirim izinleri", systemImage: "bell.badge.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Atlas.ink)
                Text(push.permissionDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(Atlas.muted)
                    .fixedSize(horizontal: false, vertical: true)
                AtlasRule()
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(Atlas.copper)
                    Text(push.deviceToken == nil ?
                         "APNs cihaz belirteci yok. Ücretsiz AltStore imzası uzaktan bildirim yetkisi içermeyebilir." :
                         "APNs cihaz belirteci alındı. Sunucu tarafı teslimat ayrıca yapılandırılmalıdır.")
                        .font(.system(size: 12))
                        .foregroundStyle(Atlas.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let stats = model.health?.push {
                    AtlasRule()
                    Label(stats.enabled ? "APNs sunucusu etkin" : "APNs sunucusu etkin değil",
                          systemImage: stats.enabled ? "checkmark.circle" : "exclamationmark.circle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Atlas.ink)
                    Text("Kuyruk: \(stats.queued)   •   Gönderilen: \(stats.sent)")
                        .font(.system(size: 12))
                        .foregroundStyle(Atlas.muted)
                }
                AtlasAction(title: "iPhone bildirim ayarlarını aç",
                            symbol: "gearshape", secondary: true) {
                    push.openSystemSettings()
                }
                AtlasAction(title: "Yerel test bildirimi gönder", symbol: "bell.fill") {
                    Task { await push.scheduleLocalTest() }
                }
                if let result = push.localTestResult {
                    Text(result)
                        .font(.system(size: 12))
                        .foregroundStyle(Atlas.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var compose: some View {
        VStack(alignment: .leading, spacing: 11) {
            AtlasHeading(kicker: "03 / TOPLU DUYURU", title: "Bildirim gönder",
                         detail: "Sunucu etkin değilse gönderim kapalı kalır.")
            AtlasCard {
                TextField("Bildirim başlığı", text: $title)
                    .focused($field, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { field = .message }
                    .font(.system(size: 14))
                    .foregroundStyle(Atlas.ink)
                    .padding(13)
                    .background(Atlas.canvas, in: RoundedRectangle(cornerRadius: 11))
                TextField("Bildirim mesajı", text: $message, axis: .vertical)
                    .focused($field, equals: .message)
                    .lineLimit(3...6)
                    .font(.system(size: 14))
                    .foregroundStyle(Atlas.ink)
                    .padding(13)
                    .background(Atlas.canvas, in: RoundedRectangle(cornerRadius: 11))
                AtlasAction(title: "Gönderimi onayla", symbol: "paperplane.fill") {
                    field = nil
                    confirmSend = true
                }
                .disabled(!session.isAdministrator ||
                          model.health?.push.enabled != true ||
                          model.isWorking ||
                          !(3...90).contains(title.trimmingCharacters(in: .whitespacesAndNewlines).count) ||
                          !(5...500).contains(message.trimmingCharacters(in: .whitespacesAndNewlines).count))
            }
        }
    }
}

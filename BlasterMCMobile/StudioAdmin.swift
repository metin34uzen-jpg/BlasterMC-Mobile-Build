import SwiftUI

/// Server-validated administrator control room. Ordinary members cannot open its UI.
struct StudioAdminCenterView:View {
    @EnvironmentObject private var session:BlasterSession
    @StateObject private var model=AdminCenterModel()
    @StateObject private var push=PushCoordinator.shared
    @FocusState private var focused:Field?
    @State private var title=""
    @State private var message=""
    @State private var confirm=false
    private enum Field:Hashable {case title,message}

    var body:some View {
        Group {
            if session.isAdministrator {
                adminContents
            } else {
                StudioEmpty(title:"Yönetici erişimi gerekli",
                            detail:"Bu bölüm yalnızca sunucu tarafından doğrulanan yöneticiler için açıktır.",
                            symbol:"lock.shield")
                    .padding(20)
                    .frame(maxWidth:.infinity,maxHeight:.infinity)
                    .background(StudioBackground())
            }
        }
        .navigationTitle("Yönetim Merkezi")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var adminContents:some View {
        ScrollView(showsIndicators:false) {
            VStack(alignment:.leading,spacing:19) {
                StudioSection(kicker:"YETKİLİ / BLASTERMC",title:"Kontrol merkezi")
                StudioHero(symbol:"shield.lefthalf.filled",height:152) {
                    VStack(alignment:.leading,spacing:8) {
                        Text("BLASTER CONTROL")
                            .font(.system(size:10,weight:.heavy,design:.monospaced))
                            .foregroundStyle(Studio.sunlight)
                        Text("Sistemler kontrol altında.")
                            .font(.system(size:23,weight:.bold,design:.rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal:false,vertical:true)
                        Text("Minecraft · Web · Discord · Bildirim")
                            .font(.system(size:11))
                            .foregroundStyle(.white.opacity(0.79))
                    }
                }
                statusSection
                notificationSection
                composerSection
                if let error=model.error {
                    StudioEmpty(title:"İşlem tamamlanamadı",
                                detail:error,symbol:"exclamationmark.triangle.fill")
                }
                if let result=model.result {
                    StudioPanel {
                        Label(result,systemImage:"checkmark.circle.fill")
                            .font(.system(size:12,weight:.semibold))
                            .foregroundStyle(Studio.ink)
                    }
                }
            }
            .padding(.horizontal,18)
            .padding(.top,18)
            .padding(.bottom,30)
            .frame(maxWidth:620)
            .frame(maxWidth:.infinity)
        }
        .background(StudioBackground())
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement:.keyboard) {
                Spacer()
                Button("Bitti") { focused=nil }
            }
        }
        .sheet(isPresented:$push.showSettingsPrompt) {
            NotificationSettingsPrompt(push:push)
        }
        .task {
            guard session.isAdministrator else { return }
            while !Task.isCancelled && session.isAdministrator {
                await model.refresh(token:session.bearerToken)
                await push.refreshPermissionStatus()
                do { try await Task.sleep(for:.seconds(30)) }
                catch { break }
            }
        }
        .refreshable {
            guard session.isAdministrator else { return }
            await model.refresh(token:session.bearerToken)
            await push.refreshPermissionStatus()
        }
        .alert("Toplu bildirim gönderilsin mi?",isPresented:$confirm) {
            Button("Vazgeç",role:.cancel){}
            Button("Gönder") {
                guard session.isAdministrator else { return }
                Task {
                    await model.send(token:session.bearerToken,
                                     title:title.trimmingCharacters(in:.whitespacesAndNewlines),
                                     body:message.trimmingCharacters(in:.whitespacesAndNewlines))
                    if model.error == nil { title="";message="" }
                }
            }
        } message: {
            Text("Bu işlem sunucunun izin verdiği kayıtlı cihazlara gönderim kuyruğu oluşturur.")
        }
    }

    private var statusSection:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"SİSTEM / KONTROL",title:"Servis sağlığı")
            if let health=model.health {
                ForEach(health.services) { entry in
                    StudioPanel(padding:14) {
                        HStack(alignment:.top,spacing:12) {
                            Image(systemName:entry.key=="minecraft" ? "gamecontroller" :
                                  entry.key=="website" ? "globe" :
                                  entry.key=="discord" ? "bubble.left.and.bubble.right" : "server.rack")
                                .font(.system(size:20))
                                .foregroundStyle(Studio.gold)
                                .frame(width:30)
                            VStack(alignment:.leading,spacing:5) {
                                Text(entry.label)
                                    .font(.system(size:14,weight:.semibold))
                                    .foregroundStyle(Studio.ink)
                                    .fixedSize(horizontal:false,vertical:true)
                                Text(entry.detail)
                                    .font(.system(size:12))
                                    .foregroundStyle(Studio.secondary)
                                    .fixedSize(horizontal:false,vertical:true)
                            }
                            .frame(maxWidth:.infinity,alignment:.leading)
                            VStack(alignment:.trailing,spacing:4) {
                                Circle().fill(entry.state=="online" ? Color.green :
                                              entry.state=="offline" ? Color.red : Color.orange)
                                    .frame(width:9,height:9)
                                Text(entry.state=="online" ? "Aktif" :
                                     entry.state=="offline" ? "Kapalı" : "Belirsiz")
                                    .font(.system(size:10,weight:.semibold))
                                    .foregroundStyle(Studio.secondary)
                            }
                        }
                    }
                }
            } else {
                StudioEmpty(title:"Servis bilgisi bekleniyor",
                            detail:model.error ?? "Yönetim API'sinden güncel bilgiler alınıyor.",
                            symbol:"waveform.path.ecg")
            }
            StudioCTA(title:model.isWorking ? "Kontrol ediliyor…" : "Servisleri yenile",
                      symbol:"arrow.clockwise",subtle:true) {
                Task { await model.refresh(token:session.bearerToken) }
            }
            .disabled(model.isWorking)
        }
    }

    private var notificationSection:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"YÖNETİCİ / BİLDİRİM",title:"Bildirim ayarları",
                          accessory:"Sadece yönetici")
            StudioPanel {
                Label("iPhone izin durumu",systemImage:"bell.badge")
                    .font(.system(size:13,weight:.semibold))
                    .foregroundStyle(Studio.ink)
                Text(push.permissionDescription)
                    .font(.system(size:12))
                    .foregroundStyle(Studio.secondary)
                    .fixedSize(horizontal:false,vertical:true)
                Divider()
                HStack(alignment:.top,spacing:9) {
                    Image(systemName:"antenna.radiowaves.left.and.right")
                        .foregroundStyle(Studio.gold)
                    Text(push.deviceToken == nil ?
                         "APNs cihaz kaydı bulunamadı. Ücretsiz AltStore imzası uzaktan push yetkisi sağlamayabilir." :
                         "APNs cihaz belirteci alındı. Sunucu tarafı teslimat ayrıca yapılandırılmalıdır.")
                        .font(.system(size:12))
                        .foregroundStyle(Studio.secondary)
                        .fixedSize(horizontal:false,vertical:true)
                }
                if let stats=model.health?.push {
                    Divider()
                    Text(stats.enabled ? "Uzaktan bildirim sunucusu etkin" :
                         "Uzaktan bildirim sunucusu etkin değil")
                        .font(.system(size:12,weight:.semibold))
                        .foregroundStyle(Studio.ink)
                    HStack(spacing:14) {
                        Text("Kuyruk: \(stats.queued)")
                        Text("Gönderilen: \(stats.sent)")
                    }
                    .font(.system(size:11))
                    .foregroundStyle(Studio.gold)
                }
                HStack(spacing:10) {
                    StudioCTA(title:"iOS ayarlarını aç",symbol:"gearshape",subtle:true) {
                        push.openSystemSettings()
                    }
                    StudioCTA(title:"Test bildirimi",symbol:"bell") {
                        Task { await push.scheduleLocalTest() }
                    }
                }
                if let notice=push.localTestResult {
                    Text(notice)
                        .font(.system(size:11))
                        .foregroundStyle(Studio.secondary)
                        .fixedSize(horizontal:false,vertical:true)
                }
            }
        }
    }

    private var composerSection:some View {
        VStack(alignment:.leading,spacing:11) {
            StudioSection(kicker:"YÖNETİCİ / TOPLU GÖNDERİM",title:"Duyuru oluştur")
            StudioPanel {
                Text("Bu işlem yalnızca APNs sunucusu etkin olduğunda kullanılabilir.")
                    .font(.system(size:12))
                    .foregroundStyle(Studio.secondary)
                    .fixedSize(horizontal:false,vertical:true)
                TextField("Bildirim başlığı",text:$title)
                    .focused($focused,equals:.title)
                    .submitLabel(.next)
                    .onSubmit { focused = .message }
                    .font(.subheadline)
                    .padding(13)
                    .background(Studio.background,in:RoundedRectangle(cornerRadius:10))
                TextField("Mesaj",text:$message,axis:.vertical)
                    .focused($focused,equals:.message)
                    .lineLimit(3...5)
                    .font(.subheadline)
                    .padding(13)
                    .background(Studio.background,in:RoundedRectangle(cornerRadius:10))
                StudioCTA(title:"Gönderimi onayla",symbol:"paperplane.fill") {
                    focused=nil
                    confirm=true
                }
                .disabled(title.trimmingCharacters(in:.whitespacesAndNewlines).count<3 ||
                          message.trimmingCharacters(in:.whitespacesAndNewlines).count<5 ||
                          model.isWorking || model.health?.push.enabled != true ||
                          !session.isAdministrator)
            }
        }
    }
}

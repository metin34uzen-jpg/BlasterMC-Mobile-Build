import Foundation
import UIKit
import UserNotifications
import Combine

@MainActor
final class PushCoordinator: ObservableObject {
    static let shared = PushCoordinator()

    @Published private(set) var deviceToken: String?
    @Published private(set) var statusMessage = ""
    @Published private(set) var permissionGranted = false
    @Published private(set) var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var localTestResult: String?
    @Published var showSettingsPrompt = false

    private init() {}

    var permissionDescription: String {
        switch permissionStatus {
        case .authorized: return "iPhone bildirim izni açık"
        case .provisional: return "Sessiz bildirim izni açık"
        case .ephemeral: return "Geçici bildirim izni açık"
        case .denied: return "Bildirim izni iOS Ayarlar'da kapalı"
        default: return "Bildirim izni henüz sorulmadı"
        }
    }

    func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = settings.authorizationStatus
        permissionGranted = settings.authorizationStatus == .authorized ||
            settings.authorizationStatus == .provisional ||
            settings.authorizationStatus == .ephemeral
    }

    // iOS only shows the system Allow/Don't Allow alert once; no artificial retries.
    func requestOnLaunch() async {
        await refreshPermissionStatus()
        if permissionStatus == .notDetermined {
            do {
                _ = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                statusMessage = "Bildirim izni istenemedi."
            }
            await refreshPermissionStatus()
        }
        if permissionGranted {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func checkAfterLogin() async {
        await refreshPermissionStatus()
        if permissionStatus == .denied {
            showSettingsPrompt = true
        }
    }

    func openSystemSettings() {
        showSettingsPrompt = false
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// Only tests LOCAL delivery after three seconds, not remote APNs.
    func scheduleLocalTest() async {
        localTestResult = nil
        await refreshPermissionStatus()
        guard permissionGranted else {
            localTestResult = "Bildirimler kapalı. Ayarlar üzerinden izin ver."
            if permissionStatus == .denied { showSettingsPrompt = true }
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "BlasterMC • Test başarılı mı?"
        content.body = "Bu bildirim 3 saniye önce uygulamada planlandı. Bu yerel bir testtir; APNs değildir."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
            localTestResult = "Yerel test bildirimi 3 saniye sonrası için planlandı."
        } catch {
            localTestResult = "Yerel test planlanamadı: \(error.localizedDescription)"
        }
    }

    func received(token: Data) {
        deviceToken = token.map { String(format: "%02x", $0) }.joined()
        statusMessage = "APNs cihaz kaydı başarılı"
    }

    func registrationFailed(_ error: Error) {
        statusMessage = "APNs cihaz kaydı yok (mevcut imza Push yetkisi taşımıyor olabilir)."
    }
}

final class BlasterAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken token: Data) {
        Task { @MainActor in PushCoordinator.shared.received(token: token) }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in PushCoordinator.shared.registrationFailed(error) }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}

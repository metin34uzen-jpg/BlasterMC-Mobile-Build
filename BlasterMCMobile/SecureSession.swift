import Foundation
import Combine
import Security

enum SecureToken {
    private static let service = "com.blastermc.mobile.session"
    private static let account = "access_token"

    static func store(_ value: String) -> Bool {
        clear()
        guard let data = value.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func clear() {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ] as CFDictionary)
    }
}

@MainActor
final class BlasterSession: ObservableObject {
    @Published private(set) var profile: PlayerProfile?
    @Published private(set) var isBusy = false
    @Published private(set) var mfaChallenge: String?
    @Published var error: String?
    @Published private(set) var products: [StoreProduct] = []
    @Published private(set) var season: SeasonData?
    @Published private(set) var announcements: [MobileNotice] = []
    @Published private(set) var events: [MobileNotice] = []
    @Published private(set) var dataError: String?

    @Published private(set) var loggedInAt: Date?
    private static let loginKey = "blaster.mobile.login_at"
    var bearerToken: String? { isSignedIn ? token : nil }
    var isAdministrator: Bool { isSignedIn && profile?.isAdmin == true }

    private let api = AppAPI()
    private var token: String? = SecureToken.read()

    var isSignedIn: Bool { profile != nil && token != nil }

    func restore() async {
        if token != nil {
            // Upgrade from v2: begin a new 15-minute window on the first v3 launch.
            if UserDefaults.standard.object(forKey: Self.loginKey) == nil {
                UserDefaults.standard.set(Date(), forKey: Self.loginKey)
            }
            loggedInAt = UserDefaults.standard.object(forKey: Self.loginKey) as? Date
            if expireIfNeeded() { await reloadPublic(); return }
            await reloadProfile()
        }
        await reloadPublic()
    }

    @discardableResult
    func expireIfNeeded() -> Bool {
        guard token != nil else { return false }
        guard let time = loggedInAt ?? UserDefaults.standard.object(forKey: Self.loginKey) as? Date,
              time.timeIntervalSinceNow > -900, time.timeIntervalSinceNow <= 0 else {
            signOut()
            return true
        }
        return false
    }

    func registerPushToken(_ value: String) async {
        guard let token = bearerToken, !value.isEmpty else { return }
        do {
            let body = try JSONSerialization.data(withJSONObject: [
                "device_token": value,
                "platform": "ios"
            ])
            let _: ResponseMessage = try await api.send(
                "devices/register", method: "POST", token: token, body: body
            )
        } catch {
            // Permission and account use remain usable if APNs has not been provisioned.
        }
    }

    func signIn(username: String, password: String) async {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            error = "Kullanıcı adı ve şifre gir."
            return
        }
        isBusy = true
        error = nil
        defer { isBusy = false }
        do {
            let result = try await api.login(username: username, password: password)
            if result.mfaRequired == true, let challenge = result.challengeToken {
                mfaChallenge = challenge
                return
            }
            try acceptSession(result)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func acceptSession(_ result: LoginResult) throws {
        guard let accessToken = result.accessToken, !accessToken.isEmpty,
              let profile = result.profile, SecureToken.store(accessToken) else {
            throw APIProblem.invalidData
        }
        mfaChallenge = nil
        token = accessToken
        loggedInAt = Date()
        UserDefaults.standard.set(loggedInAt, forKey: Self.loginKey)
        self.profile = profile
        if let deviceToken = PushCoordinator.shared.deviceToken {
            Task { await self.registerPushToken(deviceToken) }
        }
    }

    func verifyMFA(code: String) async {
        guard let challenge = mfaChallenge else { return }
        isBusy = true
        error = nil
        defer { isBusy = false }
        do { try acceptSession(await api.verifyMFA(challenge: challenge, code: code)) }
        catch { self.error = error.localizedDescription }
    }

    func reloadProfile() async {
        guard let token else { return }
        do {
            let value: PlayerProfile = try await api.fetch("profile", token: token)
            profile = value
            error = nil
            if let deviceToken = PushCoordinator.shared.deviceToken {
                await registerPushToken(deviceToken)
            }
        } catch APIProblem.unauthorized {
            signOut()
            error = APIProblem.unauthorized.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    // Independent loads: a store/catalog outage must never blank the season.
    func reloadPublic() async {
        var failures: [String] = []
        do {
            let catalog: [StoreProduct] = try await api.fetch("store/products")
            products = catalog
        } catch { failures.append("Mağaza: " + error.localizedDescription) }

        do {
            let value: SeasonData = try await api.fetch("season")
            season = value
        } catch { failures.append("Sezon: " + error.localizedDescription) }

        do {
            let content: PublicContent = try await api.fetch("content")
            announcements = content.announcements
            events = content.events
        } catch { failures.append("Haberler: " + error.localizedDescription) }

        dataError = failures.isEmpty ? nil : failures.joined(separator: " • ")
    }

    func reloadSeason() async {
        do {
            let value: SeasonData = try await api.fetch("season")
            season = value
            dataError = nil
        } catch {
            dataError = "Sezon verisi alınamadı: " + error.localizedDescription
        }
    }

    func signOut() {
        // Revoke remote token best-effort; do not leave a local session on network failure.
        let old = token
        if let old { Task { try? await api.logout(token: old) } }
        SecureToken.clear()
        token = nil
        profile = nil
        mfaChallenge = nil
        loggedInAt = nil
        UserDefaults.standard.removeObject(forKey: Self.loginKey)
        error = nil
    }
}

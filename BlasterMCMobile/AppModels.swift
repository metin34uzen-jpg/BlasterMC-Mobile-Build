import Foundation

// The site must implement this versioned contract before authenticated
// BlasterMC content can be retrieved. No demo balances or fabricated ranks.
enum MobileAPI {
    static let root = URL(string: "https://blastermc.com/api/mobile/v1/")!
}

struct PlayerProfile: Decodable {
    let blasterId: String
    let username: String
    let minecraftName: String
    let rank: String
    let credits: Int
    let skinUrl: URL?
    let inGame: Bool?
    let onSite: Bool?
    let isAdmin: Bool?
}

struct LoginResult: Decodable {
    let mfaRequired: Bool?
    let challengeToken: String?
    let accessToken: String?
    let profile: PlayerProfile?
}

struct StoreProduct: Identifiable, Decodable {
    let id: Int
    let name: String
    let description: String
    let priceCredits: Int?
    let category: String
    let imageUrl: URL?
}

struct SeasonData: Decodable {
    let title: String
    let subtitle: String?
    let endsAt: Date?
    let rewards: [SeasonReward]
    let endsAtLabel: String?
    let updatedAt: Date?
    let rankings: [SeasonRanking]?
    let milestones: [SeasonMilestone]?
}

struct SeasonRanking: Identifiable, Decodable {
    let rankPosition: Int
    let islandName: String
    let ownerUsername: String
    let islandValue: Int
    let previousRank: Int?
    var id: Int { rankPosition }
}

struct SeasonMilestone: Identifiable, Decodable {
    let title: String
    let date: String?
    var id: String { title }
}

struct SeasonReward: Identifiable, Decodable {
    let id: Int
    let title: String
    let description: String
    let isClaimed: Bool?
}

struct MobileNotice: Identifiable, Decodable {
    let id: Int
    let title: String
    let body: String
    let createdAt: Date
    let category: String
}

struct PublicContent: Decodable {
    let announcements: [MobileNotice]
    let events: [MobileNotice]
}

struct ResponseMessage: Decodable {
    let message: String?
}

enum APIProblem: LocalizedError {
    case unconfigured
    case unauthorized
    case http(Int)
    case invalidData
    var errorDescription: String? {
        switch self {
        case .unconfigured: return "Mobil API henüz web sunucusunda etkin değil."
        case .unauthorized: return "Oturum süresi doldu. Tekrar giriş yap."
        case .http(let status): return "Sunucu isteği tamamlayamadı (HTTP \(status))."
        case .invalidData: return "Sunucunun veri biçimi beklenenden farklı."
        }
    }
}

struct AppAPI {
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func fetch<T: Decodable>(_ endpoint: String, token: String? = nil) async throws -> T {
        try await send(endpoint, method: "GET", token: token, body: nil)
    }

    func send<T: Decodable>(_ endpoint: String, method: String, token: String? = nil, body: Data?) async throws -> T {
        guard let url = URL(string: endpoint, relativeTo: MobileAPI.root)?.absoluteURL,
              url.scheme == "https", url.host == MobileAPI.root.host else {
            throw APIProblem.invalidData
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIProblem.invalidData }
        if http.statusCode == 404 || http.statusCode == 501 { throw APIProblem.unconfigured }
        if http.statusCode == 401 { throw APIProblem.unauthorized }
        guard (200...299).contains(http.statusCode) else { throw APIProblem.http(http.statusCode) }
        do { return try decoder.decode(T.self, from: data) }
        catch { throw APIProblem.invalidData }
    }

    func verifyMFA(challenge: String, code: String) async throws -> LoginResult {
        let body = try JSONSerialization.data(withJSONObject: ["challenge_token": challenge, "code": code])
        return try await send("auth/verify-mfa", method: "POST", body: body)
    }

    func logout(token: String) async throws {
        let _: ResponseMessage = try await send("auth/logout", method: "POST", token: token, body: Data("{}".utf8))
    }

    func login(username: String, password: String) async throws -> LoginResult {
        let body = try JSONSerialization.data(withJSONObject: [
            "username": username,
            "password": password
        ])
        return try await send("auth/login", method: "POST", body: body)
    }
}

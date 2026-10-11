import Foundation
import Combine

@MainActor
final class ServerStatusModel: ObservableObject {
    @Published private(set) var isOnline = false
    @Published private(set) var onlinePlayers = 0
    @Published private(set) var maxPlayers = 0
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastSuccess: Date?
    @Published private(set) var failedChecks = 0
    @Published private(set) var sourceName = ""

    var hasConfirmedStatus: Bool { lastSuccess != nil }
    var isStale: Bool {
        guard let lastSuccess else { return true }
        return Date().timeIntervalSince(lastSuccess) > 60
    }
    var statusText: String {
        if !hasConfirmedStatus { return isLoading ? "Sorgulanıyor" : "Bağlantı bekleniyor" }
        if isStale { return "Güncellenemedi" }
        if failedChecks > 0 { return "Son bilinen durum" }
        return isOnline ? "Çevrimiçi" : "Çevrimdışı"
    }

    private struct StatusResponse: Decodable {
        let online: Bool
        let players: Players?
        struct Players: Decodable {
            let online: Int?
            let max: Int?
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        // Check the authoritative game API first; use public Minecraft status as fallback.
        let sources = [
            ("https://blastermc.com/api/mobile/v1/server-status", "BlasterMC"),
            ("https://api.mcsrvstat.us/3/oyna.blastermc.com", "Harici sorgu")
        ]
        for (address, source) in sources {
            guard let url = URL(string: address) else { continue }
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 3
                request.cachePolicy = .reloadIgnoringLocalCacheData
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else { continue }
                let status = try JSONDecoder().decode(StatusResponse.self, from: data)
                isOnline = status.online
                onlinePlayers = status.players?.online ?? 0
                maxPlayers = status.players?.max ?? 0
                lastSuccess = Date()
                failedChecks = 0
                sourceName = source
                errorMessage = nil
                return
            } catch is CancellationError {
                return
            } catch {
                continue
            }
        }
        // Transient failures should not erase a valid previous result.
        failedChecks += 1
        if lastSuccess == nil {
            errorMessage = "Sunucu durumu doğrulanamadı. Yeniden deneniyor."
        } else if isStale {
            errorMessage = "Son başarılı sorgu 60 saniyeden eski. Durum doğrulanamıyor."
        } else {
            errorMessage = "Bağlantıda kısa kesinti; son doğrulanan bilgi gösteriliyor."
        }
    }
}

import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Resposta inválida do servidor."
        case .server(let message): return message
        }
    }
}

final class APIService {
    static let shared = APIService()
    // Troque pela URL real do seu Cloudflare Worker.
    private let baseURL = URL(string: "https://SEU-WORKER.workers.dev")!
    private init() {}

    private func request(path: String, method: String = "GET", token: String? = nil,
                         body: Data? = nil, contentType: String = "application/json") async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.httpBody = body
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Erro HTTP \(http.statusCode)"
            throw APIError.server(message)
        }
        return data
    }

    func authenticate(email: String, password: String, register: Bool) async throws -> AuthResponse {
        let body = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])
        let data = try await request(path: register ? "api/register" : "api/login",
                                     method: "POST", body: body)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func events(token: String) async throws -> [WebhookEvent] {
        let data = try await request(path: "api/events", token: token)
        return try JSONDecoder().decode(EventsResponse.self, from: data).events
    }

    func webhookToken(token: String) async throws -> String {
        let data = try await request(path: "api/me", token: token)
        struct MeResponse: Decodable { let user: APIUser }
        return try JSONDecoder().decode(MeResponse.self, from: data).user.webhookToken
    }

    func sendTest(token: String) async throws {
        _ = try await request(path: "api/test", method: "POST", token: token,
                              body: Data("{}".utf8))
    }
}

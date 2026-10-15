import Foundation

struct APIUser: Codable {
    let id: String
    let email: String
    let webhookToken: String
}

struct AuthResponse: Codable {
    let token: String
    let user: APIUser
}

struct WebhookEvent: Codable, Identifiable {
    let id: String
    let source: String
    let receivedAt: String
    let contentType: String
    let payload: String
    var read: Bool
}

struct EventsResponse: Codable {
    let events: [WebhookEvent]
}

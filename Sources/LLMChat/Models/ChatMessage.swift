import Foundation

public enum Role: String, Codable, Sendable {
    case user
    case assistant
    case system
}

public struct ChatMessage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let role: Role
    public var content: String
    public let createdAt: Date
    public var isStreaming: Bool

    public init(id: UUID = UUID(), role: Role, content: String, createdAt: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.isStreaming = isStreaming
    }
}

import Foundation

public protocol StreamClient: Sendable {
    func stream(prompt: String, history: [ChatMessage]) -> AsyncThrowingStream<String, Error>
}

/// Server-Sent Events streaming client for any OpenAI/Anthropic-compatible
/// streaming endpoint. Parses `data: <token>\n\n` framing. Reads via
/// `URLSession.bytes` for backpressure-friendly incremental decoding.
public struct SSEStreamClient: StreamClient {
    public let endpoint: URL
    public let apiKey: String?
    public let session: URLSession

    public init(
        endpoint: URL = URL(string: "https://api.example.com/v1/chat/stream")!,
        apiKey: String? = ProcessInfo.processInfo.environment["BROKERBOT_API_KEY"],
        session: URLSession = .shared
    ) {
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.session = session
    }

    public func stream(prompt: String, history: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var req = URLRequest(url: endpoint)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    if let apiKey { req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") }
                    let payload = RequestPayload(messages: history.map { .init(role: $0.role.rawValue, content: $0.content) } + [.init(role: "user", content: prompt)], stream: true)
                    req.httpBody = try JSONEncoder().encode(payload)

                    let (bytes, response) = try await session.bytes(for: req)
                    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                        throw StreamError.badResponse
                    }

                    var buffer = ""
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }
                        if let token = Self.decodeToken(from: payload) {
                            buffer += token
                            continuation.yield(token)
                        }
                    }
                    _ = buffer
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func decodeToken(from payload: String) -> String? {
        guard let data = payload.data(using: .utf8) else { return nil }
        if let delta = try? JSONDecoder().decode(ChunkOpenAI.self, from: data),
           let token = delta.choices.first?.delta.content {
            return token
        }
        if let anth = try? JSONDecoder().decode(ChunkAnthropic.self, from: data),
           anth.type == "content_block_delta" {
            return anth.delta?.text
        }
        return nil
    }

    private struct RequestPayload: Encodable {
        struct Msg: Encodable { let role: String; let content: String }
        let messages: [Msg]
        let stream: Bool
    }

    private struct ChunkOpenAI: Decodable {
        struct Choice: Decodable {
            struct Delta: Decodable { let content: String? }
            let delta: Delta
        }
        let choices: [Choice]
    }

    private struct ChunkAnthropic: Decodable {
        struct Delta: Decodable { let text: String? }
        let type: String
        let delta: Delta?
    }

    public enum StreamError: Error { case badResponse }
}

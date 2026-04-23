import Foundation
import Observation

@MainActor
@Observable
public final class ChatViewModel {
    public var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: "Hi - I am BrokerBot. Ask anything about your listings, policies, or marketing.")
    ]
    public var input: String = ""
    public var isStreaming: Bool = false
    public var errorMessage: String?

    private let client: StreamClient
    private var streamTask: Task<Void, Never>?

    public init(client: StreamClient) {
        self.client = client
    }

    public func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }
        input = ""
        errorMessage = nil

        let userMsg = ChatMessage(role: .user, content: trimmed)
        messages.append(userMsg)

        let assistantId = UUID()
        messages.append(ChatMessage(id: assistantId, role: .assistant, content: "", isStreaming: true))
        isStreaming = true

        let history = Array(messages.dropLast(2))

        streamTask = Task { [weak self] in
            guard let self else { return }
            defer { Task { @MainActor in self.isStreaming = false } }
            do {
                for try await token in client.stream(prompt: trimmed, history: history) {
                    if Task.isCancelled { return }
                    if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                        messages[idx].content += token
                    }
                }
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].isStreaming = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    if let idx = self.messages.firstIndex(where: { $0.id == assistantId }) {
                        self.messages[idx].isStreaming = false
                        if self.messages[idx].content.isEmpty {
                            self.messages.remove(at: idx)
                        }
                    }
                }
            }
        }
    }

    public func cancel() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }
}

import XCTest
@testable import LLMChat

final class SSEStreamClientTests: XCTestCase {
    func testChatMessageInitializes() {
        let m = ChatMessage(role: .user, content: "hi")
        XCTAssertEqual(m.role, .user)
        XCTAssertEqual(m.content, "hi")
        XCTAssertFalse(m.isStreaming)
    }

    @MainActor
    func testViewModelInitialMessage() {
        let vm = ChatViewModel(client: StubClient(tokens: []))
        XCTAssertEqual(vm.messages.count, 1)
        XCTAssertEqual(vm.messages.first?.role, .assistant)
    }

    @MainActor
    func testViewModelAppendsStreamedTokens() async {
        let vm = ChatViewModel(client: StubClient(tokens: ["Hel", "lo", " world"]))
        vm.input = "Hi"
        vm.send()
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(vm.messages.last?.role, .assistant)
        XCTAssertEqual(vm.messages.last?.content, "Hello world")
    }
}

struct StubClient: StreamClient {
    let tokens: [String]
    func stream(prompt: String, history: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for t in tokens {
                    try? await Task.sleep(nanoseconds: 10_000_000)
                    continuation.yield(t)
                }
                continuation.finish()
            }
        }
    }
}

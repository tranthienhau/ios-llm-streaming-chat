import SwiftUI

@main
public struct LLMChatApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            ChatView(viewModel: ChatViewModel(client: SSEStreamClient()))
        }
    }
}

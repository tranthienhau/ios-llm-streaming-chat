import SwiftUI

public struct ChatView: View {
    @Bindable var viewModel: ChatViewModel

    public init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesList
                Divider()
                inputBar
            }
            .navigationTitle("BrokerBot")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg).id(msg.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: viewModel.messages.last?.content) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask BrokerBot...", text: $viewModel.input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .disabled(viewModel.isStreaming)
                .onSubmit(viewModel.send)

            if viewModel.isStreaming {
                Button(action: viewModel.cancel) {
                    Image(systemName: "stop.circle.fill").font(.title2)
                }
                .tint(.red)
            } else {
                Button(action: viewModel.send) {
                    Image(systemName: "arrow.up.circle.fill").font(.title2)
                }
                .disabled(viewModel.input.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(12)
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.content.isEmpty && message.isStreaming ? "..." : message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(background)
                .foregroundStyle(foreground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .textSelection(.enabled)
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var background: Color {
        message.role == .user ? .accentColor : Color(.systemGray6)
    }

    private var foreground: Color {
        message.role == .user ? .white : .primary
    }
}

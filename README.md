# ios-llm-streaming-chat

Native iOS LLM streaming chat POC - SwiftUI + Swift Concurrency + Server-Sent Events. Built for a BrokerBot-style AI chat experience where tokens stream into the UI as the model generates them.

## Features

- **SwiftUI chat UI** with scrolling bubble list, auto-scroll to latest token, textSelection
- **Streaming**: `AsyncThrowingStream<String, Error>` fed by `URLSession.bytes(for:).lines` - backpressure-friendly, cancellable
- **SSE parser** handles both OpenAI-style `choices[0].delta.content` and Anthropic-style `content_block_delta` framing
- **@Observable view model** (iOS 17+), cancel-in-flight, error surfacing via SwiftUI `.alert`
- **Cancellation** wired from `Button` -> `Task.cancel()` -> `URLSessionTask.cancel()` via `onTermination`
- **Protocol-based client** (`StreamClient`) for clean unit testing - see `StubClient` in tests

## Targeting

Built as an SPM library target to drop into an Xcode app. Minimum iOS 17 for `@Observable`. For iOS 16, swap to `ObservableObject` + `@Published`.

## Stack

Swift 5.9, SwiftUI, Swift Concurrency, `URLSession`, SPM. No third-party deps.

## Run tests

```
swift test
```

## Wire to a real endpoint

Set `BROKERBOT_API_KEY` env var and initialize `SSEStreamClient(endpoint: URL(string: "...")!)`. The parser already handles OpenAI + Anthropic SSE shapes - for other providers, extend `decodeToken`.

// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LLMChat",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "LLMChat", targets: ["LLMChat"]),
    ],
    targets: [
        .target(
            name: "LLMChat",
            path: "Sources/LLMChat"
        ),
        .testTarget(
            name: "LLMChatTests",
            dependencies: ["LLMChat"],
            path: "Tests/LLMChatTests"
        ),
    ]
)

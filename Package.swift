// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "RoomDebts",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
        .package(url: "https://github.com/MihaelIsaev/FluentQuery.git", from: "0.4.30"),

        // 📚 Other third-party libraries
        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor-community/lingo-vapor.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "App", dependencies: ["JWT", "FluentPostgreSQL", "Vapor", "FluentQuery", "LingoVapor"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)


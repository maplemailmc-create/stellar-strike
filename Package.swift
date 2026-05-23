// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShooterGame",
    platforms: [.iOS(.v17)],
    products: [
        .executable(name: "ShooterGame", targets: ["ShooterGame"])
    ],
    targets: [
        .executableTarget(
            name: "ShooterGame",
            path: "Sources/ShooterGame"
        )
    ]
)

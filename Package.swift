// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SNMPMonitor",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "SNMPMonitor", targets: ["SNMPMonitor"])
    ],
    dependencies: [
        .package(url: "https://github.com/darrellroot/SwiftSnmpKit.git", .upToNextMajor(from: "0.2.0"))
    ],
    targets: [
        .executableTarget(
            name: "SNMPMonitor",
            dependencies: [
                .product(name: "SwiftSnmpKit", package: "SwiftSnmpKit")
            ]
        )
    ]
)

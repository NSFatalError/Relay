// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Relay",
    platforms: [
        .macOS(.v14),
        .macCatalyst(.v17),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Relay",
            targets: ["Relay"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/NSFatalError/PrincipleMacros",
            "3.0.0" ..< "4.0.0"
        ),
        .package(
            url: "https://github.com/swiftlang/swift-syntax",
            "602.0.0" ..< "603.0.0"
        )
    ],
    targets: [
        .target(
            name: "Relay",
            dependencies: [
                "RelayMacros",
                .product(
                    name: "PrincipleMacrosClientSupport",
                    package: "PrincipleMacros"
                )
            ]
        ),
        .testTarget(
            name: "RelayTests",
            dependencies: ["Relay"]
        ),
        .macro(
            name: "RelayMacros",
            dependencies: [
                .product(
                    name: "PrincipleMacros",
                    package: "PrincipleMacros"
                ),
                .product(
                    name: "SwiftCompilerPlugin",
                    package: "swift-syntax",
                    condition: .when(platforms: [.macOS])
                )
            ]
        ),
        .testTarget(
            name: "RelayMacrosTests",
            dependencies: [
                "RelayMacros",
                .product(
                    name: "PrincipleMacrosTestSupport",
                    package: "PrincipleMacros"
                ),
                .product(
                    name: "SwiftCompilerPlugin",
                    package: "swift-syntax",
                    condition: .when(platforms: [.macOS])
                )
            ]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault")
    ]
}

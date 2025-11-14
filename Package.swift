// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Publishable",
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
            name: "Publishable",
            targets: ["Publishable"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/NSFatalError/PrincipleMacros",
            revision: "e7336abe981c31deaebde62c5dd216fb88029f90"
        ),
        .package(
            url: "https://github.com/swiftlang/swift-syntax",
            "602.0.0" ..< "603.0.0"
        )
    ],
    targets: [
        .target(
            name: "Publishable",
            dependencies: ["PublishableMacros"]
        ),
        .testTarget(
            name: "PublishableTests",
            dependencies: ["Publishable"]
        ),
        .macro(
            name: "PublishableMacros",
            dependencies: [
                .product(
                    name: "PrincipleMacros",
                    package: "PrincipleMacros"
                ),
                .product(
                    name: "SwiftCompilerPlugin",
                    package: "swift-syntax"
                )
            ]
        ),
        .testTarget(
            name: "PublishableMacrosTests",
            dependencies: [
                "PublishableMacros",
                .product(
                    name: "PrincipleMacrosTestSupport",
                    package: "PrincipleMacros"
                ),
                .product(
                    name: "SwiftCompilerPlugin",
                    package: "swift-syntax"
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

// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CursorDesigner",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PointerDesigner", targets: ["PointerDesigner"]),
        .executable(name: "PointerDesignerHelper", targets: ["PointerDesignerHelper"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "PointerDesigner",
            dependencies: ["PointerDesignerCore"],
            path: "Sources/PointerDesigner",
            exclude: ["Resources"]
        ),
        .target(
            name: "PointerDesignerCore",
            dependencies: [],
            path: "Sources/PointerDesignerCore"
        ),
        .executableTarget(
            name: "PointerDesignerHelper",
            dependencies: ["PointerDesignerCore"],
            path: "Sources/PointerDesignerHelper",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "PointerDesignerTests",
            dependencies: ["PointerDesignerCore"],
            path: "Tests/PointerDesignerTests"
        )
    ]
)

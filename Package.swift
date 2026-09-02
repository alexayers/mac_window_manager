// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Sizer",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Sizer",
            path: "Sources/Sizer"
        )
    ]
)

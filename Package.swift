// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "CSVImporter",
    products: [
        .library(
            name: "CSVImporter",
            targets: ["CSVImporter"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Flinesoft/HandySwift.git", .upToNextMajor(from: "2.5.0"))
    ],
    targets: [
        .target(
            name: "CSVImporter",
            dependencies: [
                "HandySwift"
            ],
            path: "Sources",
            exclude: [
                "Sources/Supporting Files"
            ]
        )
    ],
    swiftLanguageVersions: [4]
)

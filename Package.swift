// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "CSVImporter",
    products: [
        .library(name: "CSVImporter", targets: ["CSVImporter"])
    ],
    dependencies: [
        .package(url: "https://github.com/Flinesoft/HandySwift.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "2.1.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "8.0.1")),
    ],
    targets: [
        .target(
            name: "CSVImporter",
            dependencies: ["HandySwift"],
            path: "Frameworks/CSVImporter",
            exclude: ["Frameworks/SupportingFiles"]
        ),
        .testTarget(
            name: "CSVImporterTests",
            dependencies: ["CSVImporter", "Quick", "Nimble"],
            exclude: ["Tests/SupportingFiles"]
        )
    ],
    swiftLanguageVersions: [4]
)

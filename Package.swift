// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "CSVImporter",
    products: [
        .library(name: "CSVImporter", targets: ["CSVImporter"])
    ],
    dependencies: [
        .package(url: "https://github.com/Flinesoft/HandySwift.git", .upToNextMajor(from: "2.7.0")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "1.3.2")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "7.3.1"))
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

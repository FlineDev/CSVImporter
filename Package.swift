// swift-tools-version:5.9
import PackageDescription

let package = Package(
   name: "CSVImporter",
   platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
   products: [
      .library(name: "CSVImporter", targets: ["CSVImporter"])
   ],
   dependencies: [
      .package(url: "https://github.com/Flinesoft/HandySwift.git", branch: "main"),
      .package(url: "https://github.com/Quick/Quick.git", from: "2.1.0"),
      .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.1"),
   ],
   targets: [
      .target(
         name: "CSVImporter",
         dependencies: ["HandySwift"],
         path: "Frameworks/CSVImporter"
      ),
      .testTarget(
         name: "CSVImporterTests",
         dependencies: ["CSVImporter", "Quick", "Nimble"]
      )
   ]
)

// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "TJActivityViewController",
    platforms: [.iOS(.v13), .macCatalyst(.v13)],
    products: [
        .library(
            name: "TJActivityViewController",
            targets: ["TJActivityViewController"]
        )
    ],
    targets: [
        .target(
            name: "TJActivityViewController",
            path: ".",
            publicHeadersPath: "."
        )
    ]
)

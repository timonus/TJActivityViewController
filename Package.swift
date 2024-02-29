// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "TJActivityViewController",
    platforms: [.iOS(.v8), .macCatalyst(.v8)],
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
            sources: ["TJActivityViewController.m"],
            publicHeadersPath: "."
        )
    ]
)

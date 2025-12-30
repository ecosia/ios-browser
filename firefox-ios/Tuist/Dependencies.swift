import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
        .local(path: "../BrowserKit"),
        .remote(url: "https://github.com/auth0/Auth0.swift.git", requirement: .upToNextMajor(from: "2.0.0")),
        .remote(url: "https://github.com/braze-inc/braze-swift-sdk.git", requirement: .upToNextMajor(from: "11.9.0")),
        .remote(url: "https://github.com/DataDog/dd-sdk-ios.git", requirement: .upToNextMajor(from: "1.0.0")),
        .remote(url: "https://github.com/airbnb/lottie-ios.git", requirement: .upToNextMajor(from: "4.4.0")),
        .remote(url: "https://github.com/scinfu/SwiftSoup.git", requirement: .upToNextMajor(from: "2.5.3")),
        .remote(url: "https://github.com/mozilla/glean-swift.git", requirement: .branch("main")),
        .remote(url: "https://github.com/snowplow/snowplow-ios-tracker.git", requirement: .upToNextMajor(from: "6.0.9")),
        .remote(url: "https://github.com/auth0/SimpleKeychain.git", requirement: .upToNextMajor(from: "1.3.0")),
        .remote(url: "https://github.com/auth0/JWTDecode.swift.git", requirement: .upToNextMajor(from: "3.3.0")),
        .remote(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", requirement: .upToNextMajor(from: "1.18.7")),
        .remote(url: "https://github.com/nalexn/ViewInspector.git", requirement: .upToNextMajor(from: "0.10.1")),
        .remote(url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git", requirement: .upToNextMajor(from: "1.5.1")),
        .remote(url: "https://github.com/pointfreeco/swift-custom-dump.git", requirement: .upToNextMajor(from: "1.3.3")),
        .remote(url: "https://github.com/kif-framework/KIF.git", requirement: .upToNextMajor(from: "3.8.9")),
        .remote(url: "https://github.com/adjust/ios_sdk.git", requirement: .upToNextMajor(from: "4.37.0")),
        .remote(url: "https://github.com/SnapKit/SnapKit.git", requirement: .upToNextMajor(from: "5.7.0")),
        .remote(url: "https://github.com/Dev1an/A-Star.git", requirement: .upToNextMajor(from: "3.0.0-beta-1")),
        .remote(url: "https://github.com/SDWebImage/SDWebImage.git", requirement: .upToNextMajor(from: "5.20.0")),
        .remote(url: "https://github.com/swiftlang/swift-syntax.git", requirement: .upToNextMajor(from: "600.0.1")),
        .remote(url: "https://github.com/apple/swift-asn1.git", requirement: .upToNextMajor(from: "1.3.1")),
        .remote(url: "https://github.com/apple/swift-certificates.git", requirement: .upToNextMajor(from: "1.2.0")),
        .remote(url: "https://github.com/mozilla-mobile/MappaMundi.git", requirement: .branch("master")),
        .remote(url: "https://github.com/ecosia/rust-components-swift/", requirement: .branch("main")),
    ]
)



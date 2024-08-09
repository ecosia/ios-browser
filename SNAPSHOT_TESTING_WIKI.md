## Snapshot Testing Library

The SnapshotTesting library is a Swift package that allows you to capture screenshots of iOS views and compare them over time, ensuring your UI does not change unexpectedly. It is highly effective in preventing visual regressions during development.
[Repo link](https://github.com/pointfreeco/swift-snapshot-testing?tab=readme-ov-file)

## SnapshotTestHelper

SnapshotTestHelper is a utility class designed to facilitate snapshot testing across different UI themes, device configurations, and locales for both UIView and UIViewController. It abstracts complex snapshot configurations and provides a simplified API for performing localized snapshot tests.

### Key Functions a.k.a. what happens under the hood 👀

#### performSnapshot

- **Purpose**: Executes the snapshot test with specified configurations.
- **Parameters**:
  - `initializer`: A closure that returns the UI component to be tested.
  - `devices`: An array of device configurations to simulate different screen sizes and resolutions.
  - `locales`: An array of locales to test the component in different languages.
  - `wait`: Duration to wait before taking the snapshot, allowing UI to stabilize.
  - `precision`: The accuracy of the snapshot comparison.
  - `file`, `testName`, `line`: Standard XCTest parameters for identifying the test source.

#### assertSnapshot

- **Purpose**: Public interfaces for asserting snapshots of UIView and UIViewController.
- **Parameters**:
  - Includes parameters for initializing content, device simulation, locale settings, and test configurations.

#### setLocale

- **Purpose**: Sets the application’s locale to simulate different languages.
- **Implementation Details**: Updates the UserDefaults to reflect the chosen locale and swaps the main Bundle to use localized resources.

#### setupContent

- **Purpose**: Configures the UIWindow with the content to be snapshot.
- **Details**: Adds the content to the window, sets appropriate bounds, and ensures it is ready for display and snapshotting.

### Localization Support 🗣️

SnapshotTestHelper can perform snapshots in various languages by dynamically setting the application’s locale before rendering the UI. This is particularly useful for apps supporting multiple languages, ensuring that all localized strings appear correctly in the UI across different device configurations.

### Example Usage

#### Testing a UIViewController (Welcome Screen)

```swift
func testWelcomeScreen() {
    SnapshotTestHelper.assertSnapshot(initializingWith: {
        Welcome(delegate: MockWelcomeDelegate())
    }, wait: 1.0)
}
```

This test initializes a Welcome view controller with a mock delegate and asserts its appearance in English by default against an iPhone12Pro form factor in portrait mode.

#### Testing a UIView (NTPLogoCell)

```swift
func testNTPLogoCell() {
    SnapshotTestHelper.assertSnapshot(initializingWith: {
        NTPLogoCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
    })
}
```

This test captures a snapshot of the NTPLogoCell, a custom view, to ensure its visual layout remains consistent across updates.

This documentation should help developers understand how to leverage SnapshotTestHelper for comprehensive UI testing, including handling different themes, devices, and languages.

### FAQ ⁉️

<details>
<summary> What if I want to test on different devices? </summary>

To perform snapshot tests on different devices, you can specify the devices using the `devices` parameter in the `assertSnapshot` function. SnapshotTestHelper configures the test environment to simulate the screen size and resolution of the specified devices.

**Example:**

```swift
SnapshotTestHelper.assertSnapshot(initializingWith: {
    MyCustomView()
}, devices: [.iPhone8_Portrait, .iPadPro_Portrait], wait: 1.0)
```

This configuration tests the MyCustomView on both an iPhone 8 in portrait mode and an iPad Pro in portrait mode.
</details>

<details>
<summary> What if I want to test with different languages? </summary>

SnapshotTestHelper supports testing UI components in different languages by passing an array of Locale objects to the locales parameter. This adjusts the app’s locale settings dynamically before capturing each snapshot, ensuring that localized strings are displayed correctly.

```swift
SnapshotTestHelper.assertSnapshot(initializingWith: {
    LocalizedWelcomeView()
}, locales: [Locale(identifier: "en"), Locale(identifier: "fr")], wait: 1.0)
```

This tests the LocalizedWelcomeView in both English and French, capturing how the view appears with different localized content.
</details>

<details>
<summary> What if I want to add another device in landscape orientation? </summary>

Here’s how you can add a device in landscape orientation:

In your DeviceType enum, ensure you have a landscape configuration set up for the device:

```swift
enum DeviceType: String, CaseIterable {
    case iPhone12Pro_Portrait
    case iPhone12Pro_Landscape // Define the landscape configuration

    var config: ViewImageConfig {
        switch self {
        case .iPhone12Pro_Portrait:
            return ViewImageConfig.iPhone12Pro(.portrait)
        case .iPhone12Pro_Landscape:
            return ViewImageConfig.iPhone12Pro(.landscape)
        }
    }
}
```

Then, to test on landscape devices using SnapshotTestHelper, you need to specify the device and orientation when configuring your test.

```swift
SnapshotTestHelper.assertSnapshot(
    initializingWith: { YourCustomView() },
    devices: [.iPhone12Pro_Landscape], // Assume you have defined this device configuration for landscape orientation earlier like above
    wait: 1.0
)
```
</details>

<details>
<summary> How does the compare logic work? </summary>

The SnapshotTesting library captures screenshots of your UI components and compares these images against reference images stored in your project. If a reference image does not exist, it is created on the first run, meaning the initial test will always “pass” by creating the needed baseline images.

On subsequent test runs, the newly captured snapshot is compared pixel by pixel against the reference image. If differences are detected beyond the specified precision threshold, the test fails, and the differences can be reviewed visually in Xcode. This helps identify unintended changes or regressions in the UI layout and appearance.

</details>

### Key Points 🎯:

- Reference images are stored in your project directory under a folder typically named __Snapshots__.
- The precision parameter allows for control over how exact the comparison needs to be, accommodating minor rendering differences across environments.
- Failed tests will provide a visual diff image showing highlighted differences between the reference and the test snapshots.
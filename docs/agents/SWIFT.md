# Swift Code Standards

## MVVM with SwiftUI

- Use MVVM architecture with SwiftUI for new UI components
- Follow protocol-oriented programming principles
- Prefer value types (structs) over reference types (classes) when possible
- Use `ObservableObject` and `@Published` properties for view models

## SwiftUI First Approach

- Use SwiftUI for new UI components; only use UIKit when SwiftUI is insufficient
- Always create a SwiftUI preview to test the View's behavior
- Implement theming through `EcosiaThemeable` protocol
- Apply themes with `.ecosiaThemed(windowUUID, $theme)` modifier

### Theme Container Pattern

```swift
struct MyComponentTheme: EcosiaThemeable {
    var backgroundColor = Color.white
    mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundPrimary)
    }
}
```

## Naming Conventions

- Variables/Functions: `camelCase` (e.g., `searchViewModel`, `handleUserTap`)
- Types/Classes/Structs: `PascalCase` (e.g., `FeedbackViewModel`, `EcosiaHomeView`)
- Constants: `PascalCase` for static properties (e.g., `DefaultTimeout`)
- Methods: Use verbs (e.g., `fetchData`, `applyTheme`, `handleError`)
- Booleans: Use `is`/`has`/`should` prefixes (e.g., `isLoading`, `hasContent`)
- Follow Apple's API Design Guidelines

## Swift Best Practices

- Use strong typing with proper optional handling (`if let`, `guard let`)
- Leverage `async/await` for asynchronous operations
- Use `Result` type for error handling scenarios
- Prefer `let` over `var` for immutable properties
- Use protocol extensions for shared functionality
- Avoid force unwrapping (`!`) except in controlled scenarios
- Use computed properties where appropriate

## Error Handling & Logging

- Use `EcosiaLogger` for consistent logging (levels: `.debug`, `.info`, `.warning`, `.error`)
- Use `.error` log level instead of `.warning` for error conditions
- Include relevant context in log messages; never log sensitive user data
- Implement `Result` type for operations that can fail
- Use `async/await` with proper error propagation using `throws`
- Handle network errors gracefully with user-friendly messages
- Provide fallback behavior for non-critical failures
- Implement retry logic with exponential backoff for network operations

## Analytics

- **ALL** analytics instrumentation must be at the UI/ViewModel layer
- Use `Analytics.shared` (never reassign the shared instance)
- Follow established event patterns in `Analytics.Values.swift`
- Track user actions, not internal system events
- Example: `Analytics.shared.activity(.homePageViewed)`

## Accessibility

- Dark mode compatibility
- Dynamic Type support
- VoiceOver support
- Reduce Motion preference

## Performance

- Use Instruments for performance profiling
- Implement lazy loading for views and data
- Optimize network requests with proper caching
- Use `@StateObject` vs `@ObservedObject` appropriately
- Use `LazyVStack`/`LazyHStack` for efficient list rendering
- Prevent memory leaks and retain cycles

## Security

- Encrypt sensitive data using Keychain Services
- Use secure communication (certificate pinning where needed)
- Implement biometric authentication for sensitive operations
- Follow App Transport Security requirements
- Validate and sanitize all user inputs

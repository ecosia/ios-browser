# Swift Concurrency Audit Report
## Ecosia iOS Browser - Swift 6.2 Compliance

Based on [Swift Concurrency Agent Skill](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill) best practices

**Date:** January 21, 2026  
**Swift Version:** 6.2  
**Scope:** Ecosia framework + Client/Ecosia folder

---

## ✅ Already Fixed (18 files)

- ✅ Publisher.swift - @MainActor + @Sendable closures
- ✅ Images.swift - Actor with async/await
- ✅ News.swift - @MainActor with async file I/O
- ✅ EcosiaBrowserWindowAuthManager.swift - Actor isolation
- ✅ EcosiaAuthWindowRegistry.swift - Actor isolation
- ✅ Tabs.swift - Async/await file operations
- ✅ PageStore.swift - Async file I/O
- ✅ BookmarkSerializer.swift - Task.detached
- ✅ BookmarkParser.swift - Task.detached
- ✅ EcosiaErrorToast.swift - Task.sleep
- ✅ EcosiaAuthUIStateProvider.swift - @MainActor
- ✅ EcosiaAccountAvatarViewModel.swift - @MainActor
- ✅ NewsModel, Tab, Page, AuthStateAction, AuthWindowState - Sendable

---

## 🔴 Critical Issues (MUST FIX)

### 1. **Analytics.swift** - Singleton with no isolation
**Issue:** `static var shared` with mutable tracker state, accesses `User.shared` across threads  
**Risk:** Data races when tracking events from multiple threads  
**Fix:** Add `@MainActor` isolation or convert to actor  
**Lines:** 9-542

### 2. **BrazeService.swift** - Singleton with mutable state
**Issue:** `static let shared` with mutable `braze`, `notificationAuthorizationStatus`, uses Tasks but no isolation  
**Risk:** Data races on Braze instance and notification status  
**Fix:** Convert to actor or add @MainActor  
**Lines:** 15-224

### 3. **EcosiaAuthenticationService.swift** - Singleton with critical auth state
**Issue:** `static let shared` with mutable `idToken`, `accessToken`, `isLoggedIn`, no isolation  
**Risk:** **SECURITY RISK** - Race conditions on authentication state could allow unauthorized access  
**Fix:** Convert to actor for thread-safe credential management  
**Lines:** 16-418

### 4. **Statistics.swift** - Singleton with mutable state
**Issue:** `static let shared` with multiple mutable properties, async methods mutate without isolation  
**Risk:** Data races on statistics values  
**Fix:** Add `@MainActor` or convert to actor  
**Lines:** 7-79

### 5. **InvisibleTabAutoCloseManager.swift** - DispatchQueue.concurrent for state
**Issue:** Uses `DispatchQueue.concurrent` with barriers, `DispatchQueue.main.asyncAfter` for timeouts  
**Risk:** Complex manual synchronization, potential deadlocks  
**Fix:** Convert to actor, replace timeouts with Task.sleep  
**Lines:** 22-349

### 6. **User.swift** - Static mutable shared state
**Issue:** `static var shared` with `didSet` calling `DispatchQueue.main.async`  
**Risk:** Data races on User.shared modifications  
**Fix:** Add @MainActor isolation  
**Lines:** 14-308

---

## 🟡 Medium Priority Issues

### 7. **MMP.swift** - Static methods spawning Tasks
**Issue:** Static methods with `Task { }` accessing `User.shared` without isolation  
**Risk:** Minor - mostly fire-and-forget analytics  
**Fix:** Add @MainActor or document thread-safety  
**Lines:** 21-74

### 8. **Client/Ecosia DispatchQueue usage** (8 files)
**Files:**
- EcosiaThemeManager.swift
- NTPHeaderViewModel.swift
- EcosiaDebugSettings.swift
- DispatchQueueHelper+BuildChannel.swift
- BrowserViewController+Ecosia.swift
- BookmarksExchange.swift
- TabAutoCloseManager.swift ⚠️ (see #5)
- EcosiaAuthFlow.swift

**Issue:** Legacy DispatchQueue patterns  
**Fix:** Migrate to async/await where appropriate

### 9. **@objc methods** (14 files)
**Issue:** Objective-C interop might need `@MainActor` annotations  
**Fix:** Review each for proper isolation

---

## 🟢 Low Priority / Informational

### 10. **ObservableObject ViewModels** (5 files)
**Status:** ✅ All already have `@MainActor`  
- EcosiaAuthUIStateProvider.swift
- EcosiaAccountAvatarViewModel.swift
- EcosiaCachedAsyncImage.swift
- EcosiaAccountImpactViewModel.swift
- EcosiaAccountSignedOutView.swift

### 11. **NSObject subclasses** (3 files)
**Files:**
- BrazeService.swift (see #2)
- EcosiaWebViewModal.swift
- DefaultBrowserCoordinator.swift

**Action:** Verify proper isolation for UIKit integration

### 12. **Delegate protocols** (2 files)
**Files:**
- BrazeService.swift (BrazeBrowserDelegate)
- ConfigurableNudgeCardView.swift

**Action:** Consider @MainActor if UI-related

---

## 📊 Summary

| Priority | Count | Status |
|----------|-------|--------|
| ✅ Fixed | 18 | Complete |
| 🔴 Critical | 6 | **Needs immediate attention** |
| 🟡 Medium | 3 | Should fix |
| 🟢 Low | 3 | Optional |
| **Total** | **30** | **80% done** |

---

## 🚀 Recommended Fix Order

1. **EcosiaAuthenticationService** (SECURITY)
2. **Analytics** (High traffic)
3. **BrazeService** (External SDK integration)
4. **Statistics** (Shared state)
5. **InvisibleTabAutoCloseManager** (Complex logic)
6. **User** (Core app state)
7. Remaining DispatchQueue migrations
8. Review @objc methods

---

## 📋 Testing Strategy

After fixes:
1. ✅ Build with Swift 6.2 strict concurrency
2. ✅ Run complete test suite
3. ✅ Test authentication flows (critical path)
4. ✅ Test analytics tracking
5. ✅ Test tab management
6. ✅ Verify no performance regressions

---

## 🔗 References

- [Swift Concurrency Agent Skill](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill)
- [Swift Concurrency Course](https://www.swiftconcurrencycourse.com)
- [actors.md](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill/blob/main/swift-concurrency/references/actors.md)
- [sendable.md](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill/blob/main/swift-concurrency/references/sendable.md)
- [threading.md](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill/blob/main/swift-concurrency/references/threading.md)

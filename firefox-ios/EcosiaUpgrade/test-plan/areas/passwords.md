# Passwords

Covers:
- `firefox-ios/Client/Frontend/PasswordManagement/`
- `firefox-ios/Client/Frontend/Autofill/`
- `firefox-ios/Storage/Rust/RustLogins+EcosiaMigration.swift`

```mermaid
flowchart LR
  pw[Passwords]
  pw --> passwords.add-manually
  pw --> passwords.save-from-login
  pw --> passwords.use-on-login
  pw --> passwords.delete
```

## passwords.add-manually
p2 · origin 147 board "Passwords → Add password"

Add a password from the passwords screen.

**Setup:** existing · en

1. Settings → Passwords (approve the passcode prompt on the simulator: Features → Face ID → Matching Face, or `xcrun simctl spawn <udid> notifyutil -p com.apple.BiometricKit_Sim.pearl.match`).
2. Add a login for `https://example.com` with a made-up username and password. Screenshot the list.

**Expect:** the login is listed and can be opened, revealed and copied.

## passwords.save-from-login
p2 · origin 147 board "Passwords → via tooltip"

Submitting a login form offers to save the password.

**Setup:** existing · en

1. Open a public test login form (for example `https://the-internet.herokuapp.com/login`), fill it with the form's published demo values, submit.
2. Screenshot the save prompt; save.

**Expect:** the app offers to save; the login appears in Passwords.

## passwords.use-on-login
p2

Saved logins fill a login form.

**Setup:** existing · en

1. Return to the login form from the previous flow; tap the username field. Screenshot the suggestion.
2. Choose the saved login.

**Expect:** the saved login is offered and fills both fields.

## passwords.delete
p3

Deleting a saved password.

**Setup:** existing · en

1. Settings → Passwords, delete the test login.

**Expect:** it's gone and isn't offered on the form any more.

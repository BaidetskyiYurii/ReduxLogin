# 🔐 ReduxLogin — Redux Architecture + Multi-Provider Auth + OWASP Security

> A production-ready iOS authentication demo implementing Redux state management, four sign-in providers, and OWASP Mobile Top 10 security practices — built with SwiftUI, Combine, and Firebase.

![Platform](https://img.shields.io/badge/Platform-iOS%2016%2B-blue?style=flat)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple?style=flat)
![Architecture](https://img.shields.io/badge/Architecture-Redux-red?style=flat)
![Security](https://img.shields.io/badge/Security-OWASP%20Mobile%20Top%2010-black?style=flat)

---

## 📱 What It Does

ReduxLogin is a focused iOS demo covering two things most authentication demos skip: **proper architecture** and **real security practices**. It implements a custom Redux store in Swift, connects it to four authentication providers via Firebase, and applies OWASP Mobile Top 10 security guidelines throughout — Keychain storage, AES-GCM encryption, cryptographic nonces, and environment-based key management.

---

## ✨ Features

**Authentication Providers**
- ✉️ Email / Password — sign up and sign in via Firebase Auth
- 🍎 Sign in with Apple — with cryptographic nonce and SHA-256 hashing
- 🔵 Google Sign-In — with AES-encrypted client ID
- 📘 Facebook Login — via Facebook SDK + Firebase credential

**Redux Architecture**
- Generic `Store<State, Action>` — type-safe, reusable across any state/action pair
- `Reducer<State, Action>` — pure function returning `AnyPublisher` for async actions
- `AppState` — single source of truth for auth state
- `AppAction` — exhaustive enum covering all auth flows
- All async auth operations (Firebase, Apple, Google, Facebook) integrated as Combine publishers

**Security — OWASP Mobile Top 10**
- See dedicated section below

**Additional**
- Push notifications via Firebase Messaging (FCM)
- Animated `MovingShapesView` background
- Sign out and account deletion flows
- Keychain-based session persistence across launches

---

## 🛡 OWASP Mobile Top 10 — Security Implementation

### M1 — Improper Credential Usage
Credentials and auth tokens are **never stored in UserDefaults or plain files**. All sensitive data goes through `KeychainManager`:
```swift
keychainManager.save(account: .userEmail, value: email)
keychainManager.save(account: .userPassword, value: password)
keychainManager.save(account: .userToken, value: token)
```

### M2 — Inadequate Supply Chain Security
Encryption keys are **never hardcoded** in source code. They are loaded from environment variables at runtime:
```swift
guard let encryptionKey = ProcessInfo.processInfo.environment["ENCRYPTION_KEY"] else {
    print("Encryption key not found in environment variables")
    return
}
```

### M9 — Insecure Data Storage
`KeychainManager` wraps the Security framework with a clean, typed API — storing, retrieving, and deleting credentials using `kSecClassGenericPassword` with service and account scoping. On sign-out, all credentials are deleted atomically:
```swift
keychainManager.deleteAllCredentials()
```

### Cryptographic Nonce — Replay Attack Prevention
Sign in with Apple uses a **cryptographically secure random nonce** generated via `SecRandomCopyBytes`, then hashed with SHA-256 before being sent to Apple. This prevents replay attacks on the identity token:
```swift
let nonce = randomNonceString() // SecRandomCopyBytes
request.nonce = sha256(nonce)   // SHA256 via CryptoKit
```

### AES-GCM Encryption
Sensitive configuration data (e.g. OAuth client IDs) is encrypted at rest using **AES-256-GCM** via Apple's `CryptoKit` framework, with keys derived from SHA-256:
```swift
struct AESEncryption {
    func encrypt(data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    func decrypt(data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
```

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|------------|
| Architecture | Custom Redux — `Store`, `Reducer`, `AppState`, `AppAction` |
| Reactive | Combine — `PassthroughSubject`, `AnyPublisher` |
| UI Framework | SwiftUI |
| Auth | Firebase Auth — Email, Apple, Google, Facebook |
| Security | CryptoKit — AES-GCM, SHA-256 |
| Secure Storage | Keychain — Security framework |
| Push Notifications | Firebase Messaging (FCM) |
| Min Deployment | iOS 16.0 |
| Swift | 5.9 |

---

## 🏗 Project Structure

```
ReduxLogin/
├── Redux/
│   ├── Store.swift          # Generic Store<State, Action> with Combine
│   ├── Reducer.swift        # Generic Reducer — sync + async support
│   ├── AppState.swift       # Single source of truth — auth state
│   ├── AppAction.swift      # All actions: email, Apple, Google, Facebook, signOut
│   └── AppReducer.swift     # Maps actions to AuthService publishers
├── Helpers/
│   ├── AuthService.swift    # Firebase Auth — all 4 providers
│   ├── KeychainManager.swift # Secure credential storage
│   ├── AESEncryption.swift  # AES-GCM encryption via CryptoKit
│   ├── NotificationManager.swift # FCM push notifications
│   └── ApplicationUtility.swift  # Root/top view controller helpers
├── Scenes/
│   ├── Login/LoginView.swift # Auth UI — all 4 sign-in methods
│   └── Home/HomeView.swift   # Post-auth screen with sign out
├── CustomViews/
│   ├── MovingShapesView.swift           # Animated background
│   └── SignInWithAppleButtonViewRepresentable.swift
└── Models/
    └── AuthError.swift
```

---

## 🔑 How Redux Works Here

```swift
// 1. Single store injected as EnvironmentObject
let store = Store(initialState: AppState(), reducer: Reducer.appReducer())

// 2. UI sends actions
store.send(.emailLogin(.signIn(email, password)))
store.send(.appleLogin(.signIn))
store.send(.signOut(.signOutAndDelete))

// 3. Reducer maps action → AnyPublisher → state change
return authService.signInWithEmail(email: email, password: password)
    .map { result in
        switch result {
        case .success: return { state in state.isLoggedIn = true }
        case .failure(let error): return { state in state.loginError = error.localizedDescription }
        }
    }
    .eraseToAnyPublisher()

// 4. View reacts to state automatically
.navigationDestination(isPresented: Binding(get: { store.state.isLoggedIn }, set: { _ in })) {
    HomeView()
}
```

---

## 🚀 Getting Started

### Requirements
- Xcode 15+
- iOS 16.0+ device (Apple Sign In requires real device)
- Firebase project with Auth enabled (Email, Apple, Google, Facebook)
- Swift 5.9+

---

### 1. Clone the repo

```bash
git clone https://github.com/BaidetskyiYurii/ReduxLogin.git
cd ReduxLogin
open ReduxLogin/ReduxLogin.xcodeproj
```

---

### 2. Add `GoogleService-Info.plist`

This file must be added manually. It contains your Firebase project credentials (API key, project ID, client ID, etc.).

1. Go to [Firebase Console](https://console.firebase.google.com) → your project → **Project Settings**
2. Under **Your apps**, select your iOS app
3. Click **Download GoogleService-Info.plist**
4. In Xcode, right-click the `ReduxLogin/ReduxLogin/` folder → **Add Files to "ReduxLogin"**
5. Select the downloaded file — make sure **"Add to target: ReduxLogin"** ✅ is checked

---

### 3. Fill in your keys in `Info.plist`

`Info.plist` is already included in the project. Open `ReduxLogin/ReduxLogin/Info.plist` and replace the following fields with your own values:

| Field | Where to get it |
|-------|----------------|
| `FacebookAppID` | [Facebook Developer Console](https://developers.facebook.com) → Your App → **Settings → Basic → App ID** |
| `FacebookClientToken` | Facebook Developer Console → Your App → **Settings → Advanced → Client Token** |
| `CFBundleURLSchemes` → `fb...` entry | Prefix `fb` + your Facebook App ID (e.g. `fb1234567890`) |
| `CFBundleURLSchemes` → `com.googleusercontent...` entry | Open your `GoogleService-Info.plist` → copy the value of `REVERSED_CLIENT_ID` |

---

### 4. Set the `ENCRYPTION_KEY` environment variable

The app uses AES-GCM encryption for sensitive config data. The key is loaded at runtime from an environment variable — it is never stored in code or files.

1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select **Run → Arguments → Environment Variables**
3. Click **+** and add:

| Name | Value |
|------|-------|
| `ENCRYPTION_KEY` | any strong string of your choice (e.g. `my-super-secret-key-32chars!!`) |

---

### 5. Build & Run

Select a real device (Apple Sign In does not work on Simulator) and press **Run**.

---

## 💡 Why This Project

Most auth demos stop at "call Firebase and update a boolean." This one shows how to build auth properly — with a unidirectional data flow (Redux), async operations piped through Combine publishers, and security practices that match what enterprise iOS apps actually need. The OWASP implementation is not decorative — Keychain storage, cryptographic nonces, and AES-GCM encryption are all functional and reflect real production patterns.

---

## 👨‍💻 Author

**Yurii Baidetskyi** — iOS Engineer  
[LinkedIn](https://linkedin.com/in/yuriibaidetskyi) · [GitHub](https://github.com/BaidetskyiYurii)

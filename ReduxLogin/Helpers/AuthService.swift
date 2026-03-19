//
//  AuthService.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 21.07.2024.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import FacebookLogin
import CryptoKit
import FirebaseCore
import Combine

final class AuthService: NSObject {
    private var appleLoginSubject: PassthroughSubject<Result<User, Error>, Never>?
    private let loginManager = LoginManager()
    private let keychainManager = KeychainManager.shared
    private var currentNonce: String?
    
    // Subject to publish the result of log out and delete operations
    private let logOutAndDeleteSubject = PassthroughSubject<Result<Void, Error>, Never>()
    private let logOutSubject = PassthroughSubject<Result<Void, Error>, Never>()
    
    func createUserWithEmail(email: String, password: String) -> AnyPublisher<Result<User, Error>, Never> {
        let emailSignUpSubject = PassthroughSubject<Result<User, Error>, Never>()
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self else { return }
            
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
                emailSignUpSubject.send(.failure(error))
            } else if let user = authResult?.user {
                print("User created successfully: \(user.email ?? "No Email")")
                
                // Fetch and print the token
                user.getIDToken { token, error in
                    if let error = error {
                        print("Error fetching token: \(error.localizedDescription)")
                    } else if let token = token {
                        print("User token: \(token)")
                        
                        // Save credentials and token to Keychain
                        let emailSaved = self.keychainManager.save(account: .userEmail, value: email)
                        let passwordSaved = self.keychainManager.save(account: .userPassword, value: password)
                        let tokenSaved = self.keychainManager.save(account: .userToken, value: token)
                        
                        if emailSaved && passwordSaved && tokenSaved {
                            print("Credentials and token saved to Keychain successfully.")
                        } else {
                            print("Failed to save credentials or token to Keychain.")
                        }
                    }
                }
                
                emailSignUpSubject.send(.success(user))
            }
        }
        
        return emailSignUpSubject.eraseToAnyPublisher()
    }
    
    func signInWithEmail(email: String, password: String) -> AnyPublisher<Result<User, Error>, Never> {
        let emailSignInSubject = PassthroughSubject<Result<User, Error>, Never>()
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self else { return }
            
            if let error = error {
                print("Error signing in with email: \(error.localizedDescription)")
                emailSignInSubject.send(.failure(error))
            } else if let user = authResult?.user {
                print("User signed in successfully: \(user.email ?? "No Email")")
                
                // Fetch and print the token
                user.getIDToken { token, error in
                    if let error = error {
                        print("Error fetching token: \(error.localizedDescription)")
                    } else if let token = token {
                        // Save credentials and token to Keychain
                        #warning("Keychain used here")
                        let emailSaved = self.keychainManager.save(account: .userEmail, value: email)
                        let passwordSaved = self.keychainManager.save(account: .userPassword, value: password)
                        let tokenSaved = self.keychainManager.save(account: .userToken, value: token)
                        
                        if emailSaved && passwordSaved && tokenSaved {
                            print("Credentials and token saved to Keychain successfully.")
                        } else {
                            print("Failed to save credentials or token to Keychain.")
                        }
                    }
                }
                
                emailSignInSubject.send(.success(user))
            }
        }
        
        return emailSignInSubject.eraseToAnyPublisher()
    }
    
    func logOutAndDeleteAccount() -> AnyPublisher<Result<Void, Error>, Never> {
        let firebaseAuth = Auth.auth()
        guard let user = firebaseAuth.currentUser else {
            logOutAndDeleteSubject.send(.failure(AuthError.noCurrentUser))
            return logOutAndDeleteSubject.eraseToAnyPublisher()
        }
        
        // Sign out first
        do {
            if keychainManager.deleteAllCredentials() {
                try firebaseAuth.signOut()
                print("Logged out successfully")
            } else {
                logOutAndDeleteSubject.send(.failure(AuthError.failedToClearCredentials))
            }
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
            logOutAndDeleteSubject.send(.failure(signOutError))
            return logOutAndDeleteSubject.eraseToAnyPublisher()
        }
        
        // Delete account after logging out
        user.delete { error in
            if let error = error {
                print("Error deleting account: \(error.localizedDescription)")
                self.logOutAndDeleteSubject.send(.failure(error))
            } else {
                print("Account deleted successfully")
                self.logOutAndDeleteSubject.send(.success(()))
            }
        }
        
        return logOutAndDeleteSubject.eraseToAnyPublisher()
    }
    
    func logOut() -> AnyPublisher<Result<Void, Error>, Never> {
        let firebaseAuth = Auth.auth()
        
        // Attempt to sign out and post result
        do {
            if keychainManager.deleteAllCredentials() {
                try firebaseAuth.signOut()
                logOutSubject.send(.success(())) // Send success if signout is successful
            } else {
                logOutSubject.send(.failure(AuthError.failedToClearCredentials))
            }
        } catch {
            logOutSubject.send(.failure(error))
        }
        
        return logOutSubject.eraseToAnyPublisher()
    }
    
    func loginWithApple() -> AnyPublisher<Result<User, Error>, Never> {
        let nonce = randomNonceString()
        currentNonce = nonce
        let subject = PassthroughSubject<Result<User, Error>, Never>()
        self.appleLoginSubject = subject
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
        
        return subject.eraseToAnyPublisher()
    }
    
    func loginWithGoogle() -> AnyPublisher<Result<User, Error>, Never> {
        let subject = PassthroughSubject<Result<User, Error>, Never>()
        
        guard let encryptedClientID = FirebaseApp.app()?.options.clientID else {
            subject.send(.failure(AuthError.clientIDNotFound))
            return subject.eraseToAnyPublisher()
        }
        
        #warning("AESEncryption used here")
        guard let clientID = getDecryptedClientID(encryptedClientID) else {
            subject.send(.failure(AuthError.clientIDNotFound))
            return subject.eraseToAnyPublisher()
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: ApplicationUtility.rootViewController) { user, error in
            if let error = error {
                subject.send(.failure(error))
                return
            }
            
            guard let user = user?.user,
                  let idToken = user.idToken else {
                subject.send(.failure(AuthError.tokenNotFound))
                return
            }
            
            let accessToken = user.accessToken
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    subject.send(.failure(error))
                } else if let user = authResult?.user {
                    subject.send(.success(user))
                }
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    func loginWithFacebook() -> AnyPublisher<Result<User, Error>, Never> {
        let subject = PassthroughSubject<Result<User, Error>, Never>()
        
        guard let topVC = ApplicationUtility.topViewController else {
            subject.send(.failure(AuthError.topViewControllerNotFound))
            return subject.eraseToAnyPublisher()
        }
        
        loginManager.logIn(permissions: ["public_profile", "email"], from: topVC) { result, error in
            if let error = error {
                subject.send(.failure(error))
                return
            }
            
            guard let result = result, !result.isCancelled, let tokenString = result.token?.tokenString else {
                subject.send(.failure(AuthError.loginCancelled))
                return
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    subject.send(.failure(error))
                } else if let user = authResult?.user {
                    subject.send(.success(user))
                }
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Helper Functions
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    // Cryptographic Hash Function
    @available(iOS 13, *)
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func saveEncryptedClientID(clientID: String) {
        // Generate a symmetric encryption key (you should save this securely and keep it safe)
        guard let encryptionKey = ProcessInfo.processInfo.environment["ENCRYPTION_KEY"] else {
            print("Encryption key not found in environment variables")
            return
        }
        
        // Encrypt the clientID
        let encryption = AESEncryption(keyString: encryptionKey)
        do {
            let encryptedData = try encryption.encrypt(data: Data(clientID.utf8))
            
            // Save encrypted clientID to Info.plist (you can store it as a base64 encoded string)
            let encryptedClientID = encryptedData.base64EncodedString()
        } catch {
            print("Failed to encrypt clientID: \(error)")
        }
    }
    
    func getDecryptedClientID(_ encryptedClientIDString: String) -> String? {
        // Retrieve encrypted clientID from UserDefaults (or from wherever it is stored)
        guard let encryptedData = Data(base64Encoded: encryptedClientIDString) else {
            print("No encrypted clientID found")
            return nil
        }
        
        guard let encryptionKey = ProcessInfo.processInfo.environment["ENCRYPTION_KEY"] else {
               print("Encryption key not found in environment variables")
               return nil
           }
        
        let encryption = AESEncryption(keyString: encryptionKey)
        do {
            let decryptedData = try encryption.decrypt(data: encryptedData)
            let decryptedClientID = String(data: decryptedData, encoding: .utf8)
            return decryptedClientID
        } catch {
            print("Failed to decrypt clientID: \(error)")
            return nil
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                appleLoginSubject?.send(.failure(AuthError.tokenNotFound))
                return
            }
            
            // Use the currentNonce that was originally generated
            guard let currentNonce = currentNonce else {
                appleLoginSubject?.send(.failure(AuthError.tokenNotFound))
                return
            }
            
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: currentNonce,
                                                           fullName: appleIDCredential.fullName)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.appleLoginSubject?.send(.failure(error))
                } else if let user = authResult?.user {
                    self.appleLoginSubject?.send(.success(user))
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleLoginSubject?.send(.failure(error))
    }
}

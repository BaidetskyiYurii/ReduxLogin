//
//  AppReducer.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 14.07.2024.
//

import Foundation

extension Reducer where State == AppState, Action == AppAction {
    static func appReducer() -> Reducer {
        let authService = AuthService()
        
        return Reducer { state, action in
            switch action {
            case .appleLogin:
                return authService.loginWithApple()
                    .map { result in
                        switch result {
                        case .success:
                            return { state in state.isLoggedIn = true }
                        case .failure(let error):
                            return { state in state.loginError = error.localizedDescription }
                        }
                    }
                    .eraseToAnyPublisher()
            case .googleLogin:
                return authService.loginWithGoogle()
                    .map { result in
                        switch result {
                        case .success:
                            return { state in state.isLoggedIn = true }
                        case .failure(let error):
                            return { state in state.loginError = error.localizedDescription }
                        }
                    }
                    .eraseToAnyPublisher()
                
            case .facebookLogin:
                return authService.loginWithFacebook()
                    .map { result in
                        switch result {
                        case .success:
                            return { state in state.isLoggedIn = true }
                        case .failure(let error):
                            return { state in state.loginError = error.localizedDescription }
                        }
                    }
                    .eraseToAnyPublisher()
                
            case .clearLoginError:
                return Reducer.sync { state in
                    state.loginError = nil
                }
            case .signOut(let action):
                switch action {
                case .signOutAndDelete:
                    return authService.logOutAndDeleteAccount()
                        .map { result in
                            switch result {
                            case .success:
                                return { state in
                                    state.isLoggedOut = true
                                    state.isLoggedIn = false
                                }
                            case .failure(let error):
                                return { state in state.loginError = error.localizedDescription }
                            }
                        }
                        .eraseToAnyPublisher()
                case .signOut:
                    return authService.logOut()
                        .map { result in
                            print("Received result: \(result)") // Add logging to see the result
                            switch result {
                            case .success:
                                return { state in
                                    state.isLoggedOut = true
                                    state.isLoggedIn = false
                                }
                            case .failure(let error):
                                return { state in state.loginError = error.localizedDescription }
                            }
                        }
                        .eraseToAnyPublisher()
                case .back:
                    return Reducer.sync { state in
                        state.isLoggedOut = false
                    }
                }
            case .emailLogin(let action):
                switch action {
                case .signIn(let email, let password):
                    return authService.signInWithEmail(email: email, password: password)
                        .map { result in
                            switch result {
                            case .success:
                                return { state in state.isLoggedIn = true }
                            case .failure(let error):
                                return { state in state.loginError = error.localizedDescription }
                            }
                        }
                        .eraseToAnyPublisher()
                case .signUp(let email, let password):
                    return authService.createUserWithEmail(email: email, password: password)
                        .map { result in
                            switch result {
                            case .success:
                                return { state in state.isLoggedIn = true }
                            case .failure(let error):
                                return { state in state.loginError = error.localizedDescription }
                            }
                        }
                        .eraseToAnyPublisher()
                }
            }
        }
    }
}

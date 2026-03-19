//
//  AppAction.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 14.07.2024.
//

import Foundation

enum AppAction {
    case emailLogin(EmailLoginAction)
    case appleLogin(AppleLoginAction)
    case googleLogin(GoogleLoginAction)
    case facebookLogin(FacebookLoginAction)
    case clearLoginError
    case signOut(SignOutAction)
}

enum EmailLoginAction {
    case signIn(String, String)
    case signUp(String, String)
}

enum AppleLoginAction {
    case signIn
}

enum GoogleLoginAction {
    case signIn
}

enum FacebookLoginAction {
    case signIn
}

enum SignOutAction {
    case signOutAndDelete
    case signOut
    case back
}

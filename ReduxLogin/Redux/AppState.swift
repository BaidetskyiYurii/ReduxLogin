//
//  AppState.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 14.07.2024.
//

import Foundation

struct AppState {
    var isLoggedIn: Bool
    var isLoggedOut: Bool
    var loginError: String?
    
    init(isLoggedIn: Bool = false,
         isLoggedOut: Bool = false,
         loginError: String? = nil) {
        self.isLoggedIn = KeychainManager.shared.hasAllCredentials()
        self.isLoggedOut = isLoggedOut
        self.loginError = loginError
    }
}

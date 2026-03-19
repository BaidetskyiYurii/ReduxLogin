//
//  AuthError.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 21.07.2024.
//

import Foundation

enum AuthError: Error {
    case clientIDNotFound
    case tokenNotFound
    case topViewControllerNotFound
    case loginCancelled
    case noCurrentUser
    case failedToClearCredentials
}

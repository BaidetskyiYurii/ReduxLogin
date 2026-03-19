//
//  KeychainManager.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 27.01.2025.
//

import Security
import Foundation

enum KeychainManagerService: String {
    case service = "com.volpis.ReduxLogin"
}

enum KeychainManagerKeys: String, CaseIterable {
    case userEmail = "user_email"
    case userPassword = "user_password"
    case userToken = "user_token"
}

final class KeychainManager: ObservableObject {
    
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Save to Keychain
    func save(service: KeychainManagerService = .service,
              account: KeychainManagerKeys,
              value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: account.rawValue,
            kSecValueData as String: data
        ]
        
        // Delete existing item if it exists
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Retrieve from Keychain
    func retrieve(service: KeychainManagerService = .service,
                  account: KeychainManagerKeys) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: account.rawValue,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let data = item as? Data else {
            print("Error retrieving item: \(status)")
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Delete from Keychain
    func delete(service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // New function to check if all required values are present
    func hasAllCredentials(service: KeychainManagerService = .service) -> Bool {
        let email = retrieve(service: service, account: .userEmail)
        let password = retrieve(service: service, account: .userPassword)
        let token = retrieve(service: service, account: .userToken)
        
        return email != nil && password != nil && token != nil
    }
    
    // New function to delete all credentials
    func deleteAllCredentials(service: KeychainManagerService = .service) -> Bool {
        let accounts = KeychainManagerKeys.allCases
        var success = true
        
        for account in accounts {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service.rawValue,
                kSecAttrAccount as String: account.rawValue
            ]
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess && status != errSecItemNotFound {
                success = false
                print("Failed to delete \(account): \(status)")
            }
        }
        return success
    }
}

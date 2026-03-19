//
//  AESEncryption.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 28.01.2025.
//

import Foundation
import CryptoKit

struct AESEncryption {
    private let key: SymmetricKey
    
    init(keyString: String) {
        // Derive a 32-byte key from the keyString using SHA-256
        let keyData = SHA256.hash(data: Data(keyString.utf8))
        self.key = SymmetricKey(data: keyData)
    }
    
    func encrypt(data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decrypt(data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

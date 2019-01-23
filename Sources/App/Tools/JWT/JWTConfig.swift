//
//  JWTConfig.swift
//  App
//
//  Created by Timur Shafigullin on 22/01/2019.
//

import JWT

enum JWTConfig {
    
    // MARK: - Type Properties
    
    static let signerKey = "ROOM_DEBTS_JWT_API_SIGNER_KEY"
    static let header = JWTHeader(alg: "HS256", typ: "JWT")
    static let signer = JWTSigner.hs256(key: JWTConfig.signerKey)
    static let expirationTime = 60 * 60 * 24 * 7
}

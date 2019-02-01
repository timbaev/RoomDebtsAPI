//
//  JWTErrors.swift
//  App
//
//  Created by Timur Shafigullin on 22/01/2019.
//

import Foundation
import JWT

extension JWTError {
    
    // MARK: - Type Properties
    
    static let payloadCreation = JWTError(identifier: "TokenHelpers.createPayload", reason: "User ID not found")
    static let createJWT = JWTError(identifier: "TokenHelpers.createJWT", reason: "Error getting token string")
    static let verificationFailed = JWTError(identifier: "TokenHelpers.verifyToken", reason: "JWT verification failed")
}

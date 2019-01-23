//
//  JWTErrors.swift
//  App
//
//  Created by Timur Shafigullin on 22/01/2019.
//

import Foundation

enum JWTError: CustomStringConvertible, Error {
    
    // MARK: - Enumeration Cases
    
    case signatureVerificationFailed
    case issuerVerificationFailed
    case tokenIsExpired
    case payloadCreation
    case createJWT
    case verificationFailed
    
    // MARK: - Instance Properties
    
    var description: String {
        switch self {
        case .signatureVerificationFailed:
            return "Could not verify signature"
        case .issuerVerificationFailed:
            return "Could not verify JWT issuer"
        case .tokenIsExpired:
            return "Your token is expired"
        case .payloadCreation:
            return "Error creating JWT payload"
        case .createJWT:
            return "Error creating JWT"
        case .verificationFailed:
            return "JWT verification failed"
        }
    }
}

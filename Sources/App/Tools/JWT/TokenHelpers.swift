//
//  TokenHelpers.swift
//  App
//
//  Created by Timur Shafigullin on 22/01/2019.
//

import JWT

class TokenHelpers {
    
    // MARK: - Nested Types
    
    fileprivate enum Constants {
        
        // MARK: - Type Properties
        
        static let refreshTokenLength = 40
    }
    
    // MARK: - Instance Methods
    
    fileprivate class func createPayload(from user: User) throws -> AccessTokenPayload {
        if let id = user.id {
            let payload = AccessTokenPayload(userID: id)
            
            return payload
        } else {
            throw JWTError.payloadCreation
        }
    }
    
    // MARK: -
    
    class func createAccessToken(from user: User) throws -> String {
        let payload = try TokenHelpers.createPayload(from: user)
        let header = JWTConfig.header
        let signer = JWTConfig.signer
        let jwt = JWT<AccessTokenPayload>(header: header, payload: payload)
        let tokenData = try signer.sign(jwt)
        
        if let token = String(data: tokenData, encoding: .utf8) {
            return token
        } else {
            throw JWTError.createJWT
        }
    }
    
    class func expiredDate(of token: String) throws -> Date {
        let receivedJWT = try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
        
        return receivedJWT.payload.expirationAt.value
    }

    class func verifyToken(_ token: String) throws {
        do {
            let _ = try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
        } catch {
            throw JWTError.verificationFailed
        }
    }
    
    class func getUserID(fromPayloadOf token: String) throws -> Int {
        do {
            let receivedJWT = try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
            let payload = receivedJWT.payload
            
            return payload.userID
        } catch {
            throw JWTError.verificationFailed
        }
    }
    
    class func createRefreshToken() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ... Constants.refreshTokenLength).map { _ in letters.randomElement()! })
    }
}

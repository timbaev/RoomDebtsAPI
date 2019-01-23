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
        
        static let refreshTokenLength = 37
    }
    
    // MARK: - Instance Methods
    
    class func createPayload(from user: User) throws -> Payload {
        if let id = user.id {
            let now = Date()
            let timeInterval = now.timeIntervalSince1970
            let createdAt = Int(timeInterval)
            let expiration = Int(timeInterval) + JWTConfig.expirationTime
            let expirationDate = Date(timeIntervalSince1970: TimeInterval(expiration))
            let payload = Payload(iss: "roomdebts", iat: createdAt, userID: id, exp: ExpirationClaim(value: expirationDate))
           
            return payload
        } else {
            throw JWTError.payloadCreation
        }
    }
    
    class func createJWT(from user: User) throws -> String {
        let payload = try TokenHelpers.createPayload(from: user)
        let header = JWTConfig.header
        let signer = JWTConfig.signer
        let jwt = JWT<Payload>(header: header, payload: payload)
        let tokenData = try signer.sign(jwt)
        
        if let token = String(data: tokenData, encoding: .utf8) {
            return token
        } else {
            throw JWTError.createJWT
        }
    }
    
    class func expiredDate(of token: String) throws -> Date {
        let receivedJWT = try JWT<Payload>(from: token, verifiedUsing: JWTConfig.signer)
        
        return receivedJWT.payload.exp.value
    }
    
    class func createRefreshToken() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ... Constants.refreshTokenLength).map { _ in letters.randomElement()! })
    }
    
    class func tokenIsVerified(_ token: String) throws {
        do {
            let receivedJWT = try JWT<Payload>(from: token, verifiedUsing: JWTConfig.signer)
            
            if receivedJWT.payload.iss != "roomdebts" {
                throw JWTError.issuerVerificationFailed
            }
        } catch {
            throw JWTError.verificationFailed
        }
    }
    
    class func getUserID(fromPayloadOf token: String) throws -> Int {
        do {
            let receivedJWT = try JWT<Payload>(from: token, verifiedUsing: JWTConfig.signer)
            let payload = receivedJWT.payload
            
            return payload.userID
        } catch {
            throw JWTError.verificationFailed
        }
    }
}

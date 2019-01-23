//
//  JWTPayload.swift
//  App
//
//  Created by Timur Shafigullin on 22/01/2019.
//

import JWT

struct Payload: JWTPayload {
    
    // MARK: - Instance Properties
    
    var iss: String
    var iat: Int
    var userID: Int
    var exp: ExpirationClaim
    
    // MARK: - Instance Methods
    
    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
}

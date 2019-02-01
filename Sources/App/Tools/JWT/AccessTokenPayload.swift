//
//  JWTPayload.swift
//  App
//
//  Created by Timur Shafigullin on 22/01/2019.
//

import JWT

struct AccessTokenPayload: JWTPayload {
    
    // MARK: - Instance Properties
    
    var issuer: IssuerClaim
    var issuedAt: IssuedAtClaim
    var expirationAt: ExpirationClaim
    var userID: User.ID
    
    // MARK: - Initializers
    
    init(issuer: String = "TokensTutorial",
         issuedAt: Date = Date(),
         expirationAt: Date = Date().addingTimeInterval(JWTConfig.expirationTime),
         userID: User.ID) {
        self.issuer = IssuerClaim(value: issuer)
        self.issuedAt = IssuedAtClaim(value: issuedAt)
        self.expirationAt = ExpirationClaim(value: expirationAt)
        self.userID = userID
    }
    
    // MARK: - Instance Methods
    
    func verify(using signer: JWTSigner) throws {
        try self.expirationAt.verifyNotExpired()
    }
}

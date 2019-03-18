//
//  RequestExtensions.swift
//  App
//
//  Created by Timur Shafigullin on 23/01/2019.
//

import Vapor
import JWT

extension Request {
    
    // MARK: - Instance Properties
    
    var token: String {
        if let token = self.http.headers[.authorization].first {
            return token
        } else {
            return ""
        }
    }

    var userID: User.ID? {
        return try? TokenHelpers.getUserID(fromPayloadOf: self.token)
    }
    
    // MARK: - Instance Methods
    
    func authorizedUser() throws -> Future<User> {
        let userID = try TokenHelpers.getUserID(fromPayloadOf: self.token)
        
        return User.find(userID, on: self).unwrap(or: Abort(.unauthorized, reason: "Authorized user not found"))
    }

    func requiredUserID() throws -> User.ID {
        guard let userID = self.userID else {
            throw Abort(.unauthorized)
        }

        return userID
    }
}

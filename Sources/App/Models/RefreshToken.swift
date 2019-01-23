//
//  RefreshToken.swift
//  App
//
//  Created by Timur Shafigullin on 23/01/2019.
//

import Vapor
import FluentPostgreSQL

final class RefreshToken: PostgreSQLModel {
    
    // MARK: - Nested Types
    
    fileprivate enum Constants {
        
        // MARK: - Type Properties
        
        static let refreshTokenTime: TimeInterval = 60 * 24 * 60 * 60
    }
    
    // MARK: - Instance Properties
    
    var id: Int?
    var token: String
    var expiredAt: Date
    var userID: User.ID
    
    // MARK: - Initializers
    
    init(id: Int? = nil, token: String, expiredAt: Date = Date().addingTimeInterval(Constants.refreshTokenTime), userID: User.ID) {
        self.id = id
        self.token = token
        self.expiredAt = expiredAt
        self.userID = userID
    }
    
    // MARK: - Instance Methods
    
    func updateExpiredDate() {
        self.expiredAt = Date().addingTimeInterval(Constants.refreshTokenTime)
    }
}

// MARK: -

extension RefreshToken {
    
    // MARK: - Instance Properties
    
    var user: Parent<RefreshToken, User> {
        return self.parent(\.userID)
    }
}

// MARK: - Content

extension RefreshToken: Content { }

// MARK: - PostgreSQLMigration

extension RefreshToken: PostgreSQLMigration { }

// MARK: - Parameter

extension RefreshToken: Parameter { }

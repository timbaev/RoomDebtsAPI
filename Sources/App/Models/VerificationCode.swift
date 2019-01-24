//
//  Code.swift
//  App
//
//  Created by Timur Shafigullin on 24/01/2019.
//

import Vapor
import FluentPostgreSQL

final class VerificationCode: PostgreSQLModel {
    
    // MARK: - Nested Types
    
    fileprivate enum Constants {
        
        // MARK: - Type Properties
        
        static let codeTime: TimeInterval = 60 * 3
    }
    
    
    // MARK: - Instance Properties
    
    var id: Int?
    var expiredAt: Date
    var code: String
    var userID: User.ID
    
    // MARK: - Initializers
    
    init(id: Int? = nil, expiredAt: Date = Date().addingTimeInterval(Constants.codeTime), code: String = String(Int.random(in: 1000 ... 9999)), userID: User.ID) {
        self.id = id
        self.expiredAt = expiredAt
        self.code = code
        self.userID = userID
    }
    
    // MARK: - Instance Methods
    
    func update() {
        self.code = String(Int.random(in: 1000 ... 9999))
        self.expiredAt = Date().addingTimeInterval(Constants.codeTime)
    }
}

// MARK: - Content

extension VerificationCode: Content { }

// MARK: - PostgreSQLMigration

extension VerificationCode: PostgreSQLMigration { }

// MARK: - Parameter

extension VerificationCode: Parameter { }

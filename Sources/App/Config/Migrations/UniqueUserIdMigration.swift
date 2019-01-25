//
//  UniqueUserIdMigration.swift
//  App
//
//  Created by Timur Shafigullin on 25/01/2019.
//

import Vapor
import FluentPostgreSQL

struct UniqueUserIdMigration: PostgreSQLMigration {
    
    // MARK: - Instance Properties
    
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(VerificationCode.self, on: conn) { builder in
            builder.unique(on: \.userID)
        }
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(VerificationCode.self, on: conn, closure: { builder in
            builder.deleteUnique(from: \.userID)
        })
    }
}

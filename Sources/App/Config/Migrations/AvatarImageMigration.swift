//
//  AvatarImageMigration.swift
//  App
//
//  Created by Timur Shafigullin on 01/02/2019.
//

import Vapor
import FluentPostgreSQL

struct AvatarImageMigration: PostgreSQLMigration {
 
    // MARK: - Instance Properties
    
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(User.self, on: conn) { builder in
            builder.field(for: \.imageID)
        }
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(User.self, on: conn, closure: { builder in
            builder.deleteField(for: \.imageID)
        })
    }
}

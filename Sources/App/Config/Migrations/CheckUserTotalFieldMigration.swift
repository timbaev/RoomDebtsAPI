//
//  CheckUserTotalFieldMigration.swift
//  App
//
//  Created by Timur Shafigullin on 02/06/2019.
//

import Vapor
import FluentPostgreSQL

struct CheckUserTotalFieldMigration: Migration {

    // MARK: - Typealias

    typealias Database = PostgreSQLDatabase

    // MARK: - Type Methods

    static func prepare(on connection: Database.Connection) -> Future<Void> {
        return Database.update(CheckUser.self, on: connection, closure: { builder in
            builder.field(for: \.total)
            builder.field(for: \.reviewDate)
        })
    }

    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.update(CheckUser.self, on: connection, closure: { builder in
            builder.deleteField(for: \.total)
            builder.deleteField(for: \.reviewDate)
        })
    }
}

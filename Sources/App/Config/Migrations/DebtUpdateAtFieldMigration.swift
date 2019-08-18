//
//  DebtUpdateAtFieldMigration.swift
//  App
//
//  Created by Timur Shafigullin on 18/08/2019.
//

import Vapor
import FluentPostgreSQL

struct DebtUpdateAtFieldMigration: Migration {

    // MARK: - Nested Types

    typealias Database = PostgreSQLDatabase

    // MARK: - Type Methods

    static func prepare(on connection: Database.Connection) -> Future<Void> {
        return Database.update(Debt.self, on: connection, closure: { builder in
            builder.field(for: \.updatedAt)
        })
    }

    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.update(Debt.self, on: connection, closure: { builder in
            builder.deleteField(for: \.updatedAt)
        })
    }
}

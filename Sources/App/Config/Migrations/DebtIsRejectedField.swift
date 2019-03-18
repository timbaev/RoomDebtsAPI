//
//  DebtIsRejectedField.swift
//  App
//
//  Created by Timur Shafigullin on 18/03/2019.
//

import Vapor
import FluentPostgreSQL

struct DebtIsRejectedField: Migration {

    // MARK: - Typealias

    typealias Database = PostgreSQLDatabase

    // MARK: - Type Methods

    static func prepare(on connection: Database.Connection) -> Future<Void> {
        return Database.update(Debt.self, on: connection, closure: { builder in
            builder.field(for: \.isRejected, type: .bool, .default(.literal(.boolean(.false))))
        })
    }

    static func revert(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Debt.self, on: connection, closure: { builder in
            builder.deleteField(for: \.isRejected)
        })
    }
}

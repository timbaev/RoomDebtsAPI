//
//  CheckDataFieldsMogration.swift
//  App
//
//  Created by Timur Shafigullin on 07/04/2019.
//

import Vapor
import FluentPostgreSQL

struct CheckDataFieldsMogration: Migration {

    // MARK: - Typealias

    typealias Database = PostgreSQLDatabase

    // MARK: - Type Methods

    static func prepare(on connection: Database.Connection) -> Future<Void> {
        return Database.update(Check.self, on: connection, closure: { builder in
            builder.field(for: \.fd)
            builder.field(for: \.fn)
            builder.field(for: \.fiscalSign)
        })
    }

    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.update(Check.self, on: connection, closure: { builder in
            builder.deleteField(for: \.fd)
            builder.deleteField(for: \.fn)
            builder.deleteField(for: \.fiscalSign)
        })
    }
}

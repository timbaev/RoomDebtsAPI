//
//  DebtToConversationRelationMigration.swift
//  App
//
//  Created by Timur Shafigullin on 20/03/2019.
//

import Vapor
import FluentPostgreSQL

struct DebtToConversationRelationMigration: Migration {

    // MARK: - Typealias

    typealias Database = PostgreSQLDatabase

    // MARK: - Type Methods

    static func prepare(on connection: Database.Connection) -> Future<Void> {
        return Database.update(Debt.self, on: connection, closure: { builder in
            builder.reference(from: \.conversationID, to: \Conversation.id)
        })
    }

    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.update(Debt.self, on: connection, closure: { builder in
            builder.deleteReference(from: \.conversationID, to: \Conversation.id)
        })
    }
}

//
//  ConversationRejectStatusField.swift
//  App
//
//  Created by Timur Shafigullin on 20/03/2019.
//

import Vapor
import FluentPostgreSQL

struct ConversationRejectStatusField: Migration {

    // MARK: - Typealias

    typealias Database = PostgreSQLDatabase

    // MARK: - Type Methods

    static func prepare(on connection: Database.Connection) -> Future<Void> {
        return Database.update(Conversation.self, on: connection, closure: { builder in
            builder.field(for: \.rejectStatus, type: .text)
        })
    }

    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.update(Conversation.self, on: connection, closure: { builder in
            builder.deleteField(for: \.rejectStatus)
        })
    }
}

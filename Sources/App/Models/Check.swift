//
//  Check.swift
//  App
//
//  Created by Timur Shafigullin on 06/04/2019.
//

import Vapor
import FluentPostgreSQL

final class Check: Object {

    // MARK: - Nested Types

    enum Status: String, PostgreSQLEnum, Content, PostgreSQLMigration {

        // MARK: - Enumeration Cases

        case accepted
        case calculated
        case notCalculated
        case rejected
    }

    // MARK: - Instance Properties

    var id: Int?
    var date: Date
    var store: String?
    var totalSum: Double
    var address: String
    var status: Status
    var creatorID: User.ID
    var imageID: FileRecord.ID?
}

// MARK: -

extension Check {

    // MARK: - Instance Properties

    var products: Siblings<Check, Product, CheckProduct> {
        return self.siblings()
    }

    var users: Siblings<Check, User, CheckUser> {
        return self.siblings()
    }

    var creator: Parent<Check, User> {
        return self.parent(\.creatorID)
    }

    var image: Parent<Check, FileRecord>? {
        return self.parent(\.imageID)
    }
}

// MARK: - Migration

extension Check {

    // MARK: - Type Methods

    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(Check.self, on: connection) { builder in
            try self.addProperties(to: builder)

            builder.reference(from: \.creatorID, to: \User.id)
            builder.reference(from: \.imageID, to: \FileRecord.id, onDelete: .cascade)
        }
    }
}

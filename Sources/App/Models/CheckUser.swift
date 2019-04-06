//
//  CheckUser.swift
//  App
//
//  Created by Timur Shafigullin on 06/04/2019.
//

import Vapor
import FluentPostgreSQL

struct CheckUser: PostgreSQLPivot {

    // MARK: - Nested Types

    enum Status: String, PostgreSQLEnum, Content, PostgreSQLMigration {

        // MARK: - Enumeration Cases

        case accepted
        case review
        case rejected
    }

    // MARK: - Typealiases

    typealias Left = Check
    typealias Right = User

    // MARK: - Type Properties

    static var leftIDKey: LeftIDKey = \.checkID
    static var rightIDKey: RightIDKey = \.userID

    // MARK: - Instance Properties

    var id: Int?
    var checkID: Check.ID
    var userID: User.ID
    var status: Status
    var comment: String?
}

// MARK: -

extension CheckUser {

    // MARK: - Instance Properties

    var products: Siblings<CheckUser, Product, ProductCheckUser> {
        return self.siblings()
    }
}

// MARK: - ModifiablePivot

extension CheckUser: ModifiablePivot {

    // MARK: - Initializers

    init(_ check: Check, _ user: User) throws {
        self.checkID = try check.requireID()
        self.userID = try user.requireID()
        self.status = .review
    }
}

// MARK: - Migration

extension CheckUser: Migration {

    // MARK: - Type Methods

    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: conn, closure: { builder in
            try self.addProperties(to: builder)
            
            builder.reference(from: \.checkID, to: \Check.id, onDelete: .cascade)
            builder.reference(from: \.userID, to: \User.id, onDelete: .cascade)
        })
    }
}

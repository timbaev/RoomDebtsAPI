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

    // MARK: -

    struct QRCodeForm: Content {

        // MARK: - Instance Properties

        let date: String
        let sum: Int
        let fiscalSign: Int
        let fd: Int
        let n: Int
        let fn: String
    }

    struct StoreForm: Content {

        // MARK: - Instance Properties

        let store: String
    }

    // MARK: -

    struct Form: Content {

        // MARK: - Instance Properties

        let id: Int?
        let date: Date
        let store: String
        let totalSum: Double
        let address: String
        let status: String
        let creator: User.PublicForm
        let imageURL: URL?

        init(check: Check, creator: User) {
            self.id = check.id
            self.date = check.date
            self.store = check.store
            self.totalSum = check.totalSum
            self.address = check.address
            self.status = check.status.rawValue
            self.creator = User.PublicForm(user: creator)

            if let imageID = check.imageID {
                self.imageURL = FileRecord.publicURL(withID: imageID)
            } else {
                self.imageURL = nil
            }
        }
    }

    // MARK: - Instance Properties

    var id: Int?
    var date: Date
    var store: String
    var totalSum: Double
    var address: String
    var status: Status

    var fn: String
    var fd: Int
    var fiscalSign: Int

    var creatorID: User.ID
    var imageID: FileRecord.ID?

    // MARK: - Initializers

    init(receipt: Receipt, creatorID: User.ID, imageID: FileRecord.ID? = nil) {
        self.date = receipt.dateTime
        self.store = receipt.user ?? "Unknown Store"
        self.totalSum = Double(receipt.totalSum) / 100
        self.address = receipt.retailPlaceAddress
        self.status = .notCalculated
        self.creatorID = creatorID
        self.imageID = imageID
        self.fn = receipt.fiscalDriveNumber
        self.fd = receipt.fiscalDocumentNumber
        self.fiscalSign = receipt.fiscalSign
    }
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

extension Future where T: Check {

    // MARK: - Instance Methods

    func toForm(on request: Request) -> Future<Check.Form> {
        return self.flatMap(to: Check.Form.self, { check in
            return check.creator.get(on: request).map { creator in
                return Check.Form(check: check, creator: creator)
            }
        })
    }
}

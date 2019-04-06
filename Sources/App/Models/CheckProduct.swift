//
//  CheckProduct.swift
//  App
//
//  Created by Timur Shafigullin on 06/04/2019.
//

import Vapor
import FluentPostgreSQL

struct CheckProduct: PostgreSQLPivot {

    // MARK: - Typealiases

    typealias Left = Check
    typealias Right = Product

    // MARK: - Type Properties

    static var leftIDKey: LeftIDKey = \.checkID
    static var rightIDKey: RightIDKey = \.productID

    // MARK: - Instance Properties

    var id: Int?
    var checkID: Check.ID
    var productID: Product.ID
}

// MARK: - ModifiablePivot

extension CheckProduct: ModifiablePivot {

    // MARK: - Initializers

    init(_ check: Check, _ product: Product) throws {
        self.checkID = try check.requireID()
        self.productID = try product.requireID()
    }
}

// MARK: - Migration

extension CheckProduct: Migration {

    // MARK: - Type Methods

    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: conn, closure: { builder in
            try self.addProperties(to: builder)
            builder.reference(from: \.checkID, to: \Check.id, onDelete: .cascade)
            builder.reference(from: \.productID, to: \Product.id, onDelete: .cascade)
        })
    }
}

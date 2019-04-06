//
//  ProductCheckUser.swift
//  App
//
//  Created by Timur Shafigullin on 06/04/2019.
//

import Vapor
import FluentPostgreSQL

struct ProductCheckUser: PostgreSQLPivot {

    // MARK: - Typealiases

    typealias Left = Product
    typealias Right = CheckUser

    // MARK: - Type Properties

    static var leftIDKey: LeftIDKey = \.productID
    static var rightIDKey: RightIDKey = \.checkUserID

    // MARK: - Instance Properties

    var id: Int?
    var productID: Product.ID
    var checkUserID: CheckUser.ID
}

// MARK: - ModifiablePivot

extension ProductCheckUser: ModifiablePivot {

    // MARK: - Initializers

    init(_ product: Product, _ checkUser: CheckUser) throws {
        self.productID = try product.requireID()
        self.checkUserID = try checkUser.requireID()
    }
}

// MARK: - Migration

extension ProductCheckUser: Migration {

    // MARK: - Type Methods

    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: conn, closure: { builder in
            try self.addProperties(to: builder)
            builder.reference(from: \.productID, to: \Product.id, onDelete: .cascade)
            builder.reference(from: \.checkUserID, to: \CheckUser.id, onDelete: .cascade)
        })
    }
}

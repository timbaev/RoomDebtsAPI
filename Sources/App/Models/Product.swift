//
//  Product.swift
//  App
//
//  Created by Timur Shafigullin on 06/04/2019.
//

import Vapor
import FluentPostgreSQL

final class Product: Object {

    // MARK: - Nested Types

    struct Form: Content {

        // MARK: - Instance Properties

        let id: Int?
        let quantity: Double
        let sum: Double
        let name: String
        let selectedUsers: [User.PublicForm]

        // MARK: - Initializers

        init(product: Product, selectedUsers: [User.PublicForm]) {
            self.id = product.id
            self.quantity = product.quantity
            self.sum = product.sum
            self.name = product.name
            self.selectedUsers = selectedUsers
        }
    }

    // MARK: - Instance Properties

    var id: Int?
    var quantity: Double
    var sum: Double
    var price: Double
    var name: String
    var barcodeNumber: String?

    // MARK: - Initializers

    init(quantity: Double, sum: Double, price: Double, name: String, barcodeNumber: String?) {
        self.quantity = quantity
        self.sum = sum
        self.price = price
        self.name = name
        self.barcodeNumber = barcodeNumber
    }
}

// MARK: -

extension Product {

    // MARK: - Instance Properties

    var checks: Siblings<Product, Check, CheckProduct> {
        return self.siblings()
    }

    var checkUsers: Siblings<Product, CheckUser, ProductCheckUser> {
        return self.siblings()
    }
}

// MARK: - Future

extension Future where T: Product {

    // MARK: - Instance Methods

    func toForm(on request: Request) -> Future<Product.Form> {
        return self.flatMap(to: Product.Form.self, { product in
            return try product.checkUsers.query(on: request).all().flatMap { checkUsers in
                return checkUsers.map {
                    User.find($0.userID, on: request).unwrap(or: Abort(.badRequest, reason: "User with id \($0.userID) not found"))
                }.flatten(on: request).map { users in
                    return users.map { User.PublicForm(user: $0) }
                }.map { formUsers in
                    return Product.Form(product: product, selectedUsers: formUsers)
                }
            }
        })
    }
}

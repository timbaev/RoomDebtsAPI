//
//  Product.swift
//  App
//
//  Created by Timur Shafigullin on 06/04/2019.
//

import Vapor
import FluentPostgreSQL

final class Product: Object {

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

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
    var barcodeNumber: String
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

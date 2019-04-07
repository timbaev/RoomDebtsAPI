//
//  DefaultProductService.swift
//  App
//
//  Created by Timur Shafigullin on 07/04/2019.
//

import Vapor
import FluentPostgreSQL

class DefaultProductService: ProductService {

    // MARK: - Instance Methods

    func findOrCreate(on request: Request, for item: Item) -> Future<Product> {
        let sum = Double(item.sum) / 100
        let price = Double(item.price) / 100

        let result = item.name.matcheAndDelete(for: #"\*?\d{3,7}"#)
        let barcode = result.matche
        let name = result.updated.condenseWhitespace

        return Product
            .query(on: request)
            .filter(\.barcodeNumber == barcode)
            .filter(\.name == name)
            .filter(\.sum == sum)
            .filter(\.price == price)
            .filter(\.quantity == item.quantity)
            .first()
            .flatMap { product in
                if let product = product {
                    return request.future(product)
                } else {
                    return Product(quantity: item.quantity, sum: sum, price: price, name: name, barcodeNumber: barcode).save(on: request)
                }
            }
    }
}

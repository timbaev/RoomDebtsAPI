//
//  ProductService.swift
//  App
//
//  Created by Timur Shafigullin on 07/04/2019.
//

import Vapor

protocol ProductService {

    // MARK: - Instance Methods

    func findOrCreate(on request: Request, for item: Item) -> Future<Product>
}

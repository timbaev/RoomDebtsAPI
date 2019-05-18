//
//  ProductsDto.swift
//  App
//
//  Created by Timur Shafigullin on 30/04/2019.
//

import Vapor

struct ProductsDto: Content {

    // MARK: - Instance Properties

    let products: [Product.Form]
    let users: [User.PublicForm]
}


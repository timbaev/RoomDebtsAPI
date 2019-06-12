//
//  SelectedProductsDto.swift
//  App
//
//  Created by Timur Shafigullin on 02/06/2019.
//

import Vapor

struct SelectedProductsDto: Content {

    // MARK: - Instance Properties

    let selectedProducts: [Product.ID: [User.ID]]
}

//
//  CheckController.swift
//  App
//
//  Created by Timur Shafigullin on 05/04/2019.
//

import Vapor

struct CheckController {

    // MARK: - Instance Properties

    let checkService: CheckService
    let productService: ProductService

    // MARK: - Instance Methods

    func create(_ request: Request, form: Check.QRCodeForm) throws -> Future<Check.Form> {
        return try self.checkService.create(on: request, form: form)
    }

    func fetch(_ request: Request) throws -> Future<[Check.Form]> {
        return try self.checkService.fetch(on: request)
    }

    func fetchProducts(_ request: Request) throws -> Future<ProductsDto> {
        return try request.parameters.next(Check.self).flatMap { check in
            return try self.productService.fetch(on: request, for: check)
        }
    }
}

extension CheckController: RouteCollection {

    // MARK: - Instance Methods

    func boot(router: Router) throws {
        let group = router.grouped("v1/checks").grouped(Logger()).grouped(JWTMiddleware())

        group.post(Check.QRCodeForm.self, use: self.create)
        group.get(use: self.fetch)

        group.get(Check.parameter, use: self.fetchProducts)
    }
}

//
//  CheckController.swift
//  App
//
//  Created by Timur Shafigullin on 05/04/2019.
//

import Vapor

final class CheckController {

    // MARK: - Instance Properties

    let checkService: CheckService

    // MARK: - Initializers

    init(checkService: CheckService) {
        self.checkService = checkService
    }

    // MARK: - Instance Methods

    func create(_ request: Request, form: Check.QRCodeForm) throws -> Future<Check.Form> {
        return try self.checkService.create(on: request, form: form)
    }
}

extension CheckController: RouteCollection {

    // MARK: - Instance Methods

    func boot(router: Router) throws {
        let group = router.grouped("v1/checks").grouped(Logger()).grouped(JWTMiddleware())

        group.post(Check.QRCodeForm.self, use: self.create)
    }
}

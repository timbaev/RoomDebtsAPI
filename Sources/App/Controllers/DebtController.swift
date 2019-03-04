//
//  DebtController.swift
//  App
//
//  Created by Timur Shafigullin on 04/03/2019.
//

import Vapor

final class DebtController {

    // MARK: - Instance Properties

    private var debtService: DebtService

    // MARK: - Initializers

    init(debtService: DebtService) {
        self.debtService = debtService
    }

    // MARK: - Instance Methods

    func create(_ request: Request, createForm: Debt.CreateForm) throws -> Future<Debt.Form> {
        return try self.debtService.create(request: request, form: createForm)
    }
}

// MARK: - RouteCollection

extension DebtController: RouteCollection {

    // MARK: - Instance Methods

    func boot(router: Router) throws {
        let group = router.grouped("v1/debts").grouped(Logger()).grouped(JWTMiddleware())

        group.post(Debt.CreateForm.self, use: self.create)
    }
}

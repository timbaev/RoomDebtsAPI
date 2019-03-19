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

    func fetch(_ request: Request) throws -> Future<[Debt.Form]> {
        guard let conversationID = request.query[Int.self, at: "conversationID"] else {
            throw Abort(.badRequest)
        }

        return try self.debtService.fetch(request: request, conversationID: conversationID)
    }

    func accept(_ request: Request) throws -> Future<Response> {
        return try request.parameters.next(Debt.self).flatMap { debt in
            return try self.debtService.accept(on: request, debt: debt)
        }
    }

    func reject(_ request: Request) throws -> Future<HTTPStatus> {
        return try request.parameters.next(Debt.self).flatMap { debt in
            return try self.debtService.reject(on: request, debt: debt).transform(to: .noContent)
        }
    }

    func update(_ request: Request, createForm: Debt.CreateForm) throws -> Future<Debt.Form> {
        return try request.parameters.next(Debt.self).flatMap { debt in
            return try self.debtService.update(on: request, debt: debt, form: createForm)
        }
    }

    func deleteRequest(_ request: Request) throws -> Future<Debt.Form> {
        return try request.parameters.next(Debt.self).flatMap { debt in
            return try self.debtService.deleteRequest(on: request, debt: debt)
        }
    }

    func delete(_ request: Request) throws -> Future<HTTPStatus> {
        return try request.parameters.next(Debt.self).flatMap { debt in
            return try self.debtService.delete(on: request, debt: debt).transform(to: .noContent)
        }
    }

    func repayRequest(_ request: Request) throws -> Future<Debt.Form> {
        return try request.parameters.next(Debt.self).flatMap { debt in
            return try self.debtService.repayRequest(on: request, debt: debt)
        }
    }
}

// MARK: - RouteCollection

extension DebtController: RouteCollection {

    // MARK: - Instance Methods

    func boot(router: Router) throws {
        let group = router.grouped("v1/debts").grouped(Logger()).grouped(JWTMiddleware())

        group.post(Debt.CreateForm.self, use: self.create)
        group.get(use: self.fetch)

        group.post(Debt.parameter, "accept", use: self.accept)
        group.post(Debt.parameter, "reject", use: self.reject)

        group.put(Debt.CreateForm.self, at: Debt.parameter, use: self.update)

        group.delete(Debt.parameter, use: self.delete)

        group.post(Debt.parameter, "request", "delete", use: self.deleteRequest)
        group.post(Debt.parameter, "request", "repay", use: self.repayRequest)
    }
}

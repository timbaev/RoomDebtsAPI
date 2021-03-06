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

    func fetchAll(_ request: Request) throws -> Future<[Check.Form]> {
        return try self.checkService.fetch(on: request)
    }

    func fetchProducts(_ request: Request) throws -> Future<ProductsDto> {
        return try request.parameters.next(Check.self).flatMap { check in
            return try self.productService.fetch(on: request, for: check)
        }
    }

    func update(_ request: Request, form: Check.StoreForm) throws -> Future<Check.Form> {
        return try request.parameters.next(Check.self).flatMap { check in
            return try self.checkService.update(on: request, check: check, form: form)
        }
    }

    func uploadImage(_ request: Request) throws -> Future<Check.Form> {
        return try request.content.decode(File.self).flatMap { file in
            return try request.parameters.next(Check.self).flatMap { check in
                return try self.checkService.uploadImage(on: request, file: file, check: check)
            }
        }
    }

    func addParticipants(_ request: Request, usersForm: Check.UsersForm) throws -> Future<ProductsDto> {
        return try request.parameters.next(Check.self).flatMap { check in
            return try self.checkService.addParticipants(on: request, check: check, userIDs: usersForm.userIDs)
        }
    }

    func removeParticipant(_ request: Request) throws -> Future<ProductsDto> {
        guard let userID = request.query[Int.self, at: "userID"] else {
            throw Abort(.badRequest)
        }

        return try request.parameters.next(Check.self).flatMap { check in
            return try self.checkService.removeParticipant(on: request, check: check, userID: userID)
        }
    }

    func calculate(_ request: Request, dto: SelectedProductsDto) throws -> Future<[CheckUser.Form]> {
        return try request.parameters.next(Check.self).flatMap { check in
            return try self.checkService.calculate(on: request, check: check, selectedProducts: dto.selectedProducts)
        }
    }

    func fetchReviews(_ request: Request) throws -> Future<[CheckUser.Form]> {
        return try request.parameters.next(Check.self).flatMap { check in
            return try self.checkService.fetchReviews(on: request, check: check)
        }
    }

    func approve(_ request: Request) throws -> Future<[CheckUser.Form]> {
        return try request.parameters.next(Check.self).flatMap { check in
            return try self.checkService.approve(on: request, check: check)
        }
    }

    func reject(_ request: Request, dto: CheckRejectDto) throws -> Future<[CheckUser.Form]> {
        return try request.parameters.next(Check.self).flatMap { check in
            return try self.checkService.reject(on: request, check: check, dto: dto)
        }
    }

    func fetch(_ request: Request) throws -> Future<Check.Form> {
        return try request.parameters.next(Check.self).flatMap { check in
            return try self.checkService.fetch(on: request, check: check)
        }
    }

    func distribute(_ request: Request) throws -> Future<Check.Form> {
        return try request.parameters.next(Check.self).flatMap { check in
            return try self.checkService.distribute(on: request, check: check)
        }
    }
}

// MARK: - RouteCollection

extension CheckController: RouteCollection {

    // MARK: - Instance Methods

    func boot(router: Router) throws {
        let group = router.grouped("v1/checks").grouped(ConsoleLogger()).grouped(JWTMiddleware())

        group.post(Check.QRCodeForm.self, use: self.create)
        group.post(SelectedProductsDto.self, at: Check.parameter, "calculate", use: self.calculate)
        group.post(Check.UsersForm.self, at: Check.parameter, "participants", use: self.addParticipants)
        group.post(Check.parameter, "distribute", use: self.distribute)

        group.get(use: self.fetchAll)
        group.get(Check.parameter, use: self.fetch)
        group.get(Check.parameter, "products", use: self.fetchProducts)
        group.get(Check.parameter, "reviews", use: self.fetchReviews)

        group.put(Check.StoreForm.self, at: Check.parameter, use: self.update)
        group.put(Check.parameter, "image", use: self.uploadImage)
        group.put(Check.parameter, "approve", use: self.approve)
        group.put(CheckRejectDto.self, at: Check.parameter, "reject", use: self.reject)

        group.delete(Check.parameter, "participants", use: self.removeParticipant)
    }
}

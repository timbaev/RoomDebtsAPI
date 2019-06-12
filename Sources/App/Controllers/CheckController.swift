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
}

// MARK: - RouteCollection

extension CheckController: RouteCollection {

    // MARK: - Instance Methods

    func boot(router: Router) throws {
        let group = router.grouped("v1/checks").grouped(Logger()).grouped(JWTMiddleware())

        group.post(Check.QRCodeForm.self, use: self.create)
        group.get(use: self.fetch)

        group.get(Check.parameter, use: self.fetchProducts)

        group.put(Check.StoreForm.self, at: Check.parameter, use: self.update)
        group.put(Check.parameter, "image", use: self.uploadImage)

        group.post(Check.UsersForm.self, at: Check.parameter, "participants", use: self.addParticipants)
        group.delete(Check.parameter, "participants", use: self.removeParticipant)

        group.post(SelectedProductsDto.self, at: Check.parameter, "calculate", use: self.calculate)

        group.get(Check.parameter, "reviews", use: self.fetchReviews)
    }
}

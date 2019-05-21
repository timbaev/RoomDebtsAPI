//
//  DefaultCheckService.swift
//  App
//
//  Created by Timur Shafigullin on 07/04/2019.
//

import Vapor
import FluentPostgreSQL

struct DefaultCheckService: CheckService {

    // MARK: - Instance Properties

    let receiptManager: ReceiptManager
    let productService: ProductService

    // MARK: - Instance Methods

    func create(on request: Request, form: Check.QRCodeForm) throws -> Future<Check.Form> {
        return Check.query(on: request)
            .filter(\.fd == form.fd)
            .filter(\.fn == form.fn)
            .filter(\.fiscalSign == form.fiscalSign)
            .first()
            .flatMap { existsCheck in
                guard existsCheck == nil else {
                    throw Abort(.badRequest, reason: "Check \"\(existsCheck!.store)\" already exists")
                }

                return try self.receiptManager.checkReceiptExists(on: request, form: form).flatMap { checkExists in
                    guard checkExists else {
                        throw Abort(.notFound, reason: "Check not found on Federal Tax Service. Try again later")
                    }

                    return try self.receiptManager.fetchReceiptContent(on: request, form: form).flatMap { receipt in
                        let check = Check(receipt: receipt, creatorID: try request.requiredUserID())

                        return check.save(on: request).flatMap { savedCheck in
                            for item in receipt.items {
                                _ = self.productService.findOrCreate(on: request, for: item).flatMap { product in
                                    savedCheck.products.attach(product, on: request)
                                }
                            }

                            return try request.authorizedUser().flatMap { user in
                                return savedCheck.users.attach(user, on: request).flatMap { checkUser in
                                    return request.future(savedCheck).toForm(on: request)
                                }
                            }
                        }
                    }
                }
        }
    }

    func fetch(on request: Request) throws -> Future<[Check.Form]> {
        return try request.authorizedUser().flatMap { user in
            return try user.checks.query(on: request).all().flatMap { checks in
                return checks.map { check in
                    return request.future(check).toForm(on: request)
                }.flatten(on: request)
            }
        }
    }

    func update(on request: Request, check: Check, form: Check.StoreForm) throws -> Future<Check.Form> {
        guard check.creatorID == request.userID else {
            throw Abort(.forbidden, reason: "Only creator can change check store name")
        }

        check.store = form.store

        return check.save(on: request).toForm(on: request)
    }
}

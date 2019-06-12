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
    let fileService: FileService

    // MARK: - Instance Methods

    private func convertToCheckUserForm(on request: Request, checkUser: CheckUser) throws -> Future<CheckUser.Form> {
        return User.find(checkUser.userID, on: request).unwrap(or: Abort(.notFound)).map { user in
            return CheckUser.Form(checkUser: checkUser, user: user)
        }
    }

    // MARK: - CheckService

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
                            return receipt.items.map { item in
                                return self.productService.findOrCreate(on: request, for: item).flatMap { product in
                                    savedCheck.products.attach(product, on: request)
                                }
                            }.flatten(on: request).flatMap { checkProducts in
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

    func uploadImage(on request: Request, file: File, check: Check) throws -> Future<Check.Form> {
        guard check.creatorID == request.userID else {
            throw Abort(.forbidden, reason: "Only creator can change check image")
        }

        if let checkImage = check.image {
            return checkImage.get(on: request).flatMap { fileRecord in
                return try self.fileService.remove(request: request, fileRecord: fileRecord).flatMap {
                    return try self.fileService.uploadImage(on: request, file: file).flatMap { fileRecord in
                        check.imageID = try fileRecord.requireID()

                        return check.save(on: request).toForm(on: request)
                    }
                }
            }
        } else {
            return try self.fileService.uploadImage(on: request, file: file).flatMap { fileRecord in
                check.imageID = try fileRecord.requireID()

                return check.save(on: request).toForm(on: request)
            }
        }
    }

    func addParticipants(on request: Request, check: Check, userIDs: [Int]) throws -> Future<ProductsDto> {
        guard check.creatorID == request.userID else {
            throw Abort(.forbidden, reason: "Only creator can add participants")
        }

        // TODO: - Validate userIDs in user's debt conversations

        return try check.users.query(on: request).group(.or, closure: { filterBuilder in
            userIDs.forEach { userID in
                filterBuilder.filter(\.id == userID)
            }
        }).all().flatMap { existingCheckUsers in
            guard existingCheckUsers.isEmpty else {
                let userNames = existingCheckUsers.map { $0.firstName }.joined(separator: ", ")

                throw Abort(.badRequest, reason: "User(s) \(userNames) already added to check")
            }

            return userIDs.map { userID in
                return User.find(userID, on: request).unwrap(or: Abort(.notFound, reason: "User not found"))
            }.flatten(on: request).flatMap { users in
                    return users.map { user in
                        return check.users.attach(user, on: request)
                    }.flatten(on: request)
            }.flatMap { attachedCheckUsers in
                return try self.productService.fetch(on: request, for: check)
            }
        }
    }

    func removeParticipant(on request: Request, check: Check, userID: Int) throws -> Future<ProductsDto> {
        guard check.creatorID == request.userID else {
            throw Abort(.forbidden, reason: "Only creator can remove participants")
        }

        return try check.users.query(on: request).filter(\.id == userID).all().flatMap { checkUsers in
            guard let checkUser = checkUsers.first else {
                throw Abort(.badRequest, reason: "User not found")
            }

            return check.users.detach(checkUser, on: request).flatMap { _ in
                return try self.productService.fetch(on: request, for: check)
            }
        }
    }

    func calculate(on request: Request, check: Check, selectedProducts: [Product.ID: [User.ID]]) throws -> Future<[CheckUser.Form]> {
        guard check.creatorID == request.userID else {
            throw Abort(.forbidden, reason: "Only creator can calculate check")
        }

        guard check.status != .accepted else {
            throw Abort(.badRequest, reason: "Check already accepted")
        }

        let selectedProductIDs = selectedProducts.map { $0.key }

        return try check.products.query(on: request).all().flatMap { products in
            guard selectedProductIDs.count == products.count else {
                throw Abort(.badRequest, reason: "All products should be selected")
            }

            var usersTotal: [User.ID: Double] = [:]
            var userProducts: [User.ID: [Product]] = [:]

            try selectedProducts.forEach { productID, userIDs in
                guard let product = products.first(where: { $0.id == productID }) else {
                    throw Abort(.notFound, reason: "Product with ID \(productID) not found")
                }

                let total = product.price / Double(userIDs.count)

                userIDs.forEach { userID in
                    if let userTotal = usersTotal[userID] {
                        usersTotal[userID] = userTotal + total
                    } else {
                        usersTotal[userID] = total
                    }

                    if userProducts[userID] == nil {
                        userProducts[userID] = [product]
                    } else {
                        userProducts[userID]?.append(product)
                    }
                }
            }

            return try check.users.pivots(on: request).all().flatMap { checkUsers in
                var savedCheckUserFutures: [Future<CheckUser>] = []

                try usersTotal.forEach { userID, total in
                    guard var checkUser = checkUsers.first(where: { $0.userID == userID }) else {
                        throw Abort(.notFound, reason: "User with ID \(userID) not found in CheckUsers")
                    }

                    guard let products = userProducts[userID] else {
                        throw Abort(.badRequest, reason: "All users should be with selected products")
                    }

                    checkUser.total = total
                    checkUser.status = .review
                    checkUser.comment = nil
                    checkUser.reviewDate = nil

                    let savedCheckUserFuture = checkUser.products.detachAll(on: request).flatMap { _ in
                        return products.map { product in
                            return checkUser.products.attach(product, on: request)
                        }.flatten(on: request).flatMap { productCheckUser in
                            return checkUser.save(on: request)
                        }
                    }

                    savedCheckUserFutures.append(savedCheckUserFuture)
                }

                return savedCheckUserFutures.flatten(on: request).flatMap { savedCheckUsers in
                    check.status = .calculated

                    return check.save(on: request).flatMap { savedCheck in
                        return try savedCheckUsers.map {
                            try self.convertToCheckUserForm(on: request, checkUser: $0)
                        }.flatten(on: request)
                    }
                }
            }
        }
    }

    func fetchReviews(on request: Request, check: Check) throws -> Future<[CheckUser.Form]> {
        return try check.users.pivots(on: request).all().flatMap { checkUsers in
            guard checkUsers.contains(where: { $0.userID == request.userID }) else {
                throw Abort(.forbidden)
            }

            return try checkUsers.map { checkUser in
                return try self.convertToCheckUserForm(on: request, checkUser: checkUser)
            }.flatten(on: request)
        }
    }
}

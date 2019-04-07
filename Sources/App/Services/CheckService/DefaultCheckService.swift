//
//  DefaultCheckService.swift
//  App
//
//  Created by Timur Shafigullin on 07/04/2019.
//

import Vapor

struct DefaultCheckService: CheckService {

    // MARK: - Instance Properties

    let receiptManager: ReceiptManager
    let productService: ProductService

    // MARK: - Instance Methods

    func create(on request: Request, form: Check.QRCodeForm) throws -> Future<Check.Form> {
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

                    return request.future(savedCheck).toForm(on: request)
                }
            }
        }
    }
}

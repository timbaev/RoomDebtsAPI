//
//  ReceiptManager.swift
//  App
//
//  Created by Timur Shafigullin on 06/04/2019.
//

import Vapor

protocol ReceiptManager {

    // MARK: - Instance Methods

    func checkReceiptExists(on request: Request, form: Check.QRCodeForm) throws -> Future<Bool>
    func fetchReceiptContent(on request: Request, form: Check.QRCodeForm) throws -> Future<Receipt>
}

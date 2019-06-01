//
//  CheckService.swift
//  App
//
//  Created by Timur Shafigullin on 07/04/2019.
//

import Vapor

protocol CheckService {

    // MARK: - Instance Methods

    func create(on request: Request, form: Check.QRCodeForm) throws -> Future<Check.Form>
    func fetch(on request: Request) throws -> Future<[Check.Form]>
    func update(on request: Request, check: Check, form: Check.StoreForm) throws -> Future<Check.Form>
    func uploadImage(on request: Request, file: File, check: Check) throws -> Future<Check.Form>
    func addParticipants(on request: Request, check: Check, userIDs: [Int]) throws -> Future<ProductsDto>
    func removeParticipant(on request: Request, check: Check, userID: Int) throws -> Future<ProductsDto>
}

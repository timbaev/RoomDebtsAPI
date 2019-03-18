//
//  DebtService.swift
//  App
//
//  Created by Timur Shafigullin on 04/03/2019.
//

import Vapor

protocol DebtService {

    // MARK: - Instance Methods

    func create(request: Request, form: Debt.CreateForm) throws -> Future<Debt.Form>
    func fetch(request: Request, conversationID: Int) throws -> Future<[Debt.Form]>

    func accept(on request: Request, debt: Debt) throws -> Future<Debt.Form>
    func reject(on request: Request, debt: Debt) throws -> Future<Void>

    func update(on request: Request, debt: Debt, form: Debt.CreateForm) throws -> Future<Debt.Form>
}

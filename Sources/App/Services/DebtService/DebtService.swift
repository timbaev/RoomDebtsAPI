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
}

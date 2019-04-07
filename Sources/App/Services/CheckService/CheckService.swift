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
}

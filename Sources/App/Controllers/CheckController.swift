//
//  CheckController.swift
//  App
//
//  Created by Timur Shafigullin on 05/04/2019.
//

import Vapor

final class CheckController { }

extension CheckController: RouteCollection {

    // MARK: - Instance Methods

    func boot(router: Router) throws {
        let group = router.grouped("v1/checks").grouped(Logger()).grouped(JWTMiddleware())
    }
}

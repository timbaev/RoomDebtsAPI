//
//  ConversationVisitController.swift
//  App
//
//  Created by Timur Shafigullin on 18/08/2019.
//

import Vapor

final class ConversationVisitController {

    // MARK: - Instance Properties

    var conversationVisitService: ConversationVisitService

    // MARK: - Initializers

    init(conversationVisitService: ConversationVisitService) {
        self.conversationVisitService = conversationVisitService
    }

    // MARK: - Instance Methods

    func update(_ request: Request) throws -> Future<ConversationVisit.Form> {
        guard let conversationID = request.query[Int.self, at: "conversationID"] else {
            throw Abort(.badRequest)
        }

        return try self.conversationVisitService.updateConversationVisit(on: request, conversationID: conversationID)
    }
}

// MARK: - RouteCollection

extension ConversationVisitController: RouteCollection {

    // MARK: - Instance Methods

    func boot(router: Router) throws {
        let group = router.grouped("v1", "conversation", "visit").grouped(ConsoleLogger()).grouped(JWTMiddleware())

        group.put(use: self.update)
    }
}

//
//  DefaultDebtService.swift
//  App
//
//  Created by Timur Shafigullin on 04/03/2019.
//

import Vapor

class DefaultDebtService: DebtService {

    // MARK: - Instance Properties

    private var conversationService: ConversationService

    // MARK: - Initializers

    init(conversationService: ConversationService) {
        self.conversationService = conversationService
    }

    // MARK: - Instance Methods

    func create(request: Request, form: Debt.CreateForm) throws -> Future<Debt.Form> {
        return try request.authorizedUser().flatMap { user in
            let userID = try user.requireID()

            return Conversation
                .find(form.conversationID, on: request)
                .unwrap(or: Abort(.notFound, reason: "Conversation with ID \(form.conversationID) not found"))
                .flatMap { conversation in
                    guard conversation.creatorID == form.debtorID || conversation.opponentID == form.debtorID else {
                        throw Abort(.badRequest, reason: "Debtor is not participant")
                    }

                    guard conversation.creatorID == userID || conversation.opponentID == userID else {
                        throw Abort(.badRequest, reason: "Creator is not participant")
                    }

                    guard conversation.status == .accepted else {
                        throw Abort(.badRequest, reason: "Conversation is not accepted")
                    }

                    return Debt(form: form, creatorID: userID).save(on: request).map { debt in
                        return Debt.Form(debt: debt, creator: User.PublicForm(user: user))
                    }
            }
        }
    }
}

//
//  DefaultDebtService.swift
//  App
//
//  Created by Timur Shafigullin on 04/03/2019.
//

import Vapor
import FluentQuery

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

    func fetch(request: Request, conversationID: Int) throws -> Future<[Debt.Form]> {
        return try request.authorizedUser().flatMap { user in
            let userID = try user.requireID()

            return Conversation
                .find(conversationID, on: request)
                .unwrap(or: Abort(.badRequest, reason: "Conversation not found"))
                .flatMap { conversation in
                    guard conversation.creatorID == userID || conversation.opponentID == userID else {
                        throw Abort(.badRequest, reason: "User is not participant of conversation")
                    }

                    return request.requestPooledConnection(to: .psql).flatMap { conn -> Future<[Debt.Form]> in
                        let creator = User.alias(short: "creator")

                        return try FQL().select(all: Debt.self)
                            .select(.row(creator), as: "creator")
                            .from(Debt.self)
                            .join(.inner, creator, where: creator.k(\.id) == \Debt.creatorID)
                            .where(\Debt.conversationID == conversationID)
                            .orderBy(.desc(\Debt.createdAt))
                            .execute(on: conn)
                            .decode(Debt.Form.self)
                    }
            }
        }
    }

    // MARK: -

    func accept(on request: Request, debt: Debt) throws -> Future<Debt.Form> {
        return try request.authorizedUser().flatMap { user in
            let userID = try user.requireID()

            guard debt.status != .accepted else {
                throw Abort(.badRequest, reason: "Debt already accepted")
            }

            return debt.conversation.get(on: request).flatMap { conversation in
                guard conversation.creatorID == userID || conversation.opponentID == userID else {
                    throw Abort(.badRequest, reason: "User is not participant of conversation")
                }

                return self.conversationService.updatePrice(request: request, debt: debt, conversation: conversation).flatMap { _ in
                    debt.status = .accepted

                    return debt.save(on: request).flatMap { savedDebt in
                        return debt.creator.get(on: request).map { creator in
                            return Debt.Form(debt: savedDebt, creator: User.PublicForm(user: creator))
                        }
                    }
                }
            }
        }
    }

    func reject(on request: Request, debt: Debt) throws -> Future<Void> {
        return debt.delete(on: request)
    }
}

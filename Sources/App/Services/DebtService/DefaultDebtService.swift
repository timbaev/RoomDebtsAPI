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

    private func updateAndSave(on request: Request, debt: Debt, form: Debt.CreateForm, creatorID: User.ID) -> Future<Debt> {
        debt.price = form.price
        debt.date = form.date
        debt.description = form.description
        debt.debtorID = form.debtorID
        debt.creatorID = creatorID

        if debt.status != .newRequest {
            debt.status = .editRequest
        }

        return debt.save(on: request)
    }

    private func validate(conversation: Conversation, on request: Request) throws {
        guard conversation.creatorID == request.userID || conversation.opponentID == request.userID else {
            throw Abort(.badRequest, reason: "User is not participant of conversation")
        }

        guard conversation.status == .accepted else {
            throw Abort(.badRequest, reason: "Conversation is not accepted")
        }
    }

    // MARK: -

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

    func accept(on request: Request, debt: Debt) throws -> Future<Response> {
        let response = Response(using: request)

        guard debt.status != .accepted else {
            throw Abort(.badRequest, reason: "Debt already accepted")
        }

        return debt.conversation.get(on: request).flatMap { conversation in
            try self.validate(conversation: conversation, on: request)

            if debt.status == .newRequest || debt.status == .editRequest {
                return try self.conversationService.updatePrice(on: request, action: .add, debt: debt, conversation: conversation).flatMap { _ in
                    debt.status = .accepted

                    return debt.save(on: request).toForm(on: request).map { debtForm in
                        try response.content.encode(debtForm)

                        return response
                    }
                }
            } else if debt.status == .deleteRequest {
                return try self.conversationService.updatePrice(on: request, action: .subtract, debt: debt, conversation: conversation).flatMap { _ in
                    return debt.delete(on: request).map {
                        response.http.status = .noContent

                        return response
                    }
                }
            } else if debt.status == .repayRequest {
                return try self.conversationService.updatePrice(on: request, action: .subtract, debt: debt, conversation: conversation).flatMap { _ in
                    debt.status = .repaid

                    return debt.save(on: request).toForm(on: request).map { debtForm in
                        try response.content.encode(debtForm)

                        return response
                    }
                }
            } else {
                throw Abort(.badRequest)
            }
        }
    }

    func reject(on request: Request, debt: Debt) throws -> Future<Void> {
        switch debt.status {
        case .newRequest, .editRequest, .deleteRequest:
            debt.isRejected = true

            return debt.save(on: request).transform(to: Void())

        case .repayRequest, .accepted, .repaid:
            throw Abort(.badRequest)
        }
    }

    func update(on request: Request, debt: Debt, form: Debt.CreateForm) throws -> Future<Debt.Form> {
        return debt.conversation.get(on: request).flatMap { conversation in
            guard let userID = request.userID else {
                throw Abort(.unauthorized)
            }

            guard conversation.creatorID == form.debtorID || conversation.opponentID == form.debtorID else {
                throw Abort(.badRequest, reason: "Debtor is not participant")
            }

            guard conversation.creatorID == request.userID || conversation.opponentID == request.userID else {
                throw Abort(.badRequest, reason: "User is not participant of conversation")
            }

            guard conversation.status == .accepted else {
                throw Abort(.badRequest, reason: "Conversation is not accepted")
            }

            if debt.status == .accepted {
                return try self.conversationService.updatePrice(on: request, action: .subtract, debt: debt, conversation: conversation).flatMap { _ in
                    return self.updateAndSave(on: request, debt: debt, form: form, creatorID: userID).toForm(on: request)
                }
            } else {
                return self.updateAndSave(on: request, debt: debt, form: form, creatorID: userID).toForm(on: request)
            }
        }
    }

    func deleteRequest(on request: Request, debt: Debt) throws -> Future<Debt.Form> {
        return debt.conversation.get(on: request).flatMap { conversation in
            try self.validate(conversation: conversation, on: request)

            guard debt.status != .newRequest else {
                throw Abort(.badRequest, reason: "Debt should be deleted without request")
            }

            debt.status = .deleteRequest
            debt.creatorID = try request.requiredUserID()

            return debt.save(on: request).toForm(on: request)
        }
    }

    func delete(on request: Request, debt: Debt) throws -> Future<Void> {
        return debt.conversation.get(on: request).flatMap { conversation in
            try self.validate(conversation: conversation, on: request)

            guard debt.status == .newRequest else {
                throw Abort(.badRequest, reason: "Debt can't be deleted without request")
            }

            return debt.delete(on: request)
        }
    }

    func repayRequest(on request: Request, debt: Debt) throws -> Future<Debt.Form> {
        return debt.conversation.get(on: request).flatMap { conversation in
            try self.validate(conversation: conversation, on: request)

            guard debt.status == .accepted else {
                throw Abort(.badRequest, reason: "Debt must be accepted")
            }

            debt.status = .repayRequest
            debt.creatorID = try request.requiredUserID()

            return debt.save(on: request).toForm(on: request)
        }
    }

    func createAndAccept(on request: Request, form: Debt.CreateForm) throws -> Future<Response> {
        return try self.create(request: request, form: form).flatMap { createdDebtForm in
            guard let debtID = createdDebtForm.id else {
                throw Abort(.notFound, reason: "Created debt ID not found")
            }

            return Debt
                .find(debtID, on: request)
                .unwrap(or: Abort(.notFound, reason: "Created debt ID not found"))
                .flatMap { debt in
                    return try self.accept(on: request, debt: debt)
            }
        }
    }
}

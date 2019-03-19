//
//  DefaultConversationService.swift
//  App
//
//  Created by Timur Shafigullin on 03/02/2019.
//

import Vapor
import FluentPostgreSQL
import FluentQuery

class DefaultConversationService: ConversationService {

    // MARK: - Instance Methods

    private func updatePriceNewRequest(on request: Request, debt: Debt, conversation: Conversation) -> Future<Conversation> {
        let debtorID = debt.debtorID
        let price = debt.price

        if let conversationDebtorID = conversation.debtorID {
            if debtorID == conversationDebtorID {
                conversation.price += price
            } else {
                conversation.price -= price

                if conversation.price < 0 {
                    let opponentID = (conversation.creatorID == conversation.debtorID) ? conversation.opponentID : conversation.creatorID

                    conversation.debtorID = opponentID
                    conversation.price = fabs(conversation.price)
                }
            }
        } else {
            conversation.price = price
            conversation.debtorID = debtorID
        }

        if conversation.price == 0 {
            conversation.debtorID = nil
        }

        return conversation.save(on: request)
    }

    private func updatePriceEditRequest(on request: Request, oldDebt: Debt, conversation: Conversation) throws -> Future<Conversation> {
        conversation.price -= oldDebt.price

        if conversation.price < 0 {
            let opponentID = (conversation.creatorID == conversation.debtorID) ? conversation.opponentID : conversation.creatorID

            conversation.debtorID = opponentID
            conversation.price = fabs(conversation.price)
        }

        if conversation.price == 0 {
            conversation.debtorID = nil
        }

        return conversation.save(on: request)
    }

    // MARK: -
    
    func create(request: Request, createForm: Conversation.CreateForm) throws -> Future<Conversation.Form> {
        let opponentID = createForm.opponentID
        
        let opponentFuture = User
            .find(opponentID, on: request)
            .unwrap(or: Abort(.notFound, reason: "User with ID \(opponentID) not found"))
        
        return opponentFuture.flatMap { opponent in
            return try request.authorizedUser().flatMap { user in
                let userID = try user.requireID()
                
                return Conversation.query(on: request).group(.or, closure: { builder in
                    builder.filter(\.creatorID == userID).filter(\.opponentID == userID)
                }).group(.or, closure: { builder in
                    builder.filter(\.creatorID == opponentID).filter(\.opponentID == opponentID)
                }).first().flatMap { conversation in
                    guard conversation == nil else {
                        throw Abort(.badRequest, reason: "Conversation with \(opponent.firstName) \(opponent.lastName) already exists")
                    }
                    
                    return Conversation(creatorID: userID, opponentID: opponentID)
                        .save(on: request)
                        .toForm(on: request)
                }
            }
        }
    }

    func fetch(request: Request) throws -> Future<[Conversation.Form]> {
        return try request.authorizedUser().flatMap { user in
            let userID = try user.requireID()

            return request.requestPooledConnection(to: .psql).flatMap { conn -> Future<[Conversation.Form]> in
                defer { try? request.releasePooledConnection(conn, to: .psql) }

                let creator = User.alias(short: "creator")
                let opponent = User.alias(short: "opponent")

                return try FQL().select(all: Conversation.self)
                    .select(.row(creator), as: "creator")
                    .select(.row(opponent), as: "opponent")
                    .from(Conversation.self)
                    .join(.inner, creator, where: creator.k(\.id) == \Conversation.creatorID)
                    .join(.inner, opponent, where: opponent.k(\.id) == \Conversation.opponentID)
                    .where(FQWhere(\Conversation.creatorID == userID).or(\Conversation.opponentID == userID))
                    .execute(on: conn)
                    .decode(Conversation.Form.self)
            }
        }
    }

    func accept(request: Request, conversation: Conversation) throws -> Future<Conversation.Form> {
        return try request.authorizedUser().flatMap { user in
            let userID = try user.requireID()

            guard conversation.opponentID == userID else {
                throw Abort(.badRequest, reason: "User is not opponent of converation")
            }

            conversation.status = .accepted

            if conversation.status == .invited {
                return conversation.save(on: request).toForm(on: request)
            } else {
                return try conversation.debts.query(on: request).all().flatMap { debts in
                    return (debts as [Debt]).map { debt -> Future<Debt> in
                        let debt = debt

                        debt.status = .repaid

                        return debt.save(on: request)
                    }.flatten(on: request).flatMap { updatedDebts -> Future<Conversation.Form> in
                        conversation.price = 0
                        conversation.debtorID = nil

                        return conversation.save(on: request).toForm(on: request)
                    }
                }
            }
        }
    }

    func reject(request: Request, conversation: Conversation) throws -> Future<Void> {
        return try request.authorizedUser().flatMap { user in
            let userID = try user.requireID()

            guard conversation.opponentID == userID else {
                throw Abort(.badRequest, reason: "User is not opponent of converation")
            }

            return conversation.delete(on: request)
        }
    }

    func updatePrice(on request: Request, action: PriceAction, debt: Debt, conversation: Conversation) throws -> Future<Conversation> {
        switch action {
        case .add:
            return self.updatePriceNewRequest(on: request, debt: debt, conversation: conversation)

        case .subtract:
            return try self.updatePriceEditRequest(on: request, oldDebt: debt, conversation: conversation)
        }
    }

    func repayAllRequest(on request: Request, conversation: Conversation) throws -> Future<Conversation.Form> {
        guard try conversation.creatorID == request.requiredUserID() || conversation.opponentID == request.requiredUserID() else {
            throw Abort(.badRequest, reason: "User is not participant of conversation")
        }

        conversation.status = .repayRequest
        conversation.creatorID = try request.requiredUserID()

        return conversation.save(on: request).toForm(on: request)
    }
}

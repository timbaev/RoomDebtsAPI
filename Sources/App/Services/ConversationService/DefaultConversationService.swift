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

    private func fetchNewDebtCount(on request: Request, for conversationID: Conversation.ID) throws -> Future<Int> {
        return try ConversationVisit.query(on: request)
            .filter(\.userID == request.requiredUserID())
            .filter(\.conversationID == conversationID)
            .first()
            .flatMap { conversationVisit in
                if let conversationVisit = conversationVisit {
                    return Debt.query(on: request)
                        .filter(\.conversationID == conversationID)
                        .filter(\.updatedAt > conversationVisit.visitDate)
                        .count()
                } else {
                    return Debt.query(on: request).filter(\.conversationID == conversationID).count()
                }
        }
    }

    private func updateNewDebtCount(on request: Request, for conversationForms: [Conversation.Form]) throws -> Future<[Conversation.Form]> {
        return try conversationForms.map { conversationForm in
            guard let conversationID = conversationForm.id else {
                throw Abort(.internalServerError)
            }

            return try self.fetchNewDebtCount(on: request, for: conversationID).map { count in
                var conversationForm = conversationForm

                conversationForm.newDebtCount = count

                return conversationForm
            }
        }.flatten(on: request)
    }

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
            .unwrap(or: Abort(.notFound, reason: "User with ID %{ID} not found".localized(on: request, interpolations: ["ID": opponentID])))
        
        return opponentFuture.flatMap { opponent in
            return try request.authorizedUser().flatMap { user in
                let userID = try user.requireID()
                
                return Conversation.query(on: request).group(.or, closure: { builder in
                    builder.filter(\.creatorID == userID).filter(\.opponentID == userID)
                }).group(.or, closure: { builder in
                    builder.filter(\.creatorID == opponentID).filter(\.opponentID == opponentID)
                }).first().flatMap { conversation in
                    guard conversation == nil else {
                        throw Abort(.badRequest, reason: "Conversation with %{firstName} %{lastName} already exists".localized(on: request, interpolations: ["firstName": opponent.firstName, "lastName": opponent.lastName]))
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
                    .decode(Conversation.Form.self).flatMap { conversationForms in
                        return try self.updateNewDebtCount(on: request, for: conversationForms)
                }
            }
        }
    }

    func accept(request: Request, conversation: Conversation) throws -> Future<Response> {
        return try request.authorizedUser().flatMap { user in
            let userID = try user.requireID()
            let response = Response(using: request)

            guard conversation.opponentID == userID else {
                throw Abort(.badRequest, reason: "User is not participant of conversation".localized(on: request))
            }

            if conversation.status == .invited {
                conversation.status = .accepted

                return conversation.save(on: request).toForm(on: request).map { conversationForm in
                    try response.content.encode(conversationForm)

                    return response
                }
            } else if conversation.status == .repayRequest {
                conversation.status = .accepted

                return try conversation.debts.query(on: request).all().flatMap { debts in
                    return (debts as [Debt]).map { debt -> Future<Debt> in
                        let debt = debt

                        debt.status = .repaid

                        return debt.save(on: request)
                    }.flatten(on: request).flatMap { updatedDebts -> Future<Response> in
                        conversation.price = 0
                        conversation.debtorID = nil

                        return conversation.save(on: request).toForm(on: request).map { conversationForm in
                            try response.content.encode(conversationForm)

                            return response
                        }
                    }
                }
            } else if conversation.status == .deleteRequest {
                return try conversation.debts.query(on: request).delete().flatMap {
                    return conversation.delete(on: request).map {
                        response.http.status = .noContent

                        return response
                    }
                }
            } else {
                throw Abort(.badRequest)
            }
        }
    }

    func reject(request: Request, conversation: Conversation) throws -> Future<Response> {
        return try request.authorizedUser().flatMap { user in
            let userID = try user.requireID()
            let response = Response(using: request)

            guard conversation.opponentID == userID else {
                throw Abort(.badRequest, reason: "User is not participant of conversation".localized(on: request))
            }

            if conversation.status == .invited {
                return conversation.delete(on: request).map {
                    response.http.status = .noContent

                    return response
                }
            } else if conversation.status == .repayRequest {
                conversation.status = .accepted
                conversation.rejectStatus = .repayRequest

                return conversation.save(on: request).toForm(on: request).map { conversationForm -> Response in
                    try response.content.encode(conversationForm)

                    return response
                }
            } else if conversation.status == .deleteRequest {
                conversation.status = .accepted
                conversation.rejectStatus = .deleteRequest

                return conversation.save(on: request).toForm(on: request).map { conversationForm -> Response in
                    try response.content.encode(conversationForm)

                    return response
                }
            } else {
                throw Abort(.badRequest)
            }
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
            throw Abort(.badRequest, reason: "User is not participant of conversation".localized(on: request))
        }

        guard conversation.status == .accepted else {
            throw Abort(.badRequest, reason: "Debt creation request must be accepted".localized(on: request))
        }

        let opponentID = (conversation.creatorID == request.userID) ? conversation.opponentID : conversation.creatorID

        conversation.status = .repayRequest
        conversation.creatorID = try request.requiredUserID()
        conversation.opponentID = opponentID

        return conversation.save(on: request).toForm(on: request)
    }

    func deleteRequest(on request: Request, conversation: Conversation) throws -> Future<Conversation.Form> {
        let opponentID = (conversation.creatorID == request.userID) ? conversation.opponentID : conversation.creatorID
        let userID = try request.requiredUserID()

        return CheckUser.query(on: request).join(\Check.id, to: \CheckUser.checkID).filter(\Check.status != .closed).group(.or, closure: { builder in
            builder.filter(\Check.creatorID == userID).filter(\Check.creatorID == opponentID)
        }).group(.or, closure: { builder in
            builder.filter(\CheckUser.userID == userID).filter(\CheckUser.userID == opponentID)
        }).count().flatMap { commonCheckCount in
            guard commonCheckCount == 0 else {
                throw Abort(.badRequest, reason: "Unable to delete the conversation because with this user you have a common undistributed check. You can remove this person from the check and then try again.".localized(on: request))
            }

            guard try conversation.creatorID == request.requiredUserID() || conversation.opponentID == request.requiredUserID() else {
                throw Abort(.badRequest, reason: "User is not participant of conversation".localized(on: request))
            }

            guard conversation.status == .accepted || conversation.status == .repayRequest else {
                throw Abort(.badRequest, reason: "Debt creation request must be accepted".localized(on: request))
            }

            conversation.status = .deleteRequest
            conversation.creatorID = try request.requiredUserID()
            conversation.opponentID = opponentID

            return conversation.save(on: request).toForm(on: request)
        }
    }

    func cancelRequest(on request: Request, conversation: Conversation) throws -> Future<Conversation.Form> {
        guard try conversation.creatorID == request.requiredUserID() || conversation.opponentID == request.requiredUserID() else {
            throw Abort(.badRequest, reason: "User is not participant of conversation".localized(on: request))
        }

        guard conversation.status == .repayRequest || conversation.status == .deleteRequest else {
            throw Abort(.badRequest)
        }

        let opponentID = (conversation.creatorID == request.userID) ? conversation.opponentID : conversation.creatorID

        conversation.status = .accepted
        conversation.creatorID = try request.requiredUserID()
        conversation.opponentID = opponentID

        return conversation.save(on: request).toForm(on: request)
    }

    func delete(on request: Request, conversation: Conversation) throws -> Future<Void> {
        guard try conversation.creatorID == request.requiredUserID() else {
            throw Abort(.badRequest, reason: "User is not participant of conversation".localized(on: request))
        }

        guard conversation.status == .invited else {
            throw Abort(.badRequest, reason: "Forbidden delete conversation without request".localized(on: request))
        }

        return conversation.delete(on: request)
    }

    func find(on request: Request, participantIDs: [User.ID]) throws -> Future<Conversation> {
        return Conversation.query(on: request).group(.or, closure: { builder in
            builder.filter(\.creatorID == participantIDs[0]).filter(\.opponentID == participantIDs[0])
        }).group(.or, closure: { builder in
            builder.filter(\.creatorID == participantIDs[1]).filter(\.opponentID == participantIDs[1])
        }).first().unwrap(or: Abort(.notFound))
    }
}

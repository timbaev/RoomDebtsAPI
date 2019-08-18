//
//  DefaultConversationVisitService.swift
//  App
//
//  Created by Timur Shafigullin on 18/08/2019.
//

import Vapor
import FluentPostgreSQL

struct DefaultConversationVisitService: ConversationVisitService {

    // MARK: - Instance Methods

    private func firstOrNew(on request: Request, with userID: User.ID, conversationID: Conversation.ID) -> Future<ConversationVisit> {
        return ConversationVisit
            .query(on: request)
            .filter(\.userID == userID)
            .filter(\.conversationID == conversationID)
            .first()
            .flatMap { conversationVisit in
                if let conversationVisit = conversationVisit {
                    return request.future(conversationVisit)
                } else {
                    return ConversationVisit(userID: userID, conversationID: conversationID, visitDate: Date()).save(on: request)
                }
        }
    }

    // MARK: - ConversationVisitService

    func updateConversationVisit(on request: Request, conversationID: Conversation.ID) throws -> Future<ConversationVisit.Form> {
        return Conversation.find(conversationID, on: request).unwrap(or: Abort(.notFound)).flatMap { conversation in
            let userID = try request.requiredUserID()

            guard conversation.creatorID == userID || conversation.opponentID == userID else {
                throw Abort(.badRequest, reason: "User is not participant of conversation".localized(on: request))
            }

            return self.firstOrNew(on: request, with: userID, conversationID: conversationID)
                .flatMap { conversationVisit in
                    conversationVisit.visitDate = Date()

                    return conversationVisit.save(on: request).toForm()
            }
        }
    }
}

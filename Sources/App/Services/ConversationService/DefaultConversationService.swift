//
//  DefaultConversationService.swift
//  App
//
//  Created by Timur Shafigullin on 03/02/2019.
//

import Vapor
import FluentPostgreSQL

class DefaultConversationService: ConversationService {
    
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
                        .flatMap { savedConversation in
                            return savedConversation
                                .creator
                                .get(on: request)
                                .and(savedConversation.opponent.get(on: request))
                                .flatMap { (creator, opponent) in
                                    let creatorPublicForm = User.PublicForm(user: creator)
                                    let opponentPublicForm = User.PublicForm(user: opponent)

                                    return request.future(Conversation.Form(id: savedConversation.id,
                                                                            creator: creatorPublicForm,
                                                                            opponent: opponentPublicForm,
                                                                            status: savedConversation.status.rawValue,
                                                                            price: savedConversation.price,
                                                                            debtorID: savedConversation.debtorID))
                        }
                    }
                }
            }
        }
    }
}

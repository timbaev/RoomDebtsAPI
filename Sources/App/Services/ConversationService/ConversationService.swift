//
//  ConversationService.swift
//  App
//
//  Created by Timur Shafigullin on 03/02/2019.
//

import Vapor

protocol ConversationService {
 
    // MARK: - Instance Methods
    
    func create(request: Request, createForm: Conversation.CreateForm) throws -> Future<Conversation.Form>
    func fetch(request: Request) throws -> Future<[Conversation.Form]>
    func delete(on request: Request, conversation: Conversation) throws -> Future<Void>

    func accept(request: Request, conversation: Conversation) throws -> Future<Response>
    func reject(request: Request, conversation: Conversation) throws -> Future<Response>

    func updatePrice(on request: Request, action: PriceAction, debt: Debt, conversation: Conversation) throws -> Future<Conversation>

    func repayAllRequest(on request: Request, conversation: Conversation) throws -> Future<Conversation.Form>
    func deleteRequest(on request: Request, conversation: Conversation) throws -> Future<Conversation.Form>
    func cancelRequest(on request: Request, conversation: Conversation) throws -> Future<Conversation.Form>

    func find(on request: Request, participantIDs: [User.ID]) throws -> Future<Conversation>
}

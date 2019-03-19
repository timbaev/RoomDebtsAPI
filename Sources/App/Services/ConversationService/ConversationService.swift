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

    func accept(request: Request, conversation: Conversation) throws -> Future<Conversation.Form>
    func reject(request: Request, conversation: Conversation) throws -> Future<Void>

    func updatePrice(on request: Request, action: PriceAction, debt: Debt, conversation: Conversation) throws -> Future<Conversation>
}

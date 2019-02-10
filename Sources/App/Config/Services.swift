//
//  Services.swift
//  App
//
//  Created by Timur Shafigullin on 20/01/2019.
//

import Foundation

enum RDServices {
    
    // MARK: - Instance Properties
    
    static let userService: UserService = DefaultUserService(fileService: RDServices.fileService)
    static let fileService: FileService = DefaultFileService()
    static let conversationService: ConversationService = DefaultConversationService()
}

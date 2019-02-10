import Vapor

fileprivate enum BasePath {
    static let users = "v1/account"
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    // MARK: - UserController
    
    let accountController = AccountController(accountService: RDServices.accountService)
    
    try router.register(collection: accountController)
    
    // MARK: - FileController
    
    let fileController = FileController(fileService: RDServices.fileService)
    
    try router.register(collection: fileController)
    
    // MARK: - ConversationController
    
    let conversationController = ConversationController(conversationService: RDServices.conversationService)
    
    try router.register(collection: conversationController)
}

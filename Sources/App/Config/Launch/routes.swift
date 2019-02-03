import Vapor

fileprivate enum BasePath {
    static let users = "v1/account"
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    // MARK: - UserController
    
    let userController = UserController(userService: RDServices.userService)
    
    try router.register(collection: userController)
    
    // MARK: - FileController
    
    let fileController = FileController(fileService: RDServices.fileService)
    
    try router.register(collection: fileController)
}

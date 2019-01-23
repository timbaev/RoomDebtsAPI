import Vapor

fileprivate enum BasePath {
    static let users = "v1/account"
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    let userController = UserController(userService: RDServices.userService)
    
    try router.register(collection: userController)
}

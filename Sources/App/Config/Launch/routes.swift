import Vapor

fileprivate enum BasePath {
    static let users = "users"
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    // MARK: - UserController
    
    let userController = UserController(userService: RDServices.userService)
    
    router.get(BasePath.users, use: userController.index)
    router.post(User.self, at: BasePath.users, use: userController.create)
}

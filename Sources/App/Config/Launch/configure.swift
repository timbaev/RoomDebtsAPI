import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    
    // MARK: - Roter
    
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // MARK: - Middleware
    
    var middleware = MiddlewareConfig()
    
    middleware.use(ErrorMiddleware.self)
    
    services.register(middleware)
    
    // MARK: - PostgreSQL
    
    try services.register(FluentPostgreSQLProvider())
    
    let postgresqlConfig = PostgreSQLDatabaseConfig(
        hostname: "127.0.0.1",
        port: 5432,
        username: "postgres",
        database: "room_debts",
        password: "qwe"
    )
    
    let postgres = PostgreSQLDatabase(config: postgresqlConfig)
    
    var databases = DatabasesConfig()
    
    databases.add(database: postgres, as: .psql)
    services.register(databases)
    
    var migrations = MigrationConfig()
    
    migrations.add(model: User.self, database: .psql)
    
    services.register(migrations)
    
}

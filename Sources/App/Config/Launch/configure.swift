import FluentPostgreSQL
import Vapor
import LingoVapor

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

    let databaseName = (env == .testing) ? "room_debts_test" : "room_debts"
    
    let postgresqlConfig = PostgreSQLDatabaseConfig(
        hostname: "127.0.0.1",
        port: 5432,
        username: "postgres",
        database: databaseName,
        password: "qwe"
    )
    
    let postgres = PostgreSQLDatabase(config: postgresqlConfig)
    
    var databases = DatabasesConfig()
    
    databases.enableLogging(on: .psql)
    databases.add(database: postgres, as: .psql)
    
    services.register(databases)
    
    // MARK: - Migrations
    
    var migrations = MigrationConfig()

    // Models
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: FileRecord.self, database: .psql)
    migrations.add(model: RefreshToken.self, database: .psql)
    migrations.add(model: VerificationCode.self, database: .psql)
    migrations.add(model: Conversation.self, database: .psql)
    migrations.add(model: Debt.self, database: .psql)
    migrations.add(model: Check.self, database: .psql)
    migrations.add(model: Product.self, database: .psql)
    migrations.add(model: CheckProduct.self, database: .psql)
    migrations.add(model: CheckUser.self, database: .psql)
    migrations.add(model: ProductCheckUser.self, database: .psql)
    migrations.add(model: ConversationVisit.self, database: .psql)

    // Migrations
    migrations.add(migration: CheckUser.Status.self, database: .psql)
    migrations.add(migration: Check.Status.self, database: .psql)
    migrations.add(migration: CheckDataFieldsMogration.self, database: .psql)
    migrations.add(migration: CheckUserTotalFieldMigration.self, database: .psql)
    migrations.add(migration: DebtUpdateAtFieldMigration.self, database: .psql)
    
    services.register(migrations)
    
    // MARK: - Commands
    
    var commands = CommandConfig.default()
    commands.useFluentCommands()
    
    services.register(commands)
    
    // MARK: - NIOServerConfig
    
    services.register(NIOServerConfig.default(maxBodySize: 20_000_000))

    // MARK: - LingoVapor

    let lingoProvider = LingoProvider(defaultLocale: "en", localizationsDir: "Localizations")

    try services.register(lingoProvider)
}

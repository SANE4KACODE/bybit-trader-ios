import Foundation

// MARK: - Configuration
struct Config {
    
    // MARK: - Bybit API Configuration
    struct Bybit {
        static let baseURL = "https://api.bybit.com"
        static let testnetURL = "https://api-testnet.bybit.com"
        static let wsURL = "wss://stream.bybit.com"
        static let testnetWSURL = "wss://stream-testnet.bybit.com"
        
        // API Keys - ЗАМЕНИТЕ НА ВАШИ РЕАЛЬНЫЕ КЛЮЧИ
        static let apiKey = "YOUR_BYBIT_API_KEY"
        static let apiSecret = "YOUR_BYBIT_API_SECRET"
        
        // Testnet API Keys для разработки
        static let testnetApiKey = "YOUR_BYBIT_TESTNET_API_KEY"
        static let testnetApiSecret = "YOUR_BYBIT_TESTNET_API_SECRET"
        
        // Настройки по умолчанию
        static let defaultIsTestnet = true
        static let requestTimeout: TimeInterval = 30
        static let maxRetries = 3
        static let retryDelay: TimeInterval = 1
    }
    
    // MARK: - Supabase Configuration
    struct Supabase {
        static let url = "https://koagmtxeomjrymgwnvub.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvYWdtdHhlb21qcnltZ3dudnViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNTg0ODYsImV4cCI6MjA3MDczNDQ4Nn0.n8nsLg_edXrdJmklTA7IDsHXeT9wiDxsjWAkUThrIhM"
        static let serviceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvYWdtdHhlb21qcnltZ3dudnViIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImiaWF0IjoxNzU1MTU4NDg2LCJleHAiOjIwNzAwNzM0NDY2fQ.oeAfTX-vYIpekFqAxT5GtrQ-HQTty31dbfW2SDkNjPY"
        
        // Настройки базы данных
        static let maxRetries = 3
        static let requestTimeout: TimeInterval = 30
        static let batchSize = 100
    }
    
    // MARK: - AI Chat Configuration
    struct AIChat {
        static let apiKey = "sk-UJSfLa_vaSuXl4zi5rVbxw"
        static let baseURL = "https://api.artemox.com"
        static let model = "gpt-4o-mini"
        static let maxTokens = 1000
        static let temperature = 0.7
        static let requestTimeout: TimeInterval = 60
    }
    
    // MARK: - App Configuration
    struct App {
        static let name = "Bybit Trader"
        static let version = "1.0.0"
        static let build = "1"
        static let bundleIdentifier = "com.bybittrader.app"
        
        // Настройки по умолчанию
        static let defaultRefreshInterval: TimeInterval = 30
        static let maxCacheSize = 100 * 1024 * 1024 // 100 MB
        static let maxLogEntries = 1000
        static let maxPriceAlerts = 50
        
        // Настройки безопасности
        static let maxLoginAttempts = 5
        static let lockoutDuration: TimeInterval = 300 // 5 минут
        static let sessionTimeout: TimeInterval = 3600 // 1 час
        
        // Настройки уведомлений
        static let defaultNotificationSound = "default"
        static let quietHoursStart = 22 // 22:00
        static let quietHoursEnd = 8 // 8:00
    }
    
    // MARK: - Subscription Configuration
    struct Subscription {
        static let trialDuration: TimeInterval = 30 * 24 * 60 * 60 // 30 дней
        static let monthlyPrice: Decimal = 299.00
        static let defaultCurrency = "RUB"
        static let defaultCountry = "RU"
        
        // Product IDs для StoreKit
        static let monthlyProductId = "com.bybittrader.monthly"
        static let yearlyProductId = "com.bybittrader.yearly"
        
        // Локализованные цены
        static let localizedPrices: [String: [String: Decimal]] = [
            "RU": ["RUB": 299.00, "USD": 3.99],
            "US": ["USD": 3.99, "EUR": 3.49],
            "EU": ["EUR": 3.49, "USD": 3.99],
            "GB": ["GBP": 2.99, "EUR": 3.49],
            "CA": ["CAD": 4.99, "USD": 3.99]
        ]
    }
    
    // MARK: - Trading Configuration
    struct Trading {
        static let defaultLeverage = 1.0
        static let maxLeverage = 100.0
        static let minOrderSize = 0.001
        static let maxOrderSize = 1000000.0
        
        // Настройки риска
        static let maxPositionSize = 0.1 // 10% от баланса
        static let stopLossPercentage = 0.05 // 5%
        static let takeProfitPercentage = 0.1 // 10%
        
        // Настройки ордеров
        static let defaultOrderTimeout: TimeInterval = 60
        static let maxPendingOrders = 100
        static let orderHistoryLimit = 1000
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let defaultAnimationDuration: Double = 0.3
        static let longAnimationDuration: Double = 0.6
        static let shortAnimationDuration: Double = 0.15
        
        // Цвета темы
        static let primaryColor = "#007AFF"
        static let secondaryColor = "#5856D6"
        static let successColor = "#34C759"
        static let warningColor = "#FF9500"
        static let errorColor = "#FF3B30"
        
        // Размеры
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 8
        static let shadowOpacity: Float = 0.1
        
        // Анимации
        static let springDamping: CGFloat = 0.8
        static let springVelocity: CGFloat = 0.5
    }
    
    // MARK: - Logging Configuration
    struct Logging {
        static let maxFileSize = 10 * 1024 * 1024 // 10 MB
        static let maxLogFiles = 5
        static let logLevel: LogLevel = .info
        
        enum LogLevel: String, CaseIterable {
            case debug = "debug"
            case info = "info"
            case warning = "warning"
            case error = "error"
        }
    }
    
    // MARK: - Cache Configuration
    struct Cache {
        static let maxMemorySize = 50 * 1024 * 1024 // 50 MB
        static let maxDiskSize = 200 * 1024 * 1024 // 200 MB
        static let defaultExpiration: TimeInterval = 300 // 5 минут
        
        // Специфичные настройки кэша
        static let marketDataExpiration: TimeInterval = 30 // 30 секунд
        static let userDataExpiration: TimeInterval = 3600 // 1 час
        static let chartDataExpiration: TimeInterval = 86400 // 24 часа
    }
    
    // MARK: - Network Configuration
    struct Network {
        static let maxConcurrentRequests = 10
        static let requestTimeout: TimeInterval = 30
        static let retryCount = 3
        static let retryDelay: TimeInterval = 1
        
        // Настройки WebSocket
        static let wsReconnectDelay: TimeInterval = 5
        static let wsMaxReconnectAttempts = 10
        static let wsHeartbeatInterval: TimeInterval = 30
        static let wsConnectionTimeout: TimeInterval = 10
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let isRealTimeTradingEnabled = true
        static let isAIChatEnabled = true
        static let isAdvancedAnalyticsEnabled = true
        static let isLearningSystemEnabled = true
        static let isSubscriptionEnabled = true
        static let isBiometricAuthEnabled = true
        static let isAppleSignInEnabled = true
        static let isExportEnabled = true
        static let isNotificationsEnabled = true
        static let isPriceAlertsEnabled = true
    }
    
    // MARK: - Environment Detection
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    static var isProduction: Bool {
        return !isDebug
    }
    
    // MARK: - Dynamic Configuration
    static func getBybitBaseURL(isTestnet: Bool) -> String {
        return isTestnet ? Bybit.testnetURL : Bybit.baseURL
    }
    
    static func getBybitWSURL(isTestnet: Bool) -> String {
        return isTestnet ? Bybit.testnetWSURL : Bybit.wsURL
    }
    
    static func getBybitAPIKey(isTestnet: Bool) -> String {
        return isTestnet ? Bybit.testnetApiKey : Bybit.apiKey
    }
    
    static func getBybitAPISecret(isTestnet: Bool) -> String {
        return isTestnet ? Bybit.testnetApiSecret : Bybit.apiSecret
    }
    
    static func getLocalizedPrice(for country: String, currency: String) -> Decimal? {
        return localizedPrices[country]?[currency]
    }
    
    // MARK: - Validation
    static func validateConfiguration() -> [String] {
        var errors: [String] = []
        
        // Проверяем API ключи
        if Bybit.apiKey == "YOUR_BYBIT_API_KEY" {
            errors.append("Bybit API Key не настроен")
        }
        
        if Bybit.apiSecret == "YOUR_BYBIT_API_SECRET" {
            errors.append("Bybit API Secret не настроен")
        }
        
        if Bybit.testnetApiKey == "YOUR_BYBIT_TESTNET_API_KEY" {
            errors.append("Bybit Testnet API Key не настроен")
        }
        
        if Bybit.testnetApiSecret == "YOUR_BYBIT_TESTNET_API_SECRET" {
            errors.append("Bybit Testnet API Secret не настроен")
        }
        
        // Проверяем Supabase
        if Supabase.url.isEmpty {
            errors.append("Supabase URL не настроен")
        }
        
        if Supabase.anonKey.isEmpty {
            errors.append("Supabase Anonymous Key не настроен")
        }
        
        // Проверяем AI Chat
        if AIChat.apiKey == "sk-UJSfLa_vaSuXl4zi5rVbxw" {
            errors.append("AI Chat API Key не настроен")
        }
        
        return errors
    }
    
    // MARK: - Configuration Helpers
    static func getAppVersion() -> String {
        return "\(App.version) (\(App.build))"
    }
    
    static func getBuildInfo() -> [String: String] {
        return [
            "version": App.version,
            "build": App.build,
            "bundle": App.bundleIdentifier,
            "environment": isDebug ? "Debug" : "Release",
            "simulator": isSimulator ? "Yes" : "No"
        ]
    }
}

// MARK: - Environment Variables
extension Config {
    static func loadFromEnvironment() {
        // Загружаем конфигурацию из переменных окружения
        if let bybitApiKey = ProcessInfo.processInfo.environment["BYBIT_API_KEY"] {
            Bybit.apiKey = bybitApiKey
        }
        
        if let bybitApiSecret = ProcessInfo.processInfo.environment["BYBIT_API_SECRET"] {
            Bybit.apiSecret = bybitApiSecret
        }
        
        if let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] {
            Supabase.url = supabaseUrl
        }
        
        if let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            Supabase.anonKey = supabaseKey
        }
        
        if let aiChatKey = ProcessInfo.processInfo.environment["AI_CHAT_API_KEY"] {
            AIChat.apiKey = aiChatKey
        }
    }
}

// MARK: - Configuration Persistence
extension Config {
    static func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        
        defaults.set(Bybit.defaultIsTestnet, forKey: "bybit_is_testnet")
        defaults.set(App.defaultRefreshInterval, forKey: "app_refresh_interval")
        defaults.set(UI.defaultAnimationDuration, forKey: "ui_animation_duration")
        defaults.set(Logging.logLevel.rawValue, forKey: "logging_level")
        defaults.set(Features.isRealTimeTradingEnabled, forKey: "feature_realtime_trading")
        defaults.set(Features.isAIChatEnabled, forKey: "feature_ai_chat")
    }
    
    static func loadFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        Bybit.defaultIsTestnet = defaults.bool(forKey: "bybit_is_testnet")
        App.defaultRefreshInterval = defaults.double(forKey: "app_refresh_interval")
        UI.defaultAnimationDuration = defaults.double(forKey: "ui_animation_duration")
        
        if let logLevelString = defaults.string(forKey: "logging_level"),
           let logLevel = Logging.LogLevel(rawValue: logLevelString) {
            Logging.logLevel = logLevel
        }
        
        Features.isRealTimeTradingEnabled = defaults.bool(forKey: "feature_realtime_trading")
        Features.isAIChatEnabled = defaults.bool(forKey: "feature_ai_chat")
    }
}

import Foundation
import Supabase

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        let supabaseURL = "https://koagmtxeomjrymgwnvub.supabase.co"
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvYWdtdHhlb21qcnltZ3dudnViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNTg0ODYsImV4cCI6MjA3MDczNDQ4Nn0.n8nsLg_edXrdJmklTA7IDsHXeT9wiDxsjWAkUThrIhM"
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String) async throws -> User {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        return response.user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        return response.user
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - User Management
    func createUserProfile(userId: String, email: String, countryCode: String = "RU", currency: String = "RUB") async throws {
        let userData: [String: Any] = [
            "id": userId,
            "email": email,
            "country_code": countryCode,
            "currency": currency,
            "subscription_status": "trial",
            "subscription_start_date": ISO8601DateFormatter().string(from: Date()),
            "subscription_end_date": ISO8601DateFormatter().string(from: Date().addingTimeInterval(30 * 24 * 60 * 60)),
            "trial_end_date": ISO8601DateFormatter().string(from: Date().addingTimeInterval(30 * 24 * 60 * 60)),
            "monthly_price": getLocalizedPrice(countryCode: countryCode, currency: currency)
        ]
        
        try await client.database
            .from("users")
            .insert(userData)
            .execute()
    }
    
    func getUserProfile(userId: String) async throws -> UserProfile? {
        let response = try await client.database
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
        
        return try response.decoded(to: UserProfile.self)
    }
    
    func updateSubscriptionStatus(userId: String, status: String, endDate: Date?) async throws {
        var updateData: [String: Any] = ["subscription_status": status]
        
        if let endDate = endDate {
            updateData["subscription_end_date"] = ISO8601DateFormatter().string(from: endDate)
        }
        
        try await client.database
            .from("users")
            .update(updateData)
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Trades Management
    func saveTrade(_ trade: Trade) async throws {
        let tradeData = try trade.toDictionary()
        
        try await client.database
            .from("trades")
            .insert(tradeData)
            .execute()
    }
    
    func getTrades(userId: String, limit: Int = 100, offset: Int = 0) async throws -> [Trade] {
        let response = try await client.database
            .from("trades")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
        
        return try response.decoded(to: [Trade].self)
    }
    
    func updateTrade(_ trade: Trade) async throws {
        let tradeData = try trade.toDictionary()
        
        try await client.database
            .from("trades")
            .update(tradeData)
            .eq("id", value: trade.id)
            .execute()
    }
    
    func deleteTrade(tradeId: String) async throws {
        try await client.database
            .from("trades")
            .delete()
            .eq("id", value: tradeId)
            .execute()
    }
    
    // MARK: - Positions Management
    func savePosition(_ position: Position) async throws {
        let positionData = try position.toDictionary()
        
        try await client.database
            .from("positions")
            .insert(positionData)
            .execute()
    }
    
    func getPositions(userId: String) async throws -> [Position] {
        let response = try await client.database
            .from("positions")
            .select()
            .eq("user_id", value: userId)
            .eq("status", value: "open")
            .execute()
        
        return try response.decoded(to: [Position].self)
    }
    
    // MARK: - Balances Management
    func saveBalance(_ balance: Balance) async throws {
        let balanceData = try balance.toDictionary()
        
        try await client.database
            .from("balances")
            .upsert(balanceData, onConflict: "user_id,currency")
            .execute()
    }
    
    func getBalances(userId: String) async throws -> [Balance] {
        let response = try await client.database
            .from("balances")
            .select()
            .eq("user_id", value: userId)
            .execute()
        
        return try response.decoded(to: [Balance].self)
    }
    
    // MARK: - User Settings
    func saveUserSettings(_ settings: UserSettings) async throws {
        let settingsData = try settings.toDictionary()
        
        try await client.database
            .from("user_settings")
            .upsert(settingsData, onConflict: "user_id")
            .execute()
    }
    
    func getUserSettings(userId: String) async throws -> UserSettings? {
        let response = try await client.database
            .from("user_settings")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
        
        return try response.decoded(to: UserSettings.self)
    }
    
    // MARK: - Analytics
    func generateTradingReport(userId: String, startDate: Date, endDate: Date) async throws -> TradingReport {
        let startDateStr = ISO8601DateFormatter().string(from: startDate)
        let endDateStr = ISO8601DateFormatter().string(from: endDate)
        
        let response = try await client.database
            .from("trades")
            .select()
            .eq("user_id", value: userId)
            .gte("created_at", value: startDateStr)
            .lte("created_at", value: endDateStr)
            .execute()
        
        let trades = try response.decoded(to: [Trade].self)
        return TradingReport.generate(from: trades, startDate: startDate, endDate: endDate)
    }
    
    // MARK: - Export Functions
    func exportTradesToCSV(userId: String, startDate: Date, endDate: Date) async throws -> String {
        let trades = try await getTrades(userId: userId, limit: 10000)
        
        let filteredTrades = trades.filter { trade in
            trade.createdAt >= startDate && trade.createdAt <= endDate
        }
        
        return generateCSV(from: filteredTrades)
    }
    
    // MARK: - Helper Functions
    private func getLocalizedPrice(countryCode: String, currency: String) -> Decimal {
        switch (countryCode, currency) {
        case ("RU", "RUB"):
            return 299.00
        case ("US", "USD"):
            return 3.99
        case ("EU", "EUR"):
            return 3.49
        case ("GB", "GBP"):
            return 2.99
        default:
            return 299.00
        }
    }
    
    private func generateCSV(from trades: [Trade]) -> String {
        let headers = "Дата,Символ,Сторона,Тип,Количество,Цена,Сумма,Комиссия,Статус,Заметки\n"
        
        let rows = trades.map { trade in
            let date = ISO8601DateFormatter().string(from: trade.createdAt)
            let side = trade.side == "buy" ? "Покупка" : "Продажа"
            let type = trade.orderType == "market" ? "Рыночный" : "Лимитный"
            let amount = trade.quantity * trade.price
            let notes = trade.notes ?? ""
            
            return "\(date),\(trade.symbol),\(side),\(type),\(trade.quantity),\(trade.price),\(amount),\(trade.fee),\(trade.status),\(notes)"
        }.joined(separator: "\n")
        
        return headers + rows
    }
}

// MARK: - Models
struct UserProfile: Codable {
    let id: String
    let email: String
    let subscriptionStatus: String
    let subscriptionStartDate: String
    let subscriptionEndDate: String
    let trialEndDate: String
    let countryCode: String
    let currency: String
    let monthlyPrice: Decimal
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case subscriptionStatus = "subscription_status"
        case subscriptionStartDate = "subscription_start_date"
        case subscriptionEndDate = "subscription_end_date"
        case trialEndDate = "trial_end_date"
        case countryCode = "country_code"
        case currency, monthlyPrice = "monthly_price"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Trade: Codable, Identifiable {
    let id: String
    let userId: String
    let symbol: String
    let side: String
    let orderType: String
    let quantity: Decimal
    let price: Decimal
    let executedPrice: Decimal?
    let totalAmount: Decimal?
    let fee: Decimal
    let status: String
    let orderId: String?
    let bybitOrderId: String?
    let notes: String?
    let tags: [String]?
    let createdAt: Date
    let executedAt: Date?
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case symbol, side
        case orderType = "order_type"
        case quantity, price
        case executedPrice = "executed_price"
        case totalAmount = "total_amount"
        case fee, status
        case orderId = "order_id"
        case bybitOrderId = "bybit_order_id"
        case notes, tags
        case createdAt = "created_at"
        case executedAt = "executed_at"
        case updatedAt = "updated_at"
    }
    
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return dict
    }
}

struct Position: Codable, Identifiable {
    let id: String
    let userId: String
    let symbol: String
    let side: String
    let quantity: Decimal
    let entryPrice: Decimal
    let currentPrice: Decimal?
    let unrealizedPnl: Decimal?
    let realizedPnl: Decimal?
    let leverage: Int
    let margin: Decimal?
    let liquidationPrice: Decimal?
    let status: String
    let openedAt: Date
    let closedAt: Date?
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case symbol, side, quantity
        case entryPrice = "entry_price"
        case currentPrice = "current_price"
        case unrealizedPnl = "unrealized_pnl"
        case realizedPnl = "realized_pnl"
        case leverage, margin
        case liquidationPrice = "liquidation_price"
        case status
        case openedAt = "opened_at"
        case closedAt = "closed_at"
        case updatedAt = "updated_at"
    }
    
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return dict
    }
}

struct Balance: Codable, Identifiable {
    let id: String
    let userId: String
    let currency: String
    let availableBalance: Decimal
    let totalBalance: Decimal
    let frozenBalance: Decimal
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currency
        case availableBalance = "available_balance"
        case totalBalance = "total_balance"
        case frozenBalance = "frozen_balance"
        case updatedAt = "updated_at"
    }
    
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return dict
    }
}

struct UserSettings: Codable {
    let id: String
    let userId: String
    let apiKey: String?
    let apiSecret: String?
    let testnet: Bool
    let autoRefresh: Bool
    let refreshInterval: Int
    let notificationsEnabled: Bool
    let darkModeEnabled: Bool
    let biometricAuthEnabled: Bool
    let selectedSymbols: [String]
    let riskLevel: String
    let maxPositionSize: Decimal
    let stopLossPercentage: Decimal
    let takeProfitPercentage: Decimal
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case apiKey = "api_key"
        case apiSecret = "api_secret"
        case testnet
        case autoRefresh = "auto_refresh"
        case refreshInterval = "refresh_interval"
        case notificationsEnabled = "notifications_enabled"
        case darkModeEnabled = "dark_mode_enabled"
        case biometricAuthEnabled = "biometric_auth_enabled"
        case selectedSymbols = "selected_symbols"
        case riskLevel = "risk_level"
        case maxPositionSize = "max_position_size"
        case stopLossPercentage = "stop_loss_percentage"
        case takeProfitPercentage = "take_profit_percentage"
        case updatedAt = "updated_at"
    }
    
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return dict
    }
}

struct TradingReport: Codable {
    let id: String
    let userId: String
    let reportType: String
    let startDate: String
    let endDate: String
    let totalTrades: Int
    let winningTrades: Int
    let losingTrades: Int
    let totalPnl: Decimal
    let winRate: Decimal
    let averageWin: Decimal
    let averageLoss: Decimal
    let maxDrawdown: Decimal
    let sharpeRatio: Decimal?
    let reportData: [String: Any]?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case reportType = "report_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case totalTrades = "total_trades"
        case winningTrades = "winning_trades"
        case losingTrades = "losing_trades"
        case totalPnl = "total_pnl"
        case winRate = "win_rate"
        case averageWin = "average_win"
        case averageLoss = "average_loss"
        case maxDrawdown = "max_drawdown"
        case sharpeRatio = "sharpe_ratio"
        case reportData = "report_data"
        case createdAt = "created_at"
    }
    
    static func generate(from trades: [Trade], startDate: Date, endDate: Date) -> TradingReport {
        let totalTrades = trades.count
        let winningTrades = trades.filter { $0.totalAmount ?? 0 > 0 }.count
        let losingTrades = trades.filter { $0.totalAmount ?? 0 < 0 }.count
        
        let totalPnl = trades.compactMap { $0.totalAmount }.reduce(0, +)
        let winRate = totalTrades > 0 ? Decimal(winningTrades) / Decimal(totalTrades) * 100 : 0
        
        let winningAmounts = trades.compactMap { $0.totalAmount }.filter { $0 > 0 }
        let losingAmounts = trades.compactMap { $0.totalAmount }.filter { $0 < 0 }
        
        let averageWin = winningAmounts.isEmpty ? 0 : winningAmounts.reduce(0, +) / Decimal(winningAmounts.count)
        let averageLoss = losingAmounts.isEmpty ? 0 : losingAmounts.reduce(0, +) / Decimal(losingAmounts.count)
        
        // Простой расчет максимальной просадки
        var maxDrawdown: Decimal = 0
        var runningTotal: Decimal = 0
        var peak: Decimal = 0
        
        for trade in trades.sorted(by: { $0.createdAt < $1.createdAt }) {
            runningTotal += trade.totalAmount ?? 0
            if runningTotal > peak {
                peak = runningTotal
            }
            let drawdown = peak - runningTotal
            if drawdown > maxDrawdown {
                maxDrawdown = drawdown
            }
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        return TradingReport(
            id: UUID().uuidString,
            userId: trades.first?.userId ?? "",
            reportType: "custom",
            startDate: dateFormatter.string(from: startDate),
            endDate: dateFormatter.string(from: endDate),
            totalTrades: totalTrades,
            winningTrades: winningTrades,
            losingTrades: losingTrades,
            totalPnl: totalPnl,
            winRate: winRate,
            averageWin: averageWin,
            averageLoss: averageLoss,
            maxDrawdown: maxDrawdown,
            sharpeRatio: nil,
            reportData: nil,
            createdAt: dateFormatter.string(from: Date())
        )
    }
}

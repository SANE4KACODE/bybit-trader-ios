import Foundation

// MARK: - Balance Models
struct Balance: Codable, Identifiable {
    let id = UUID()
    let coin: String
    let walletBalance: String
    let availableBalance: String
    let unrealizedPnl: String
    let marginBalance: String
    
    enum CodingKeys: String, CodingKey {
        case coin
        case walletBalance = "walletBalance"
        case availableBalance = "availableBalance"
        case unrealizedPnl = "unrealizedPnl"
        case marginBalance = "marginBalance"
    }
}

struct BalanceResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: BalanceResult
}

struct BalanceResult: Codable {
    let list: [Balance]
}

// MARK: - Position Models
struct Position: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let side: String
    let size: String
    let entryPrice: String
    let markPrice: String
    let unrealizedPnl: String
    let leverage: String
    let marginType: String
    let positionValue: String
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case side
        case size
        case entryPrice = "entryPrice"
        case markPrice = "markPrice"
        case unrealizedPnl = "unrealizedPnl"
        case leverage
        case marginType = "marginType"
        case positionValue = "positionValue"
    }
}

struct PositionResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: PositionResult
}

struct PositionResult: Codable {
    let list: [Position]
}

// MARK: - Trading Models
struct OrderRequest: Codable {
    let symbol: String
    let side: String
    let orderType: String
    let qty: String
    let price: String?
    let timeInForce: String
    let category: String
}

struct OrderResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: OrderResult
}

struct OrderResult: Codable {
    let orderId: String
    let orderLinkId: String
}

// MARK: - Order History Models
struct OrderHistory: Codable, Identifiable {
    let id = UUID()
    let orderId: String
    let symbol: String
    let side: String
    let orderType: String
    let qty: String
    let price: String
    let status: String
    let createTime: String
    let updateTime: String
    let executedQty: String
    let avgPrice: String
    
    enum CodingKeys: String, CodingKey {
        case orderId = "orderId"
        case symbol
        case side
        case orderType = "orderType"
        case qty
        case price
        case status
        case createTime = "createTime"
        case updateTime = "updateTime"
        case executedQty = "executedQty"
        case avgPrice = "avgPrice"
    }
}

struct OrderHistoryResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: OrderHistoryResult
}

struct OrderHistoryResult: Codable {
    let list: [OrderHistory]
}

// MARK: - Market Data Models
struct TickerData: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let lastPrice: String
    let prevPrice24h: String
    let price24hPcnt: String
    let highPrice24h: String
    let lowPrice24h: String
    let turnover24h: String
    let volume24h: String
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case lastPrice = "lastPrice"
        case prevPrice24h = "prevPrice24h"
        case price24hPcnt = "price24hPcnt"
        case highPrice24h = "highPrice24h"
        case lowPrice24h = "lowPrice24h"
        case turnover24h = "turnover24h"
        case volume24h = "volume24h"
    }
}

struct TickerResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: TickerResult
}

struct TickerResult: Codable {
    let list: [TickerData]
}

// MARK: - Chart Data Models
struct ChartData: Codable, Identifiable {
    let id = UUID()
    let timestamp: Int
    let open: String
    let high: String
    let low: String
    let close: String
    let volume: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case open
        case high
        case low
        case close
        case volume
    }
}

struct ChartResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: ChartResult
}

struct ChartResult: Codable {
    let list: [ChartData]
}

// MARK: - User Settings
struct UserSettings: Codable {
    var apiKey: String = ""
    var secretKey: String = ""
    var testnet: Bool = true
    var selectedSymbol: String = "BTCUSDT"
    var autoRefresh: Bool = true
    var refreshInterval: Int = 30 // секунды
    var notificationsEnabled: Bool = false
    var darkModeEnabled: Bool = false
    var biometricAuthEnabled: Bool = false
}

// MARK: - Notification Settings
struct NotificationSettings: Codable {
    var priceAlerts: Bool = false
    var orderExecuted: Bool = true
    var positionClosed: Bool = true
    var balanceChanges: Bool = false
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
}

// MARK: - Enums
enum OrderSide: String, CaseIterable {
    case buy = "Buy"
    case sell = "Sell"
    
    var displayName: String {
        switch self {
        case .buy: return "Покупка"
        case .sell: return "Продажа"
        }
    }
    
    var color: String {
        switch self {
        case .buy: return "green"
        case .sell: return "red"
        }
    }
}

enum OrderType: String, CaseIterable {
    case market = "Market"
    case limit = "Limit"
    
    var displayName: String {
        switch self {
        case .market: return "Рыночный"
        case .limit: return "Лимитный"
        }
    }
}

enum TimeInForce: String, CaseIterable {
    case gtc = "GTC"
    case ioc = "IOC"
    case fok = "FOK"
    
    var displayName: String {
        switch self {
        case .gtc: return "До отмены"
        case .ioc: return "Немедленно или отмена"
        case .fok: return "Заполнить или убить"
        }
    }
}

enum OrderStatus: String, CaseIterable {
    case pending = "Pending"
    case filled = "Filled"
    case cancelled = "Cancelled"
    case rejected = "Rejected"
    
    var displayName: String {
        switch self {
        case .pending: return "В ожидании"
        case .filled: return "Исполнен"
        case .cancelled: return "Отменен"
        case .rejected: return "Отклонен"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .filled: return "green"
        case .cancelled: return "gray"
        case .rejected: return "red"
        }
    }
}

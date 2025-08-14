import Foundation
import CryptoKit

class BybitAPIService: ObservableObject {
    static let shared = BybitAPIService()
    
    // MARK: - Configuration
    private var apiKey: String = ""
    private var apiSecret: String = ""
    private var isTestnet: Bool = true
    
    private var baseURL: String {
        isTestnet ? "https://api-testnet.bybit.com" : "https://api.bybit.com"
    }
    
    // MARK: - Initialization
    private init() {}
    
    func configure(apiKey: String, apiSecret: String, isTestnet: Bool = true) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.isTestnet = isTestnet
    }
    
    // MARK: - Authentication
    private func generateSignature(timestamp: String, recvWindow: String, queryString: String) -> String {
        let signString = timestamp + apiKey + recvWindow + queryString
        let signature = HMAC<SHA256>.authenticationCode(for: Data(signString.utf8), using: Data(apiSecret.utf8))
        return Data(signature).map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func createHeaders(method: String, queryString: String = "") -> [String: String] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let recvWindow = "5000"
        let signature = generateSignature(timestamp: timestamp, recvWindow: recvWindow, queryString: queryString)
        
        return [
            "X-BAPI-API-KEY": apiKey,
            "X-BAPI-SIGNATURE": signature,
            "X-BAPI-TIMESTAMP": timestamp,
            "X-BAPI-RECV-WINDOW": recvWindow,
            "Content-Type": "application/json"
        ]
    }
    
    // MARK: - Account Information
    func getWalletBalance() async throws -> WalletBalanceResponse {
        let endpoint = "/v5/account/wallet-balance"
        let url = URL(string: baseURL + endpoint)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = createHeaders(method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BybitAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(WalletBalanceResponse.self, from: data)
    }
    
    // MARK: - Positions
    func getPositions(symbol: String? = nil) async throws -> PositionResponse {
        var endpoint = "/v5/position/list"
        if let symbol = symbol {
            endpoint += "?symbol=\(symbol)"
        }
        
        let url = URL(string: baseURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = createHeaders(method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BybitAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(PositionResponse.self, from: data)
    }
    
    // MARK: - Trading
    func placeOrder(symbol: String, side: OrderSide, orderType: OrderType, qty: String, price: String? = nil) async throws -> OrderResponse {
        let endpoint = "/v5/order/create"
        let url = URL(string: baseURL + endpoint)!
        
        var orderData: [String: Any] = [
            "symbol": symbol,
            "side": side.rawValue,
            "orderType": orderType.rawValue,
            "qty": qty,
            "category": "linear"
        ]
        
        if let price = price {
            orderData["price"] = price
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: orderData)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.allHTTPHeaderFields = createHeaders(method: "POST")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BybitAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(OrderResponse.self, from: data)
    }
    
    func cancelOrder(symbol: String, orderId: String) async throws -> CancelOrderResponse {
        let endpoint = "/v5/order/cancel"
        let url = URL(string: baseURL + endpoint)!
        
        let cancelData: [String: Any] = [
            "symbol": symbol,
            "orderId": orderId,
            "category": "linear"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: cancelData)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.allHTTPHeaderFields = createHeaders(method: "POST")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BybitAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(CancelOrderResponse.self, from: data)
    }
    
    // MARK: - Market Data
    func getKlineData(symbol: String, interval: KlineInterval, limit: Int = 200) async throws -> KlineResponse {
        let endpoint = "/v5/market/kline?symbol=\(symbol)&interval=\(interval.rawValue)&limit=\(limit)"
        let url = URL(string: baseURL + endpoint)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BybitAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(KlineResponse.self, from: data)
    }
    
    func getTickerInfo(symbol: String) async throws -> TickerResponse {
        let endpoint = "/v5/market/tickers?symbol=\(symbol)"
        let url = URL(string: baseURL + endpoint)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BybitAPIError.requestFailed
        }
        
        return try JSONDecoder().decode(TickerResponse.self, from: data)
    }
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
}

enum OrderType: String, CaseIterable {
    case market = "Market"
    case limit = "Limit"
    case stop = "Stop"
    case stopLimit = "StopLimit"
    
    var displayName: String {
        switch self {
        case .market: return "Рыночный"
        case .limit: return "Лимитный"
        case .stop: return "Стоп"
        case .stopLimit: return "Стоп-лимит"
        }
    }
}

enum KlineInterval: String, CaseIterable {
    case m1 = "1"
    case m3 = "3"
    case m5 = "5"
    case m15 = "15"
    case m30 = "30"
    case h1 = "60"
    case h2 = "120"
    case h4 = "240"
    case h6 = "360"
    case h8 = "480"
    case h12 = "720"
    case d1 = "D"
    case w1 = "W"
    case month1 = "M"
    
    var displayName: String {
        switch self {
        case .m1: return "1м"
        case .m3: return "3м"
        case .m5: return "5м"
        case .m15: return "15м"
        case .m30: return "30м"
        case .h1: return "1ч"
        case .h2: return "2ч"
        case .h4: return "4ч"
        case .h6: return "6ч"
        case .h8: return "8ч"
        case .h12: return "12ч"
        case .d1: return "1д"
        case .w1: return "1н"
        case .month1: return "1м"
        }
    }
}

// MARK: - Response Models
struct WalletBalanceResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: WalletBalanceResult
    
    enum CodingKeys: String, CodingKey {
        case retCode = "retCode"
        case retMsg = "retMsg"
        case result
    }
}

struct WalletBalanceResult: Codable {
    let list: [WalletBalance]
}

struct WalletBalance: Codable, Identifiable {
    let id = UUID()
    let accountType: String
    let coin: [CoinBalance]
    
    enum CodingKeys: String, CodingKey {
        case accountType = "accountType"
        case coin
    }
}

struct CoinBalance: Codable, Identifiable {
    let id = UUID()
    let coin: String
    let walletBalance: String
    let availableToWithdraw: String
    let availableToSend: String
    
    enum CodingKeys: String, CodingKey {
        case coin, walletBalance, availableToWithdraw, availableToSend
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

struct Position: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let side: String
    let size: String
    let entryPrice: String
    let markPrice: String
    let unrealizedPnl: String
    let leverage: String
    let margin: String
    
    enum CodingKeys: String, CodingKey {
        case symbol, side, size, entryPrice, markPrice, unrealizedPnl, leverage, margin
    }
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

struct CancelOrderResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: CancelOrderResult
}

struct CancelOrderResult: Codable {
    let orderId: String
}

struct KlineResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: KlineResult
}

struct KlineResult: Codable {
    let category: String
    let symbol: String
    let list: [[String]]
}

struct TickerResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: TickerResult
}

struct TickerResult: Codable {
    let category: String
    let list: [TickerInfo]
}

struct TickerInfo: Codable, Identifiable {
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
        case symbol, lastPrice, prevPrice24h, price24hPcnt, highPrice24h, lowPrice24h, turnover24h, volume24h
    }
}

enum BybitAPIError: Error, LocalizedError {
    case requestFailed
    case invalidResponse
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .requestFailed:
            return "Ошибка при выполнении запроса к Bybit API"
        case .invalidResponse:
            return "Неверный ответ от сервера"
        case .authenticationFailed:
            return "Ошибка аутентификации"
        }
    }
}

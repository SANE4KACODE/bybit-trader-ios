import Foundation
import CryptoKit

class BybitService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    private var apiKey: String = ""
    private var secretKey: String = ""
    private var baseURL: String = "https://api-testnet.bybit.com" // Testnet по умолчанию
    
    // Кэш для данных
    private var balanceCache: [Balance] = []
    private var positionsCache: [Position] = []
    private var tickerCache: [String: TickerData] = [:]
    private var orderHistoryCache: [OrderHistory] = []
    
    // Таймер для автообновления
    private var autoRefreshTimer: Timer?
    
    // MARK: - Configuration
    func configure(apiKey: String, secretKey: String, testnet: Bool) {
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.baseURL = testnet ? "https://api-testnet.bybit.com" : "https://api.bybit.com"
        self.isAuthenticated = !apiKey.isEmpty && !secretKey.isEmpty
        
        if isAuthenticated {
            startAutoRefresh()
        } else {
            stopAutoRefresh()
        }
    }
    
    // MARK: - Auto Refresh
    func startAutoRefresh() {
        stopAutoRefresh()
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshAllData()
            }
        }
    }
    
    func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
    
    private func refreshAllData() async {
        do {
            async let balanceTask = fetchBalance()
            async let positionsTask = fetchPositions()
            
            let (balances, positions) = try await (balanceTask, positionsTask)
            
            await MainActor.run {
                self.balanceCache = balances
                self.positionsCache = positions
                self.lastUpdateTime = Date()
            }
        } catch {
            print("Ошибка автообновления: \(error)")
        }
    }
    
    // MARK: - Authentication
    private func generateSignature(timestamp: String, queryString: String) -> String {
        let param = timestamp + apiKey + "5000" + queryString
        let signature = HMAC<SHA256>.authenticationCode(for: param.data(using: .utf8)!, using: SymmetricKey(data: secretKey.data(using: .utf8)!))
        return signature.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Balance
    func fetchBalance() async throws -> [Balance] {
        let endpoint = "/v5/account/wallet-balance"
        let queryString = "accountType=UNIFIED"
        
        let url = URL(string: baseURL + endpoint + "?" + queryString)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-BAPI-API-KEY")
        
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let signature = generateSignature(timestamp: timestamp, queryString: queryString)
        
        request.setValue(timestamp, forHTTPHeaderField: "X-BAPI-TIMESTAMP")
        request.setValue(signature, forHTTPHeaderField: "X-BAPI-SIGN")
        request.setValue("5000", forHTTPHeaderField: "X-BAPI-RECV-WINDOW")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BybitError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 401 {
                throw BybitError.authenticationError
            } else {
                throw BybitError.invalidResponse
            }
        }
        
        let balanceResponse = try JSONDecoder().decode(BalanceResponse.self, from: data)
        
        if balanceResponse.retCode != 0 {
            throw BybitError.apiError(balanceResponse.retMsg)
        }
        
        await MainActor.run {
            self.balanceCache = balanceResponse.result.list
            self.lastUpdateTime = Date()
        }
        
        return balanceResponse.result.list
    }
    
    // MARK: - Positions
    func fetchPositions() async throws -> [Position] {
        let endpoint = "/v5/position/list"
        let queryString = "category=linear&settleCoin=USDT"
        
        let url = URL(string: baseURL + endpoint + "?" + queryString)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-BAPI-API-KEY")
        
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let signature = generateSignature(timestamp: timestamp, queryString: queryString)
        
        request.setValue(timestamp, forHTTPHeaderField: "X-BAPI-TIMESTAMP")
        request.setValue(signature, forHTTPHeaderField: "X-BAPI-SIGN")
        request.setValue("5000", forHTTPHeaderField: "X-BAPI-RECV-WINDOW")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BybitError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 401 {
                throw BybitError.authenticationError
            } else {
                throw BybitError.invalidResponse
            }
        }
        
        let positionResponse = try JSONDecoder().decode(PositionResponse.self, from: data)
        
        if positionResponse.retCode != 0 {
            throw BybitError.apiError(positionResponse.retMsg)
        }
        
        await MainActor.run {
            self.positionsCache = positionResponse.result.list
            self.lastUpdateTime = Date()
        }
        
        return positionResponse.result.list
    }
    
    // MARK: - Market Data
    func fetchTicker(symbol: String) async throws -> TickerData? {
        // Проверяем кэш
        if let cachedTicker = tickerCache[symbol] {
            return cachedTicker
        }
        
        let endpoint = "/v5/market/tickers"
        let queryString = "category=linear&symbol=\(symbol)"
        
        let url = URL(string: baseURL + endpoint + "?" + queryString)!
        let request = URLRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BybitError.networkError
        }
        
        let tickerResponse = try JSONDecoder().decode(TickerResponse.self, from: data)
        
        if tickerResponse.retCode != 0 {
            throw BybitError.apiError(tickerResponse.retMsg)
        }
        
        let ticker = tickerResponse.result.list.first
        
        if let ticker = ticker {
            await MainActor.run {
                self.tickerCache[symbol] = ticker
            }
        }
        
        return ticker
    }
    
    // MARK: - Chart Data
    func fetchChartData(symbol: String, interval: String = "1", limit: Int = 200) async throws -> [ChartData] {
        let endpoint = "/v5/market/kline"
        let queryString = "category=linear&symbol=\(symbol)&interval=\(interval)&limit=\(limit)"
        
        let url = URL(string: baseURL + endpoint + "?" + queryString)!
        let request = URLRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BybitError.networkError
        }
        
        let chartResponse = try JSONDecoder().decode(ChartResponse.self, from: data)
        
        if chartResponse.retCode != 0 {
            throw BybitError.apiError(chartResponse.retMsg)
        }
        
        return chartResponse.result.list
    }
    
    // MARK: - Order History
    func fetchOrderHistory(symbol: String? = nil, limit: Int = 50) async throws -> [OrderHistory] {
        let endpoint = "/v5/order/realtime"
        var queryString = "category=linear&limit=\(limit)"
        
        if let symbol = symbol {
            queryString += "&symbol=\(symbol)"
        }
        
        let url = URL(string: baseURL + endpoint + "?" + queryString)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-BAPI-API-KEY")
        
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let signature = generateSignature(timestamp: timestamp, queryString: queryString)
        
        request.setValue(timestamp, forHTTPHeaderField: "X-BAPI-TIMESTAMP")
        request.setValue(signature, forHTTPHeaderField: "X-BAPI-SIGN")
        request.setValue("5000", forHTTPHeaderField: "X-BAPI-RECV-WINDOW")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BybitError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 401 {
                throw BybitError.authenticationError
            } else {
                throw BybitError.invalidResponse
            }
        }
        
        let orderResponse = try JSONDecoder().decode(OrderHistoryResponse.self, from: data)
        
        if orderResponse.retCode != 0 {
            throw BybitError.apiError(orderResponse.retMsg)
        }
        
        await MainActor.run {
            self.orderHistoryCache = orderResponse.result.list
        }
        
        return orderResponse.result.list
    }
    
    // MARK: - Trading
    func placeOrder(symbol: String, side: String, orderType: String, qty: String, price: String?, timeInForce: String) async throws -> OrderResult {
        let endpoint = "/v5/order/create"
        
        var body: [String: Any] = [
            "category": "linear",
            "symbol": symbol,
            "side": side,
            "orderType": orderType,
            "qty": qty,
            "timeInForce": timeInForce
        ]
        
        if let price = price, orderType == "Limit" {
            body["price"] = price
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        let url = URL(string: baseURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-BAPI-API-KEY")
        request.httpBody = jsonData
        
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let queryString = String(data: jsonData, encoding: .utf8) ?? ""
        let signature = generateSignature(timestamp: timestamp, queryString: queryString)
        
        request.setValue(timestamp, forHTTPHeaderField: "X-BAPI-TIMESTAMP")
        request.setValue(signature, forHTTPHeaderField: "X-BAPI-SIGN")
        request.setValue("5000", forHTTPHeaderField: "X-BAPI-RECV-WINDOW")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BybitError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 401 {
                throw BybitError.authenticationError
            } else {
                throw BybitError.invalidResponse
            }
        }
        
        let orderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
        
        if orderResponse.retCode != 0 {
            throw BybitError.apiError(orderResponse.retMsg)
        }
        
        // Очищаем кэш после размещения ордера
        await MainActor.run {
            self.balanceCache.removeAll()
            self.positionsCache.removeAll()
        }
        
        return orderResponse.result
    }
    
    // MARK: - Close Position
    func closePosition(symbol: String, side: String, qty: String) async throws -> OrderResult {
        let closeSide = side == "Buy" ? "Sell" : "Buy"
        return try await placeOrder(
            symbol: symbol,
            side: closeSide,
            orderType: "Market",
            qty: qty,
            price: nil,
            timeInForce: "IOC"
        )
    }
    
    // MARK: - Cancel Order
    func cancelOrder(symbol: String, orderId: String) async throws -> Bool {
        let endpoint = "/v5/order/cancel"
        let body: [String: Any] = [
            "category": "linear",
            "symbol": symbol,
            "orderId": orderId
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        let url = URL(string: baseURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-BAPI-API-KEY")
        request.httpBody = jsonData
        
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let queryString = String(data: jsonData, encoding: .utf8) ?? ""
        let signature = generateSignature(timestamp: timestamp, queryString: queryString)
        
        request.setValue(timestamp, forHTTPHeaderField: "X-BAPI-TIMESTAMP")
        request.setValue(signature, forHTTPHeaderField: "X-BAPI-SIGN")
        request.setValue("5000", forHTTPHeaderField: "X-BAPI-RECV-WINDOW")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BybitError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 401 {
                throw BybitError.authenticationError
            } else {
                throw BybitError.invalidResponse
            }
        }
        
        // Очищаем кэш после отмены ордера
        await MainActor.run {
            self.orderHistoryCache.removeAll()
        }
        
        return true
    }
    
    // MARK: - Cache Management
    func clearCache() {
        balanceCache.removeAll()
        positionsCache.removeAll()
        tickerCache.removeAll()
        orderHistoryCache.removeAll()
    }
    
    func getCachedBalance() -> [Balance] {
        return balanceCache
    }
    
    func getCachedPositions() -> [Position] {
        return positionsCache
    }
    
    func getCachedTicker(for symbol: String) -> TickerData? {
        return tickerCache[symbol]
    }
    
    func getCachedOrderHistory() -> [OrderHistory] {
        return orderHistoryCache
    }
}

// MARK: - Errors
enum BybitError: Error, LocalizedError {
    case networkError
    case authenticationError
    case invalidResponse
    case insufficientBalance
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Ошибка сети. Проверьте подключение к интернету."
        case .authenticationError:
            return "Ошибка аутентификации. Проверьте API ключи."
        case .invalidResponse:
            return "Неверный ответ от сервера."
        case .insufficientBalance:
            return "Недостаточно средств для выполнения операции."
        case .apiError(let message):
            return "Ошибка API: \(message)"
        }
    }
}

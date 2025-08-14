import Foundation
import Combine
import CryptoKit

class RealTimeBybitService: ObservableObject {
    static let shared = RealTimeBybitService()
    
    // MARK: - Published Properties
    @Published var walletBalance: WalletBalance?
    @Published var positions: [Position] = []
    @Published var tickers: [TickerInfo] = []
    @Published var orderHistory: [OrderInfo] = []
    @Published var klineData: [KlineData] = []
    @Published var isConnected = false
    @Published var connectionStatus = "Отключено"
    @Published var lastUpdateTime = Date()
    
    // MARK: - Private Properties
    private var apiKey: String = ""
    private var apiSecret: String = ""
    private var isTestnet: Bool = true
    private var baseURL: String {
        return isTestnet ? "https://api-testnet.bybit.com" : "https://api.bybit.com"
    }
    private var wsURL: String {
        return isTestnet ? "wss://stream-testnet.bybit.com" : "wss://stream.bybit.com"
    }
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var cancellables = Set<AnyCancellable>()
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    
    // MARK: - Caching
    private let cache = NSCache<NSString, CachedData>()
    private let cacheExpiration: TimeInterval = 30 // 30 seconds
    
    // MARK: - Logging
    private let loggingService = LoggingService.shared
    
    private init() {
        setupCaching()
        setupPublishers()
    }
    
    // MARK: - Configuration
    func configure(apiKey: String, apiSecret: String, isTestnet: Bool = true) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.isTestnet = isTestnet
        
        loggingService.info("RealTimeBybitService configured", category: "bybit", metadata: [
            "isTestnet": isTestnet,
            "baseURL": baseURL
        ])
        
        // Load cached data
        loadCachedData()
        
        // Start real-time updates
        startRealTimeUpdates()
    }
    
    // MARK: - Real-time Updates
    func startRealTimeUpdates() {
        connectWebSocket()
        startPeriodicUpdates()
    }
    
    func stopRealTimeUpdates() {
        disconnectWebSocket()
        stopPeriodicUpdates()
    }
    
    // MARK: - WebSocket Connection
    private func connectWebSocket() {
        guard let url = URL(string: wsURL) else {
            loggingService.error("Invalid WebSocket URL", category: "websocket")
            return
        }
        
        urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession?.webSocketTask(with: url)
        
        webSocketTask?.resume()
        isConnected = true
        connectionStatus = "Подключено"
        
        loggingService.info("WebSocket connected", category: "websocket")
        
        // Start receiving messages
        receiveMessage()
        
        // Send authentication
        sendAuthentication()
        
        // Start heartbeat
        startHeartbeat()
    }
    
    private func disconnectWebSocket() {
        webSocketTask?.cancel()
        webSocketTask = nil
        isConnected = false
        connectionStatus = "Отключено"
        
        stopHeartbeat()
        
        loggingService.info("WebSocket disconnected", category: "websocket")
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleWebSocketMessage(message)
                self?.receiveMessage() // Continue receiving
            case .failure(let error):
                self?.loggingService.error("WebSocket receive error", category: "websocket", error: error)
                self?.handleWebSocketError(error)
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            handleDataMessage(data)
        @unknown default:
            break
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let topic = json["topic"] as? String {
                    handleTopicMessage(topic: topic, data: json)
                } else if let op = json["op"] as? String {
                    handleOperationMessage(op: op, data: json)
                }
            }
        } catch {
            loggingService.error("Failed to parse WebSocket message", category: "websocket", error: error)
        }
    }
    
    private func handleDataMessage(_ data: Data) {
        // Handle binary messages if needed
        loggingService.debug("Received binary WebSocket message", category: "websocket")
    }
    
    private func handleTopicMessage(topic: String, data: [String: Any]) {
        switch topic {
        case let t where t.contains("orderbook"):
            handleOrderBookUpdate(data)
        case let t where t.contains("tickers"):
            handleTickerUpdate(data)
        case let t where t.contains("kline"):
            handleKlineUpdate(data)
        case let t where t.contains("position"):
            handlePositionUpdate(data)
        case let t where t.contains("wallet"):
            handleWalletUpdate(data)
        default:
            loggingService.debug("Unknown topic: \(topic)", category: "websocket")
        }
    }
    
    private func handleOperationMessage(op: String, data: [String: Any]) {
        switch op {
        case "auth":
            handleAuthResponse(data)
        case "subscribe":
            handleSubscribeResponse(data)
        case "ping":
            sendPong()
        default:
            loggingService.debug("Unknown operation: \(op)", category: "websocket")
        }
    }
    
    // MARK: - Message Handlers
    private func handleOrderBookUpdate(_ data: [String: Any]) {
        // Handle order book updates
        loggingService.debug("Order book update received", category: "websocket")
    }
    
    private func handleTickerUpdate(_ data: [String: Any]) {
        // Handle ticker updates
        if let tickerData = data["data"] as? [String: Any] {
            updateTickerData(tickerData)
        }
    }
    
    private func handleKlineUpdate(_ data: [String: Any]) {
        // Handle kline updates
        if let klineData = data["data"] as? [[String: Any]] {
            updateKlineData(klineData)
        }
    }
    
    private func handlePositionUpdate(_ data: [String: Any]) {
        // Handle position updates
        if let positionData = data["data"] as? [[String: Any]] {
            updatePositionData(positionData)
        }
    }
    
    private func handleWalletUpdate(_ data: [String: Any]) {
        // Handle wallet updates
        if let walletData = data["data"] as? [String: Any] {
            updateWalletData(walletData)
        }
    }
    
    private func handleAuthResponse(_ data: [String: Any]) {
        if let success = data["success"] as? Bool, success {
            loggingService.info("WebSocket authentication successful", category: "websocket")
            subscribeToTopics()
        } else {
            loggingService.error("WebSocket authentication failed", category: "websocket")
        }
    }
    
    private func handleSubscribeResponse(_ data: [String: Any]) {
        if let success = data["success"] as? Bool, success {
            loggingService.info("Successfully subscribed to topics", category: "websocket")
        } else {
            loggingService.error("Failed to subscribe to topics", category: "websocket")
        }
    }
    
    // MARK: - WebSocket Operations
    private func sendAuthentication() {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signature = generateSignature(timestamp: timestamp)
        
        let authMessage: [String: Any] = [
            "op": "auth",
            "args": [
                apiKey,
                timestamp,
                signature
            ]
        ]
        
        sendWebSocketMessage(authMessage)
    }
    
    private func subscribeToTopics() {
        let topics = [
            "orderbook.1.BTCUSDT",
            "tickers.BTCUSDT",
            "kline.1.BTCUSDT",
            "position",
            "wallet"
        ]
        
        let subscribeMessage: [String: Any] = [
            "op": "subscribe",
            "args": topics
        ]
        
        sendWebSocketMessage(subscribeMessage)
    }
    
    private func sendWebSocketMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let text = String(data: data, encoding: .utf8) else {
            loggingService.error("Failed to serialize WebSocket message", category: "websocket")
            return
        }
        
        webSocketTask?.send(.string(text)) { [weak self] error in
            if let error = error {
                self?.loggingService.error("Failed to send WebSocket message", category: "websocket", error: error)
            }
        }
    }
    
    private func sendPong() {
        let pongMessage: [String: Any] = ["op": "pong"]
        sendWebSocketMessage(pongMessage)
    }
    
    // MARK: - Heartbeat
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func sendPing() {
        let pingMessage: [String: Any] = ["op": "ping"]
        sendWebSocketMessage(pingMessage)
    }
    
    // MARK: - Error Handling
    private func handleWebSocketError(_ error: Error) {
        isConnected = false
        connectionStatus = "Ошибка подключения"
        
        loggingService.error("WebSocket error", category: "websocket", error: error)
        
        // Attempt to reconnect
        scheduleReconnect()
    }
    
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.connectWebSocket()
        }
    }
    
    // MARK: - Periodic Updates
    private func startPeriodicUpdates() {
        // Update data every 30 seconds
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchAllData()
            }
            .store(in: &cancellables)
    }
    
    private func stopPeriodicUpdates() {
        cancellables.removeAll()
    }
    
    // MARK: - Data Fetching
    func fetchAllData() {
        let startTime = Date()
        
        Task {
            async let balanceTask = fetchWalletBalance()
            async let positionsTask = fetchPositions()
            async let tickersTask = fetchTickers()
            async let ordersTask = fetchOrderHistory()
            
            let (balance, positions, tickers, orders) = await (balanceTask, positionsTask, tickersTask, ordersTask)
            
            await MainActor.run {
                self.walletBalance = balance
                self.positions = positions
                self.tickers = tickers
                self.orderHistory = orders
                self.lastUpdateTime = Date()
                
                let duration = Date().timeIntervalSince(startTime)
                self.loggingService.logPerformance("Data fetch", duration: duration, category: "performance")
            }
        }
    }
    
    // MARK: - API Methods
    private func fetchWalletBalance() async -> WalletBalance? {
        let endpoint = "/v5/account/wallet-balance"
        let url = baseURL + endpoint
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let headers = createHeaders(endpoint: endpoint, method: "GET")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        loggingService.logAPIRequest(request, category: "bybit")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            loggingService.logAPIResponse(response, data: data, error: nil, category: "bybit")
            
            let balanceResponse = try JSONDecoder().decode(WalletBalanceResponse.self, from: data)
            if balanceResponse.retCode == 0 {
                return balanceResponse.result.list.first
            } else {
                loggingService.error("Failed to fetch wallet balance", category: "bybit", metadata: [
                    "retCode": balanceResponse.retCode,
                    "retMsg": balanceResponse.retMsg
                ])
                return nil
            }
        } catch {
            loggingService.error("Error fetching wallet balance", category: "bybit", error: error)
            return nil
        }
    }
    
    private func fetchPositions() async -> [Position] {
        let endpoint = "/v5/position/list"
        let url = baseURL + endpoint
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let headers = createHeaders(endpoint: endpoint, method: "GET")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        loggingService.logAPIRequest(request, category: "bybit")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            loggingService.logAPIResponse(response, data: data, error: nil, category: "bybit")
            
            let positionResponse = try JSONDecoder().decode(PositionResponse.self, from: data)
            if positionResponse.retCode == 0 {
                return positionResponse.result.list
            } else {
                loggingService.error("Failed to fetch positions", category: "bybit", metadata: [
                    "retCode": positionResponse.retCode,
                    "retMsg": positionResponse.retMsg
                ])
                return []
            }
        } catch {
            loggingService.error("Error fetching positions", category: "bybit", error: error)
            return []
        }
    }
    
    private func fetchTickers() async -> [TickerInfo] {
        let endpoint = "/v5/market/tickers?category=spot"
        let url = baseURL + endpoint
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        loggingService.logAPIRequest(request, category: "bybit")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            loggingService.logAPIResponse(response, data: data, error: nil, category: "bybit")
            
            let tickerResponse = try JSONDecoder().decode(TickerResponse.self, from: data)
            if tickerResponse.retCode == 0 {
                return tickerResponse.result.list
            } else {
                loggingService.error("Failed to fetch tickers", category: "bybit", metadata: [
                    "retCode": tickerResponse.retCode,
                    "retMsg": tickerResponse.retMsg
                ])
                return []
            }
        } catch {
            loggingService.error("Error fetching tickers", category: "bybit", error: error)
            return []
        }
    }
    
    private func fetchOrderHistory() async -> [OrderInfo] {
        let endpoint = "/v5/order/realtime"
        let url = baseURL + endpoint
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let headers = createHeaders(endpoint: endpoint, method: "GET")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        loggingService.logAPIRequest(request, category: "bybit")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            loggingService.logAPIResponse(response, data: data, error: nil, category: "bybit")
            
            let orderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
            if orderResponse.retCode == 0 {
                return orderResponse.result.list
            } else {
                loggingService.error("Failed to fetch order history", category: "bybit", metadata: [
                    "retCode": orderResponse.retCode,
                    "retMsg": orderResponse.retMsg
                ])
                return []
            }
        } catch {
            loggingService.error("Error fetching order history", category: "bybit", error: error)
            return []
        }
    }
    
    // MARK: - Trading Methods
    func placeOrder(symbol: String, side: OrderSide, orderType: OrderType, quantity: Double, price: Double? = nil) async -> OrderResult? {
        let endpoint = "/v5/order/create"
        let url = baseURL + endpoint
        
        var orderData: [String: Any] = [
            "category": "spot",
            "symbol": symbol,
            "side": side.rawValue,
            "orderType": orderType.rawValue,
            "qty": String(quantity)
        ]
        
        if let price = price {
            orderData["price"] = String(price)
        }
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let headers = createHeaders(endpoint: endpoint, method: "POST")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: orderData)
        } catch {
            loggingService.error("Failed to serialize order data", category: "bybit", error: error)
            return nil
        }
        
        loggingService.logAPIRequest(request, category: "bybit")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            loggingService.logAPIResponse(response, data: data, error: nil, category: "bybit")
            
            let orderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
            if orderResponse.retCode == 0 {
                let result = OrderResult(
                    orderId: orderResponse.result.orderId,
                    symbol: symbol,
                    side: side,
                    orderType: orderType,
                    quantity: quantity,
                    price: price,
                    status: "Created"
                )
                
                loggingService.logTrade(Trade(symbol: symbol, side: side.rawValue, quantity: quantity, price: price ?? 0, timestamp: Date(), tags: []), action: "placed", category: "trading")
                
                return result
            } else {
                loggingService.error("Failed to place order", category: "bybit", metadata: [
                    "retCode": orderResponse.retCode,
                    "retMsg": orderResponse.retMsg,
                    "orderData": orderData
                ])
                return nil
            }
        } catch {
            loggingService.error("Error placing order", category: "bybit", error: error)
            return nil
        }
    }
    
    // MARK: - Helper Methods
    private func generateSignature(timestamp: Int64) -> String {
        let queryString = "api_key=\(apiKey)&timestamp=\(timestamp)"
        let signature = HMAC.SHA256.sign(data: queryString.data(using: .utf8)!, key: apiSecret.data(using: .utf8)!)
        return signature.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private func createHeaders(endpoint: String, method: String) -> [String: String] {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signature = generateSignature(timestamp: timestamp)
        
        return [
            "X-BAPI-API-KEY": apiKey,
            "X-BAPI-SIGNATURE": signature,
            "X-BAPI-SIGNATURE-TYPE": "2",
            "X-BAPI-TIMESTAMP": String(timestamp)
        ]
    }
    
    // MARK: - Caching
    private func setupCaching() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    private func loadCachedData() {
        // Load cached data from UserDefaults or other storage
        // This is a simplified version
    }
    
    private func updateTickerData(_ data: [String: Any]) {
        // Update ticker data from WebSocket
        DispatchQueue.main.async {
            // Update tickers array
        }
    }
    
    private func updateKlineData(_ data: [[String: Any]]) {
        // Update kline data from WebSocket
        DispatchQueue.main.async {
            // Update klineData array
        }
    }
    
    private func updatePositionData(_ data: [[String: Any]]) {
        // Update position data from WebSocket
        DispatchQueue.main.async {
            // Update positions array
        }
    }
    
    private func updateWalletData(_ data: [String: Any]) {
        // Update wallet data from WebSocket
        DispatchQueue.main.async {
            // Update walletBalance
        }
    }
    
    // MARK: - Publishers
    private func setupPublishers() {
        // Setup any additional publishers if needed
    }
}

// MARK: - Models
struct OrderResult {
    let orderId: String
    let symbol: String
    let side: OrderSide
    let orderType: OrderType
    let quantity: Double
    let price: Double?
    let status: String
}

struct CachedData {
    let data: Any
    let timestamp: Date
    let expirationInterval: TimeInterval
    
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > expirationInterval
    }
}

// MARK: - Response Models (simplified)
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

struct PositionResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: PositionResult
    
    enum CodingKeys: String, CodingKey {
        case retCode = "retCode"
        case retMsg = "retMsg"
        case result
    }
}

struct PositionResult: Codable {
    let list: [Position]
}

struct TickerResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: TickerResult
    
    enum CodingKeys: String, CodingKey {
        case retCode = "retCode"
        case retMsg = "retMsg"
        case result
    }
}

struct TickerResult: Codable {
    let list: [TickerInfo]
}

struct OrderResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: OrderResult
    
    enum CodingKeys: String, CodingKey {
        case retCode = "retCode"
        case retMsg = "retMsg"
        case result
    }
}

struct OrderResult: Codable {
    let list: [OrderInfo]
    let orderId: String?
}

// MARK: - Enums
enum OrderSide: String, CaseIterable, Codable {
    case buy = "Buy"
    case sell = "Sell"
}

enum OrderType: String, CaseIterable, Codable {
    case market = "Market"
    case limit = "Limit"
}

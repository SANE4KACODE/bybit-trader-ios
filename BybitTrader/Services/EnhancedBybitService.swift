import Foundation
import Combine
import CryptoKit

class EnhancedBybitService: ObservableObject {
    static let shared = EnhancedBybitService()
    
    // MARK: - Published Properties
    @Published var walletBalance: WalletBalance?
    @Published var positions: [Position] = []
    @Published var tickers: [TickerInfo] = []
    @Published var orderHistory: [OrderInfo] = []
    @Published var klineData: [KlineData] = []
    @Published var isConnected = false
    @Published var connectionStatus = "Отключено"
    @Published var lastUpdateTime = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let apiKeyService = APIKeyManagementService.shared
    private let loggingService = LoggingService.shared
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    
    // MARK: - Computed Properties
    private var baseURL: String {
        guard let currentKey = apiKeyService.getCurrentAPIKey() else { return "" }
        return currentKey.isTestnet ? "https://api-testnet.bybit.com" : "https://api.bybit.com"
    }
    
    private var wsURL: String {
        guard let currentKey = apiKeyService.getCurrentAPIKey() else { return "" }
        return currentKey.isTestnet ? "wss://stream-testnet.bybit.com" : "wss://stream.bybit.com"
    }
    
    private init() {
        setupService()
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupService() {
        // Check if we have valid API keys
        guard apiKeyService.getCurrentAPIKey() != nil else {
            connectionStatus = "API ключ не настроен"
            return
        }
        
        startDataUpdates()
    }
    
    private func setupObservers() {
        // Observe API key changes
        apiKeyService.$currentAPIKey
            .sink { [weak self] apiKey in
                if apiKey != nil {
                    self?.startDataUpdates()
                } else {
                    self?.stopDataUpdates()
                }
            }
            .store(in: &cancellables)
        
        // Observe error messages
        $errorMessage
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.loggingService.error("Bybit service error", category: "bybit", metadata: [
                    "error": error
                ])
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func startDataUpdates() {
        guard apiKeyService.getCurrentAPIKey() != nil else {
            errorMessage = "API ключ не настроен"
            return
        }
        
        isLoading = true
        connectionStatus = "Подключение..."
        
        // Fetch initial data
        Task {
            await fetchAllData()
            
            await MainActor.run {
                self.isLoading = false
                self.connectionStatus = "Подключено"
                self.isConnected = true
            }
        }
        
        // Start periodic updates
        startPeriodicUpdates()
    }
    
    func stopDataUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        isConnected = false
        connectionStatus = "Отключено"
        
        loggingService.info("Data updates stopped", category: "bybit")
    }
    
    func refreshData() async {
        guard apiKeyService.getCurrentAPIKey() != nil else {
            await MainActor.run {
                self.errorMessage = "API ключ не настроен"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        await fetchAllData()
        
        await MainActor.run {
            self.isLoading = false
            self.lastUpdateTime = Date()
        }
    }
    
    // MARK: - Data Fetching
    private func fetchAllData() async {
        let startTime = Date()
        
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
            
            let duration = Date().timeIntervalSince(startTime)
            self.loggingService.logPerformance("Data fetch", duration: duration, category: "performance")
        }
    }
    
    private func fetchWalletBalance() async -> WalletBalance? {
        guard let credentials = apiKeyService.getAPIKeyCredentials() else { return nil }
        
        let endpoint = "/v5/account/wallet-balance"
        let url = baseURL + endpoint
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let headers = createHeaders(endpoint: endpoint, method: "GET", apiKey: credentials.apiKey, apiSecret: credentials.apiSecret)
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
        guard let credentials = apiKeyService.getAPIKeyCredentials() else { return [] }
        
        let endpoint = "/v5/position/list"
        let url = baseURL + endpoint
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let headers = createHeaders(endpoint: endpoint, method: "GET", apiKey: credentials.apiKey, apiSecret: credentials.apiSecret)
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
        guard let credentials = apiKeyService.getAPIKeyCredentials() else { return [] }
        
        let endpoint = "/v5/order/realtime"
        let url = baseURL + endpoint
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let headers = createHeaders(endpoint: endpoint, method: "GET", apiKey: credentials.apiKey, apiSecret: credentials.apiSecret)
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
        guard let credentials = apiKeyService.getAPIKeyCredentials() else {
            await MainActor.run {
                self.errorMessage = "API ключ не настроен"
            }
            return nil
        }
        
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
        
        let headers = createHeaders(endpoint: endpoint, method: "POST", apiKey: credentials.apiKey, apiSecret: credentials.apiSecret)
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
                
                // Refresh data after order placement
                await refreshData()
                
                return result
            } else {
                await MainActor.run {
                    self.errorMessage = "Ошибка размещения ордера: \(orderResponse.retMsg)"
                }
                
                loggingService.error("Failed to place order", category: "bybit", metadata: [
                    "retCode": orderResponse.retCode,
                    "retMsg": orderResponse.retMsg,
                    "orderData": orderData
                ])
                return nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Ошибка сети при размещении ордера"
            }
            
            loggingService.error("Error placing order", category: "bybit", error: error)
            return nil
        }
    }
    
    func cancelOrder(orderId: String, symbol: String) async -> Bool {
        guard let credentials = apiKeyService.getAPIKeyCredentials() else {
            await MainActor.run {
                self.errorMessage = "API ключ не настроен"
            }
            return false
        }
        
        let endpoint = "/v5/order/cancel"
        let url = baseURL + endpoint
        
        let cancelData: [String: Any] = [
            "category": "spot",
            "symbol": symbol,
            "orderId": orderId
        ]
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let headers = createHeaders(endpoint: endpoint, method: "POST", apiKey: credentials.apiKey, apiSecret: credentials.apiSecret)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: cancelData)
        } catch {
            loggingService.error("Failed to serialize cancel data", category: "bybit", error: error)
            return false
        }
        
        loggingService.logAPIRequest(request, category: "bybit")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            loggingService.logAPIResponse(response, data: data, error: nil, category: "bybit")
            
            let cancelResponse = try JSONDecoder().decode(CancelOrderResponse.self, from: data)
            if cancelResponse.retCode == 0 {
                loggingService.info("Order cancelled successfully", category: "bybit", metadata: [
                    "orderId": orderId,
                    "symbol": symbol
                ])
                
                // Refresh data after order cancellation
                await refreshData()
                
                return true
            } else {
                await MainActor.run {
                    self.errorMessage = "Ошибка отмены ордера: \(cancelResponse.retMsg)"
                }
                
                loggingService.error("Failed to cancel order", category: "bybit", metadata: [
                    "retCode": cancelResponse.retCode,
                    "retMsg": cancelResponse.retMsg,
                    "orderId": orderId
                ])
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Ошибка сети при отмене ордера"
            }
            
            loggingService.error("Error cancelling order", category: "bybit", error: error)
            return false
        }
    }
    
    // MARK: - Chart Data
    func fetchKlineData(symbol: String, interval: String, limit: Int = 200) async -> [KlineData] {
        let endpoint = "/v5/market/kline?category=spot&symbol=\(symbol)&interval=\(interval)&limit=\(limit)"
        let url = baseURL + endpoint
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        loggingService.logAPIRequest(request, category: "bybit")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            loggingService.logAPIResponse(response, data: data, error: nil, category: "bybit")
            
            let klineResponse = try JSONDecoder().decode(KlineResponse.self, from: data)
            if klineResponse.retCode == 0 {
                return klineResponse.result.list
            } else {
                loggingService.error("Failed to fetch kline data", category: "bybit", metadata: [
                    "retCode": klineResponse.retCode,
                    "retMsg": klineResponse.retMsg,
                    "symbol": symbol,
                    "interval": interval
                ])
                return []
            }
        } catch {
            loggingService.error("Error fetching kline data", category: "bybit", error: error)
            return []
        }
    }
    
    // MARK: - Private Methods
    private func startPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshData()
            }
        }
    }
    
    private func createHeaders(endpoint: String, method: String, apiKey: String, apiSecret: String) -> [String: String] {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signature = generateSignature(endpoint: endpoint, method: method, timestamp: timestamp, apiSecret: apiSecret)
        
        return [
            "X-BAPI-API-KEY": apiKey,
            "X-BAPI-SIGNATURE": signature,
            "X-BAPI-SIGNATURE-TYPE": "2",
            "X-BAPI-TIMESTAMP": String(timestamp)
        ]
    }
    
    private func generateSignature(endpoint: String, method: String, timestamp: Int64, apiSecret: String) -> String {
        let queryString = "api_key=\(apiKey)&timestamp=\(timestamp)"
        let signature = HMAC.SHA256.sign(data: queryString.data(using: .utf8)!, key: apiSecret.data(using: .utf8)!)
        return signature.map { String(format: "%02hhx", $0) }.joined()
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error, context: String) {
        await MainActor.run {
            self.errorMessage = "\(context): \(error.localizedDescription)"
        }
        
        loggingService.error("Bybit service error", category: "bybit", error: error, metadata: [
            "context": context
        ])
    }
}

// MARK: - Response Models
struct CancelOrderResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: CancelOrderResult
    
    enum CodingKeys: String, CodingKey {
        case retCode = "retCode"
        case retMsg = "retMsg"
        case result
    }
}

struct CancelOrderResult: Codable {
    let orderId: String
}

struct KlineResponse: Codable {
    let retCode: Int
    let retMsg: String
    let result: KlineResult
    
    enum CodingKeys: String, CodingKey {
        case retCode = "retCode"
        case retMsg = "retMsg"
        case result
    }
}

struct KlineResult: Codable {
    let list: [KlineData]
}

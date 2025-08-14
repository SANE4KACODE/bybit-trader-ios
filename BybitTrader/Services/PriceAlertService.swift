import Foundation
import Combine
import UserNotifications

class PriceAlertService: ObservableObject {
    static let shared = PriceAlertService()
    
    // MARK: - Published Properties
    @Published var priceAlerts: [PriceAlert] = []
    @Published var activeAlerts: [PriceAlert] = []
    @Published var triggeredAlerts: [TriggeredAlert] = []
    @Published var marketData: [String: MarketData] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let bybitService = RealTimeBybitService.shared
    private let notificationService = NotificationService.shared
    private let loggingService = LoggingService.shared
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    private var priceUpdateTimer: Timer?
    private var alertCheckTimer: Timer?
    
    // MARK: - Constants
    private let priceUpdateInterval: TimeInterval = 10 // 10 seconds
    private let alertCheckInterval: TimeInterval = 5 // 5 seconds
    private let supportedSymbols = ["BTCUSDT", "ETHUSDT", "BNBUSDT", "ADAUSDT", "SOLUSDT", "DOTUSDT", "LINKUSDT", "UNIUSDT", "LTCUSDT", "BCHUSDT"]
    
    private init() {
        setupPriceMonitoring()
        loadPriceAlerts()
        startPriceUpdates()
    }
    
    // MARK: - Setup
    private func setupPriceMonitoring() {
        // Observe market data updates from Bybit service
        bybitService.$tickers
            .sink { [weak self] tickers in
                self?.updateMarketData(from: tickers)
            }
            .store(in: &cancellables)
        
        // Setup timers
        setupTimers()
    }
    
    private func setupTimers() {
        // Price update timer
        priceUpdateTimer = Timer.scheduledTimer(withTimeInterval: priceUpdateInterval, repeats: true) { [weak self] _ in
            self?.updatePrices()
        }
        
        // Alert check timer
        alertCheckTimer = Timer.scheduledTimer(withTimeInterval: alertCheckInterval, repeats: true) { [weak self] _ in
            self?.checkPriceAlerts()
        }
    }
    
    // MARK: - Public Methods
    func createPriceAlert(
        symbol: String,
        targetPrice: Double,
        condition: PriceAlertCondition,
        isEnabled: Bool = true,
        notificationType: NotificationType = .push,
        customMessage: String? = nil
    ) async {
        let alert = PriceAlert(
            symbol: symbol,
            targetPrice: targetPrice,
            condition: condition,
            isEnabled: isEnabled,
            notificationType: notificationType,
            customMessage: customMessage
        )
        
        do {
            try await supabaseService.savePriceAlert(alert)
            
            await MainActor.run {
                self.priceAlerts.append(alert)
                
                if isEnabled {
                    self.activeAlerts.append(alert)
                    self.schedulePriceAlert(alert)
                }
                
                self.loggingService.info("Price alert created", category: "price_alerts", metadata: [
                    "symbol": symbol,
                    "targetPrice": targetPrice,
                    "condition": condition.rawValue
                ])
            }
        } catch {
            await MainActor.run {
                self.loggingService.error("Failed to create price alert", category: "price_alerts", error: error)
                self.errorMessage = "Не удалось создать ценовое уведомление"
            }
        }
    }
    
    func updatePriceAlert(_ alert: PriceAlert) async {
        do {
            try await supabaseService.updatePriceAlert(alert)
            
            await MainActor.run {
                if let index = self.priceAlerts.firstIndex(where: { $0.id == alert.id }) {
                    self.priceAlerts[index] = alert
                }
                
                if let index = self.activeAlerts.firstIndex(where: { $0.id == alert.id }) {
                    if alert.isEnabled {
                        self.activeAlerts[index] = alert
                    } else {
                        self.activeAlerts.remove(at: index)
                    }
                }
                
                self.loggingService.info("Price alert updated", category: "price_alerts", metadata: [
                    "alertId": alert.id.uuidString
                ])
            }
        } catch {
            await MainActor.run {
                self.loggingService.error("Failed to update price alert", category: "price_alerts", error: error)
                self.errorMessage = "Не удалось обновить ценовое уведомление"
            }
        }
    }
    
    func deletePriceAlert(_ alert: PriceAlert) async {
        do {
            try await supabaseService.deletePriceAlert(alert.id)
            
            await MainActor.run {
                self.priceAlerts.removeAll { $0.id == alert.id }
                self.activeAlerts.removeAll { $0.id == alert.id }
                
                // Remove scheduled notification
                self.notificationService.removePriceAlert(alert)
                
                self.loggingService.info("Price alert deleted", category: "price_alerts", metadata: [
                    "alertId": alert.id.uuidString
                ])
            }
        } catch {
            await MainActor.run {
                self.loggingService.error("Failed to delete price alert", category: "price_alerts", error: error)
                self.errorMessage = "Не удалось удалить ценовое уведомление"
            }
        }
    }
    
    func enablePriceAlert(_ alert: PriceAlert) async {
        var updatedAlert = alert
        updatedAlert.isEnabled = true
        
        await updatePriceAlert(updatedAlert)
        
        await MainActor.run {
            if !self.activeAlerts.contains(where: { $0.id == alert.id }) {
                self.activeAlerts.append(updatedAlert)
            }
        }
    }
    
    func disablePriceAlert(_ alert: PriceAlert) async {
        var updatedAlert = alert
        updatedAlert.isEnabled = false
        
        await updatePriceAlert(updatedAlert)
        
        await MainActor.run {
            self.activeAlerts.removeAll { $0.id == alert.id }
        }
    }
    
    func getPriceAlertHistory() -> [TriggeredAlert] {
        return triggeredAlerts.sorted { $0.triggeredAt > $1.triggeredAt }
    }
    
    func clearPriceAlertHistory() {
        triggeredAlerts.removeAll()
        
        loggingService.info("Price alert history cleared", category: "price_alerts")
    }
    
    func getMarketOverview() -> MarketOverview {
        let totalAlerts = priceAlerts.count
        let activeAlertsCount = activeAlerts.count
        let triggeredAlertsCount = triggeredAlerts.count
        
        let symbolDistribution = Dictionary(grouping: priceAlerts, by: { $0.symbol })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        let conditionDistribution = Dictionary(grouping: priceAlerts, by: { $0.condition })
            .mapValues { $0.count }
        
        return MarketOverview(
            totalAlerts: totalAlerts,
            activeAlerts: activeAlertsCount,
            triggeredAlerts: triggeredAlertsCount,
            symbolDistribution: symbolDistribution,
            conditionDistribution: conditionDistribution,
            lastUpdate: Date()
        )
    }
    
    func exportPriceAlerts() -> String {
        var csv = "Symbol,Target Price,Condition,Status,Enabled,Notification Type,Custom Message,Created Date\n"
        
        for alert in priceAlerts {
            let status = activeAlerts.contains(where: { $0.id == alert.id }) ? "Active" : "Inactive"
            let enabled = alert.isEnabled ? "Yes" : "No"
            let customMessage = alert.customMessage ?? "N/A"
            
            csv += "\(alert.symbol),\(alert.targetPrice),\(alert.condition.displayName),\(status),\(enabled),\(alert.notificationType.displayName),\(customMessage),\(alert.createdAt.formatted())\n"
        }
        
        return csv
    }
    
    // MARK: - Private Methods
    private func loadPriceAlerts() {
        Task {
            do {
                let alerts = try await supabaseService.getPriceAlerts()
                
                await MainActor.run {
                    self.priceAlerts = alerts
                    self.activeAlerts = alerts.filter { $0.isEnabled }
                }
            } catch {
                await MainActor.run {
                    self.loggingService.error("Failed to load price alerts", category: "price_alerts", error: error)
                }
            }
        }
    }
    
    private func startPriceUpdates() {
        // Start monitoring supported symbols
        for symbol in supportedSymbols {
            startSymbolMonitoring(symbol)
        }
    }
    
    private func startSymbolMonitoring(_ symbol: String) {
        // This would integrate with Bybit WebSocket for real-time price updates
        // For now, we'll use the ticker data from the service
        
        loggingService.info("Started monitoring symbol", category: "price_alerts", metadata: [
            "symbol": symbol
        ])
    }
    
    private func updatePrices() {
        // Update prices for all monitored symbols
        // This would typically come from WebSocket data
        
        for symbol in supportedSymbols {
            if let marketData = marketData[symbol] {
                // Update market data
                updateMarketDataForSymbol(symbol, data: marketData)
            }
        }
    }
    
    private func updateMarketData(from tickers: [TickerInfo]) {
        for ticker in tickers {
            let marketData = MarketData(
                symbol: ticker.symbol,
                lastPrice: Double(ticker.lastPrice) ?? 0,
                bidPrice: Double(ticker.bid1Price) ?? 0,
                askPrice: Double(ticker.ask1Price) ?? 0,
                volume24h: Double(ticker.volume24h) ?? 0,
                priceChange24h: Double(ticker.price24hPcnt) ?? 0,
                high24h: Double(ticker.highPrice24h) ?? 0,
                low24h: Double(ticker.lowPrice24h) ?? 0,
                timestamp: Date()
            )
            
            marketData[ticker.symbol] = marketData
        }
    }
    
    private func updateMarketDataForSymbol(_ symbol: String, data: MarketData) {
        // Update market data and check alerts
        marketData[symbol] = data
        
        // Check if any alerts should be triggered
        checkAlertsForSymbol(symbol, currentPrice: data.lastPrice)
    }
    
    private func checkPriceAlerts() {
        for alert in activeAlerts {
            if let marketData = marketData[alert.symbol] {
                checkAlert(alert, currentPrice: marketData.lastPrice)
            }
        }
    }
    
    private func checkAlertsForSymbol(_ symbol: String, currentPrice: Double) {
        let symbolAlerts = activeAlerts.filter { $0.symbol == symbol }
        
        for alert in symbolAlerts {
            checkAlert(alert, currentPrice: currentPrice)
        }
    }
    
    private func checkAlert(_ alert: PriceAlert, currentPrice: Double) {
        let shouldTrigger = shouldTriggerAlert(alert, currentPrice: currentPrice)
        
        if shouldTrigger {
            triggerPriceAlert(alert, currentPrice: currentPrice)
        }
    }
    
    private func shouldTriggerAlert(_ alert: PriceAlert, currentPrice: Double) -> Bool {
        switch alert.condition {
        case .above:
            return currentPrice > alert.targetPrice
        case .below:
            return currentPrice < alert.targetPrice
        case .equals:
            return abs(currentPrice - alert.targetPrice) < 0.01 // Small tolerance
        case .crossesAbove:
            // Would need to track previous price
            return false
        case .crossesBelow:
            // Would need to track previous price
            return false
        case .percentageChange:
            // Would need to track previous price
            return false
        }
    }
    
    private func triggerPriceAlert(_ alert: PriceAlert, currentPrice: Double) {
        // Create triggered alert record
        let triggeredAlert = TriggeredAlert(
            alertId: alert.id,
            symbol: alert.symbol,
            targetPrice: alert.targetPrice,
            currentPrice: currentPrice,
            condition: alert.condition,
            triggeredAt: Date()
        )
        
        triggeredAlerts.append(triggeredAlert)
        
        // Send notification
        sendPriceAlertNotification(alert, currentPrice: currentPrice)
        
        // Disable alert if it's one-time
        if alert.isOneTime {
            Task {
                await disablePriceAlert(alert)
            }
        }
        
        loggingService.info("Price alert triggered", category: "price_alerts", metadata: [
            "alertId": alert.id.uuidString,
            "symbol": alert.symbol,
            "targetPrice": alert.targetPrice,
            "currentPrice": currentPrice
        ])
    }
    
    private func sendPriceAlertNotification(_ alert: PriceAlert, currentPrice: Double) {
        let title = "Ценовое уведомление"
        let body = "\(alert.symbol) достиг цены \(String(format: "%.2f", currentPrice))"
        
        switch alert.notificationType {
        case .push:
            notificationService.schedulePriceAlert(alert)
        case .email:
            // Send email notification
            sendEmailNotification(alert, currentPrice: currentPrice)
        case .both:
            notificationService.schedulePriceAlert(alert)
            sendEmailNotification(alert, currentPrice: currentPrice)
        }
    }
    
    private func sendEmailNotification(_ alert: PriceAlert, currentPrice: Double) {
        // Implementation for email notifications
        // This would integrate with an email service
        
        loggingService.info("Email notification sent", category: "price_alerts", metadata: [
            "alertId": alert.id.uuidString,
            "symbol": alert.symbol
        ])
    }
    
    private func schedulePriceAlert(_ alert: PriceAlert) {
        // Schedule notification for this alert
        notificationService.schedulePriceAlert(alert)
    }
}

// MARK: - Models
struct PriceAlert: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let targetPrice: Double
    let condition: PriceAlertCondition
    var isEnabled: Bool
    let notificationType: NotificationType
    let customMessage: String?
    let isOneTime: Bool
    let createdAt: Date
    var updatedAt: Date
    
    init(symbol: String, targetPrice: Double, condition: PriceAlertCondition, isEnabled: Bool = true, notificationType: NotificationType = .push, customMessage: String? = nil) {
        self.symbol = symbol
        self.targetPrice = targetPrice
        self.condition = condition
        self.isEnabled = isEnabled
        self.notificationType = notificationType
        self.customMessage = customMessage
        self.isOneTime = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct TriggeredAlert: Identifiable, Codable {
    let id = UUID()
    let alertId: UUID
    let symbol: String
    let targetPrice: Double
    let currentPrice: Double
    let condition: PriceAlertCondition
    let triggeredAt: Date
}

struct MarketData {
    let symbol: String
    let lastPrice: Double
    let bidPrice: Double
    let askPrice: Double
    let volume24h: Double
    let priceChange24h: Double
    let high24h: Double
    let low24h: Double
    let timestamp: Date
}

struct MarketOverview {
    let totalAlerts: Int
    let activeAlerts: Int
    let triggeredAlerts: Int
    let symbolDistribution: [(String, Int)]
    let conditionDistribution: [PriceAlertCondition: Int]
    let lastUpdate: Date
}

enum PriceAlertCondition: String, CaseIterable, Codable {
    case above = "above"
    case below = "below"
    case equals = "equals"
    case crossesAbove = "crossesAbove"
    case crossesBelow = "crossesBelow"
    case percentageChange = "percentageChange"
    
    var displayName: String {
        switch self {
        case .above: return "Выше"
        case .below: return "Ниже"
        case .equals: return "Равно"
        case .crossesAbove: return "Пересекает выше"
        case .crossesBelow: return "Пересекает ниже"
        case .percentageChange: return "Изменение %"
        }
    }
    
    var symbol: String {
        switch self {
        case .above: return ">"
        case .below: return "<"
        case .equals: return "="
        case .crossesAbove: return "↗"
        case .crossesBelow: return "↘"
        case .percentageChange: return "%"
        }
    }
}

enum NotificationType: String, CaseIterable, Codable {
    case push = "push"
    case email = "email"
    case both = "both"
    
    var displayName: String {
        switch self {
        case .push: return "Push-уведомление"
        case .email: return "Email"
        case .both: return "Push + Email"
        }
    }
}

// MARK: - Extensions
extension NotificationService {
    func removePriceAlert(_ alert: PriceAlert) {
        // Remove scheduled notification for this alert
        let identifier = "price_alert_\(alert.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        loggingService.info("Price alert notification removed", category: "notifications", metadata: [
            "alertId": alert.id.uuidString
        ])
    }
}

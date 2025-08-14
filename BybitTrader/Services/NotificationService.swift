import Foundation
import UserNotifications
import Combine

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var notificationSettings = NotificationSettings()
    @Published var priceAlerts: [PriceAlert] = []
    @Published var tradeNotifications: [TradeNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let loggingService = LoggingService.shared
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        setupNotifications()
        loadNotificationSettings()
        loadPriceAlerts()
    }
    
    // MARK: - Setup
    private func setupNotifications() {
        // Request authorization
        requestAuthorization()
        
        // Setup notification categories
        setupNotificationCategories()
        
        // Observe app state changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkPendingNotifications()
            }
            .store(in: &cancellables)
    }
    
    private func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                
                if granted {
                    self?.loggingService.info("Notification authorization granted", category: "notifications")
                } else {
                    self?.loggingService.warning("Notification authorization denied", category: "notifications")
                }
                
                if let error = error {
                    self?.loggingService.error("Notification authorization error", category: "notifications", error: error)
                }
            }
        }
    }
    
    private func setupNotificationCategories() {
        let tradeCategory = UNNotificationCategory(
            identifier: "TRADE_NOTIFICATION",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_TRADE",
                    title: "Просмотреть",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "Отклонить",
                    options: [.destructive]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let priceAlertCategory = UNNotificationCategory(
            identifier: "PRICE_ALERT",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_CHART",
                    title: "График",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "PLACE_ORDER",
                    title: "Разместить ордер",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let subscriptionCategory = UNNotificationCategory(
            identifier: "SUBSCRIPTION",
            actions: [
                UNNotificationAction(
                    identifier: "RENEW",
                    title: "Продлить",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "MANAGE",
                    title: "Управление",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([tradeCategory, priceAlertCategory, subscriptionCategory])
    }
    
    // MARK: - Public Methods
    func scheduleTradeNotification(for trade: Trade) {
        guard isAuthorized && notificationSettings.tradeNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Новая сделка"
        content.body = "\(trade.symbol) \(trade.side) \(trade.quantity) @ \(trade.price)"
        content.sound = .default
        content.categoryIdentifier = "TRADE_NOTIFICATION"
        content.userInfo = [
            "tradeId": trade.id.uuidString,
            "symbol": trade.symbol,
            "type": "trade"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "trade_\(trade.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.loggingService.error("Failed to schedule trade notification", category: "notifications", error: error)
            } else {
                self?.loggingService.info("Trade notification scheduled", category: "notifications", metadata: [
                    "tradeId": trade.id.uuidString
                ])
            }
        }
    }
    
    func schedulePriceAlert(for alert: PriceAlert) {
        guard isAuthorized && notificationSettings.priceAlerts else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Ценовое уведомление"
        content.body = "\(alert.symbol) достиг цены \(alert.targetPrice)"
        content.sound = .default
        content.categoryIdentifier = "PRICE_ALERT"
        content.userInfo = [
            "alertId": alert.id.uuidString,
            "symbol": alert.symbol,
            "type": "price_alert"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "price_alert_\(alert.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.loggingService.error("Failed to schedule price alert", category: "notifications", error: error)
            } else {
                self?.loggingService.info("Price alert scheduled", category: "notifications", metadata: [
                    "alertId": alert.id.uuidString,
                    "symbol": alert.symbol
                ])
            }
        }
    }
    
    func scheduleSubscriptionReminder(daysBeforeExpiry: Int) {
        guard isAuthorized && notificationSettings.subscriptionReminders else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Напоминание о подписке"
        content.body = "Ваша подписка истекает через \(daysBeforeExpiry) дней"
        content.sound = .default
        content.categoryIdentifier = "SUBSCRIPTION"
        content.userInfo = ["type": "subscription_reminder"]
        
        // Schedule for specific time (e.g., 9 AM)
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "subscription_reminder_\(daysBeforeExpiry)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.loggingService.error("Failed to schedule subscription reminder", category: "notifications", error: error)
            } else {
                self?.loggingService.info("Subscription reminder scheduled", category: "notifications", metadata: [
                    "daysBeforeExpiry": daysBeforeExpiry
                ])
            }
        }
    }
    
    func scheduleDailySummary() {
        guard isAuthorized && notificationSettings.dailySummary else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Дневной обзор"
        content.body = "Проверьте результаты вашей торговли за сегодня"
        content.sound = .default
        content.userInfo = ["type": "daily_summary"]
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_summary",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.loggingService.error("Failed to schedule daily summary", category: "notifications", error: error)
            } else {
                self?.loggingService.info("Daily summary scheduled", category: "notifications")
            }
        }
    }
    
    func scheduleWeeklyReport() {
        guard isAuthorized && notificationSettings.weeklyReports else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Недельный отчет"
        content.body = "Ваш недельный торговый отчет готов"
        content.sound = .default
        content.userInfo = ["type": "weekly_report"]
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_report",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.loggingService.error("Failed to schedule weekly report", category: "notifications", error: error)
            } else {
                self?.loggingService.info("Weekly report scheduled", category: "notifications")
            }
        }
    }
    
    // MARK: - Price Alerts
    func createPriceAlert(symbol: String, targetPrice: Double, condition: PriceAlertCondition, isEnabled: Bool = true) async {
        let alert = PriceAlert(
            symbol: symbol,
            targetPrice: targetPrice,
            condition: condition,
            isEnabled: isEnabled
        )
        
        do {
            try await supabaseService.savePriceAlert(alert)
            
            await MainActor.run {
                self.priceAlerts.append(alert)
                
                if isEnabled {
                    self.schedulePriceAlert(for: alert)
                }
                
                self.loggingService.info("Price alert created", category: "notifications", metadata: [
                    "symbol": symbol,
                    "targetPrice": targetPrice,
                    "condition": condition.rawValue
                ])
            }
        } catch {
            await MainActor.run {
                self.loggingService.error("Failed to create price alert", category: "notifications", error: error)
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
                
                self.loggingService.info("Price alert updated", category: "notifications", metadata: [
                    "alertId": alert.id.uuidString
                ])
            }
        } catch {
            await MainActor.run {
                self.loggingService.error("Failed to update price alert", category: "notifications", error: error)
                self.errorMessage = "Не удалось обновить ценовое уведомление"
            }
        }
    }
    
    func deletePriceAlert(_ alert: PriceAlert) async {
        do {
            try await supabaseService.deletePriceAlert(alert.id)
            
            await MainActor.run {
                self.priceAlerts.removeAll { $0.id == alert.id }
                
                // Remove scheduled notification
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: ["price_alert_\(alert.id.uuidString)"])
                
                self.loggingService.info("Price alert deleted", category: "notifications", metadata: [
                    "alertId": alert.id.uuidString
                ])
            }
        } catch {
            await MainActor.run {
                self.loggingService.error("Failed to delete price alert", category: "notifications", error: error)
                self.errorMessage = "Не удалось удалить ценовое уведомление"
            }
        }
    }
    
    // MARK: - Settings Management
    func updateNotificationSettings(_ settings: NotificationSettings) async {
        do {
            try await supabaseService.saveUserSettings(UserSettings(notificationSettings: settings))
            
            await MainActor.run {
                self.notificationSettings = settings
                
                // Update scheduled notifications based on new settings
                self.updateScheduledNotifications()
                
                self.loggingService.info("Notification settings updated", category: "notifications", metadata: [
                    "tradeNotifications": settings.tradeNotifications,
                    "priceAlerts": settings.priceAlerts,
                    "dailySummary": settings.dailySummary
                ])
            }
        } catch {
            await MainActor.run {
                self.loggingService.error("Failed to update notification settings", category: "notifications", error: error)
                self.errorMessage = "Не удалось обновить настройки уведомлений"
            }
        }
    }
    
    private func updateScheduledNotifications() {
        // Remove all scheduled notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Reschedule based on current settings
        if notificationSettings.dailySummary {
            scheduleDailySummary()
        }
        
        if notificationSettings.weeklyReports {
            scheduleWeeklyReport()
        }
        
        // Reschedule price alerts
        for alert in priceAlerts where alert.isEnabled {
            schedulePriceAlert(for: alert)
        }
    }
    
    // MARK: - Data Loading
    private func loadNotificationSettings() {
        Task {
            do {
                let settings = try await supabaseService.getUserSettings()
                
                await MainActor.run {
                    self.notificationSettings = settings.notificationSettings
                }
            } catch {
                await MainActor.run {
                    self.loggingService.error("Failed to load notification settings", category: "notifications", error: error)
                }
            }
        }
    }
    
    private func loadPriceAlerts() {
        Task {
            do {
                let alerts = try await supabaseService.getPriceAlerts()
                
                await MainActor.run {
                    self.priceAlerts = alerts
                }
            } catch {
                await MainActor.run {
                    self.loggingService.error("Failed to load price alerts", category: "notifications", error: error)
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    func checkPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.loggingService.info("Pending notifications checked", category: "notifications", metadata: [
                    "count": requests.count
                ])
            }
        }
    }
    
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        loggingService.info("All notifications cleared", category: "notifications")
    }
    
    func getNotificationStatus() -> NotificationStatus {
        return NotificationStatus(
            isAuthorized: isAuthorized,
            pendingCount: 0, // Would need to fetch this
            deliveredCount: 0 // Would need to fetch this
        )
    }
}

// MARK: - Models
struct NotificationSettings: Codable {
    var tradeNotifications: Bool = true
    var priceAlerts: Bool = true
    var subscriptionReminders: Bool = true
    var dailySummary: Bool = false
    var weeklyReports: Bool = false
    var marketUpdates: Bool = true
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
}

struct PriceAlert: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let targetPrice: Double
    let condition: PriceAlertCondition
    var isEnabled: Bool
    let createdAt: Date
    var updatedAt: Date
    
    init(symbol: String, targetPrice: Double, condition: PriceAlertCondition, isEnabled: Bool = true) {
        self.symbol = symbol
        self.targetPrice = targetPrice
        self.condition = condition
        self.isEnabled = isEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum PriceAlertCondition: String, CaseIterable, Codable {
    case above = "above"
    case below = "below"
    case equals = "equals"
    
    var displayName: String {
        switch self {
        case .above: return "Выше"
        case .below: return "Ниже"
        case .equals: return "Равно"
        }
    }
    
    var symbol: String {
        switch self {
        case .above: return ">"
        case .below: return "<"
        case .equals: return "="
        }
    }
}

struct TradeNotification: Identifiable {
    let id = UUID()
    let tradeId: UUID
    let symbol: String
    let message: String
    let timestamp: Date
    let isRead: Bool
}

struct NotificationStatus {
    let isAuthorized: Bool
    let pendingCount: Int
    let deliveredCount: Int
}

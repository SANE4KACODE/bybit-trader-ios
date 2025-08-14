import Foundation
import StoreKit
import Combine

class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    // MARK: - Published Properties
    @Published var subscriptionStatus: SubscriptionStatus = .trial
    @Published var trialDaysRemaining: Int = 30
    @Published var subscriptionEndDate: Date?
    @Published var monthlyPrice: Decimal = 299.00
    @Published var currency: String = "RUB"
    @Published var countryCode: String = "RU"
    @Published var isSubscribed: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let supabaseService = SupabaseService.shared
    private let loggingService = LoggingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private let trialDuration: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    private let subscriptionProductId = "com.bybittrader.monthly"
    
    private init() {
        setupSubscription()
        loadSubscriptionStatus()
    }
    
    // MARK: - Setup
    private func setupSubscription() {
        // Configure StoreKit
        #if DEBUG
        // Use test environment for development
        #endif
        
        // Observe subscription changes
        NotificationCenter.default.publisher(for: .SKPaymentTransactionStateChanged)
            .sink { [weak self] notification in
                self?.handlePaymentTransactionChanged(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadSubscriptionStatus() {
        isLoading = true
        
        Task {
            do {
                let profile = try await supabaseService.getUserProfile()
                
                await MainActor.run {
                    self.updateSubscriptionStatus(from: profile)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.loggingService.error("Failed to load subscription status", category: "subscription", error: error)
                    self.errorMessage = "Не удалось загрузить статус подписки"
                    self.isLoading = false
                }
            }
        }
    }
    
    func startTrial() {
        guard subscriptionStatus == .none else {
            loggingService.warning("Cannot start trial - user already has subscription", category: "subscription")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let trialStartDate = Date()
                let trialEndDate = trialStartDate.addingTimeInterval(trialDuration)
                
                let profile = UserProfile(
                    email: "user@example.com", // Get from current user
                    subscriptionStatus: "trial",
                    subscriptionStartDate: trialStartDate,
                    subscriptionEndDate: trialEndDate,
                    trialEndDate: trialEndDate,
                    monthlyPrice: monthlyPrice,
                    countryCode: countryCode,
                    currency: currency
                )
                
                try await supabaseService.createUserProfile(profile)
                
                await MainActor.run {
                    self.subscriptionStatus = .trial
                    self.subscriptionEndDate = trialEndDate
                    self.trialDaysRemaining = 30
                    self.isSubscribed = false
                    self.isLoading = false
                    
                    self.loggingService.info("Trial started successfully", category: "subscription", metadata: [
                        "trialStartDate": trialStartDate,
                        "trialEndDate": trialEndDate
                    ])
                }
            } catch {
                await MainActor.run {
                    self.loggingService.error("Failed to start trial", category: "subscription", error: error)
                    self.errorMessage = "Не удалось начать пробный период"
                    self.isLoading = false
                }
            }
        }
    }
    
    func purchaseSubscription() {
        guard subscriptionStatus != .active else {
            loggingService.warning("User already has active subscription", category: "subscription")
            return
        }
        
        isLoading = true
        
        // Request StoreKit products
        let request = SKProductsRequest(productIdentifiers: [subscriptionProductId])
        request.delegate = self
        request.start()
    }
    
    func restorePurchases() {
        isLoading = true
        
        SKPaymentQueue.default().restoreCompletedTransactions()
        
        // Set a timeout for restore
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.isLoading == true {
                self?.isLoading = false
                self?.errorMessage = "Восстановление покупок не завершено"
            }
        }
    }
    
    func cancelSubscription() {
        guard subscriptionStatus == .active else {
            loggingService.warning("Cannot cancel - no active subscription", category: "subscription")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await supabaseService.updateSubscriptionStatus("cancelled")
                
                await MainActor.run {
                    self.subscriptionStatus = .cancelled
                    self.isSubscribed = false
                    self.isLoading = false
                    
                    self.loggingService.info("Subscription cancelled", category: "subscription")
                }
            } catch {
                await MainActor.run {
                    self.loggingService.error("Failed to cancel subscription", category: "subscription", error: error)
                    self.errorMessage = "Не удалось отменить подписку"
                    self.isLoading = false
                }
            }
        }
    }
    
    func checkTrialExpiration() {
        guard subscriptionStatus == .trial,
              let trialEndDate = subscriptionEndDate else { return }
        
        let now = Date()
        if now > trialEndDate {
            // Trial expired
            subscriptionStatus = .expired
            isSubscribed = false
            
            loggingService.info("Trial expired", category: "subscription", metadata: [
                "trialEndDate": trialEndDate,
                "currentDate": now
            ])
            
            // Update Supabase
            Task {
                try? await supabaseService.updateSubscriptionStatus("expired")
            }
        } else {
            // Calculate remaining days
            let remaining = Calendar.current.dateComponents([.day], from: now, to: trialEndDate).day ?? 0
            trialDaysRemaining = max(0, remaining)
        }
    }
    
    func getLocalizedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "\(countryCode)_\(countryCode)")
        
        return formatter.string(from: monthlyPrice as NSDecimalNumber) ?? "\(monthlyPrice) \(currency)"
    }
    
    func getSubscriptionBenefits() -> [SubscriptionBenefit] {
        return [
            SubscriptionBenefit(
                title: "Торговля в реальном времени",
                description: "Получайте обновления цен и позиций каждую секунду",
                icon: "chart.line.uptrend.xyaxis",
                isAvailable: isSubscribed
            ),
            SubscriptionBenefit(
                title: "Расширенная аналитика",
                description: "Детальные графики и технические индикаторы",
                icon: "chart.bar.fill",
                isAvailable: isSubscribed
            ),
            SubscriptionBenefit(
                title: "AI Помощник",
                description: "Персональный торговый советник на базе ИИ",
                icon: "brain.head.profile",
                isAvailable: isSubscribed
            ),
            SubscriptionBenefit(
                title: "Экспорт данных",
                description: "Выгрузка сделок в Excel, CSV, JSON",
                icon: "square.and.arrow.up",
                isAvailable: isSubscribed
            ),
            SubscriptionBenefit(
                title: "Приоритетная поддержка",
                description: "Быстрые ответы от команды поддержки",
                icon: "message.fill",
                isAvailable: isSubscribed
            ),
            SubscriptionBenefit(
                title: "Уведомления",
                description: "Push-уведомления о важных событиях",
                icon: "bell.fill",
                isAvailable: isSubscribed
            )
        ]
    }
    
    // MARK: - Private Methods
    private func updateSubscriptionStatus(from profile: UserProfile) {
        subscriptionStatus = SubscriptionStatus(rawValue: profile.subscriptionStatus) ?? .none
        subscriptionEndDate = profile.subscriptionEndDate
        monthlyPrice = profile.monthlyPrice
        countryCode = profile.countryCode
        currency = profile.currency
        
        // Check if subscription is active
        if let endDate = subscriptionEndDate {
            isSubscribed = endDate > Date() && subscriptionStatus == .active
        } else {
            isSubscribed = false
        }
        
        // Check trial expiration
        if subscriptionStatus == .trial {
            checkTrialExpiration()
        }
        
        loggingService.info("Subscription status updated", category: "subscription", metadata: [
            "status": profile.subscriptionStatus,
            "isSubscribed": isSubscribed,
            "trialDaysRemaining": trialDaysRemaining
        ])
    }
    
    private func handlePaymentTransactionChanged(_ notification: Notification) {
        guard let transaction = notification.object as? SKPaymentTransaction else { return }
        
        switch transaction.transactionState {
        case .purchased, .restored:
            handleSuccessfulPurchase(transaction)
        case .failed:
            handleFailedPurchase(transaction)
        case .deferred:
            handleDeferredPurchase(transaction)
        case .purchasing:
            // Transaction is being processed
            break
        @unknown default:
            break
        }
    }
    
    private func handleSuccessfulPurchase(_ transaction: SKPaymentTransaction) {
        // Verify receipt with your server
        verifyReceipt(transaction)
        
        // Finish the transaction
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleFailedPurchase(_ transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError {
            errorMessage = getErrorMessage(for: error)
            loggingService.error("Purchase failed", category: "subscription", error: error)
        }
        
        isLoading = false
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleDeferredPurchase(_ transaction: SKPaymentTransaction) {
        // Purchase is pending approval (e.g., Ask to Buy enabled)
        errorMessage = "Покупка ожидает одобрения"
        isLoading = false
    }
    
    private func verifyReceipt(_ transaction: SKPaymentTransaction) {
        // In a real app, you would verify the receipt with your server
        // For now, we'll simulate a successful verification
        
        Task {
            do {
                try await supabaseService.updateSubscriptionStatus("active")
                
                await MainActor.run {
                    self.subscriptionStatus = .active
                    self.isSubscribed = true
                    self.isLoading = false
                    
                    self.loggingService.info("Subscription activated", category: "subscription", metadata: [
                        "transactionId": transaction.transactionIdentifier ?? "unknown"
                    ])
                }
            } catch {
                await MainActor.run {
                    self.loggingService.error("Failed to activate subscription", category: "subscription", error: error)
                    self.errorMessage = "Не удалось активировать подписку"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func getErrorMessage(for error: SKError) -> String {
        switch error.code {
        case .paymentCancelled:
            return "Покупка отменена"
        case .paymentInvalid:
            return "Недействительный платеж"
        case .paymentNotAllowed:
            return "Платеж не разрешен"
        case .storeProductNotAvailable:
            return "Продукт недоступен"
        case .cloudServicePermissionDenied:
            return "Доступ к облачным сервисам запрещен"
        case .cloudServiceNetworkConnectionFailed:
            return "Ошибка сетевого подключения"
        case .cloudServiceRevoked:
            return "Облачный сервис отозван"
        default:
            return "Произошла ошибка при покупке"
        }
    }
    
    // MARK: - Timer for Trial Check
    func startTrialCheckTimer() {
        Timer.publish(every: 3600, on: .main, in: .common) // Check every hour
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkTrialExpiration()
            }
            .store(in: &cancellables)
    }
}

// MARK: - SKProductsRequestDelegate
extension SubscriptionService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard let product = response.products.first else {
            DispatchQueue.main.async {
                self.errorMessage = "Продукт не найден"
                self.isLoading = false
            }
            return
        }
        
        // Create payment
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Не удалось загрузить информацию о продукте"
            self.isLoading = false
            self.loggingService.error("Products request failed", category: "subscription", error: error)
        }
    }
}

// MARK: - Models
enum SubscriptionStatus: String, CaseIterable, Codable {
    case none = "none"
    case trial = "trial"
    case active = "active"
    case expired = "expired"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .none: return "Без подписки"
        case .trial: return "Пробный период"
        case .active: return "Активная подписка"
        case .expired: return "Подписка истекла"
        case .cancelled: return "Подписка отменена"
        }
    }
    
    var color: String {
        switch self {
        case .none: return "#6c757d"
        case .trial: return "#ffc107"
        case .active: return "#28a745"
        case .expired: return "#dc3545"
        case .cancelled: return "#6c757d"
        }
    }
}

struct SubscriptionBenefit: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let isAvailable: Bool
}

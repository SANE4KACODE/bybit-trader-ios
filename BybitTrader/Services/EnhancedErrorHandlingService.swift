import Foundation
import SwiftUI
import Combine

class EnhancedErrorHandlingService: ObservableObject {
    static let shared = EnhancedErrorHandlingService()
    
    // MARK: - Published Properties
    @Published var currentError: AppError?
    @Published var errorHistory: [AppError] = []
    @Published var isShowingError = false
    @Published var errorCount = 0
    @Published var criticalErrorCount = 0
    
    // MARK: - Private Properties
    private let loggingService = LoggingService.shared
    private var cancellables = Set<AnyCancellable>()
    private var errorTimer: Timer?
    
    private init() {
        setupService()
    }
    
    // MARK: - Setup
    private func setupService() {
        // Observe error changes
        $currentError
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.handleNewError(error)
            }
            .store(in: &cancellables)
        
        // Start error monitoring
        startErrorMonitoring()
    }
    
    // MARK: - Public Methods
    func handleError(_ error: Error, context: String, severity: ErrorSeverity = .medium) {
        let appError = AppError(
            error: error,
            context: context,
            severity: severity,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.errorHistory.append(appError)
            self.errorCount += 1
            
            if severity == .critical {
                self.criticalErrorCount += 1
            }
            
            // Keep only last 100 errors
            if self.errorHistory.count > 100 {
                self.errorHistory.removeFirst(self.errorHistory.count - 100)
            }
        }
        
        // Log error
        loggingService.error("Error occurred", category: "error_handling", error: error, metadata: [
            "context": context,
            "severity": severity.rawValue,
            "errorCount": errorCount
        ])
        
        // Show error to user
        showErrorToUser(appError)
    }
    
    func handleBybitError(_ error: BybitError, context: String) {
        let appError = AppError(
            error: error,
            context: context,
            severity: getSeverityForBybitError(error),
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.errorHistory.append(appError)
            self.errorCount += 1
        }
        
        // Log specific Bybit error
        loggingService.error("Bybit API error", category: "bybit", metadata: [
            "context": context,
            "errorType": error.localizedDescription,
            "severity": appError.severity.rawValue
        ])
        
        showErrorToUser(appError)
    }
    
    func handleNetworkError(_ error: NetworkError, context: String) {
        let appError = AppError(
            error: error,
            context: context,
            severity: .high,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.errorHistory.append(appError)
            self.errorCount += 1
        }
        
        loggingService.error("Network error", category: "network", metadata: [
            "context": context,
            "errorType": error.localizedDescription
        ])
        
        showErrorToUser(appError)
    }
    
    func handleValidationError(_ error: ValidationError, context: String) {
        let appError = AppError(
            error: error,
            context: context,
            severity: .low,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.errorHistory.append(appError)
            self.errorCount += 1
        }
        
        loggingService.warning("Validation error", category: "validation", metadata: [
            "context": context,
            "errorType": error.localizedDescription
        ])
        
        showErrorToUser(appError)
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.isShowingError = false
        }
    }
    
    func clearAllErrors() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.errorHistory.removeAll()
            self.errorCount = 0
            self.criticalErrorCount = 0
            self.isShowingError = false
        }
        
        loggingService.info("All errors cleared", category: "error_handling")
    }
    
    func retryLastOperation() {
        guard let lastError = errorHistory.last else { return }
        
        loggingService.info("Retrying last operation", category: "error_handling", metadata: [
            "context": lastError.context,
            "errorType": lastError.error.localizedDescription
        ])
        
        // This would typically trigger a retry mechanism
        // Implementation depends on the specific operation
        clearError()
    }
    
    // MARK: - Error Analysis
    func getErrorStatistics() -> ErrorStatistics {
        let totalErrors = errorHistory.count
        let criticalErrors = errorHistory.filter { $0.severity == .critical }.count
        let highErrors = errorHistory.filter { $0.severity == .high }.count
        let mediumErrors = errorHistory.filter { $0.severity == .medium }.count
        let lowErrors = errorHistory.filter { $0.severity == .low }.count
        
        let bybitErrors = errorHistory.filter { $0.error is BybitError }.count
        let networkErrors = errorHistory.filter { $0.error is NetworkError }.count
        let validationErrors = errorHistory.filter { $0.error is ValidationError }.count
        
        let recentErrors = errorHistory.filter { 
            Date().timeIntervalSince($0.timestamp) < 3600 // Last hour
        }.count
        
        return ErrorStatistics(
            totalErrors: totalErrors,
            criticalErrors: criticalErrors,
            highErrors: highErrors,
            mediumErrors: mediumErrors,
            lowErrors: lowErrors,
            bybitErrors: bybitErrors,
            networkErrors: networkErrors,
            validationErrors: validationErrors,
            recentErrors: recentErrors
        )
    }
    
    func getErrorsBySeverity(_ severity: ErrorSeverity) -> [AppError] {
        return errorHistory.filter { $0.severity == severity }
    }
    
    func getErrorsByContext(_ context: String) -> [AppError] {
        return errorHistory.filter { $0.context == context }
    }
    
    func getErrorsByType(_ errorType: String) -> [AppError] {
        return errorHistory.filter { 
            String(describing: type(of: $0.error)) == errorType
        }
    }
    
    // MARK: - Private Methods
    private func handleNewError(_ error: AppError) {
        // Auto-hide low severity errors after 3 seconds
        if error.severity == .low {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                if self?.currentError?.id == error.id {
                    self?.clearError()
                }
            }
        }
        
        // Show critical errors immediately
        if error.severity == .critical {
            showCriticalErrorAlert(error)
        }
        
        // Trigger haptic feedback for high/critical errors
        if error.severity == .high || error.severity == .critical {
            triggerHapticFeedback(.heavy)
        }
    }
    
    private func showErrorToUser(_ error: AppError) {
        DispatchQueue.main.async {
            self.isShowingError = true
        }
        
        // Auto-hide after appropriate time
        let hideDelay: TimeInterval
        switch error.severity {
        case .low:
            hideDelay = 3.0
        case .medium:
            hideDelay = 5.0
        case .high:
            hideDelay = 8.0
        case .critical:
            hideDelay = 0 // Don't auto-hide critical errors
        }
        
        if hideDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay) { [weak self] in
                if self?.currentError?.id == error.id {
                    self?.clearError()
                }
            }
        }
    }
    
    private func showCriticalErrorAlert(_ error: AppError) {
        // Show system alert for critical errors
        DispatchQueue.main.async {
            // This would typically show a system alert
            // Implementation depends on the UI framework
        }
    }
    
    private func getSeverityForBybitError(_ error: BybitError) -> ErrorSeverity {
        switch error {
        case .invalidAPIKey, .insufficientBalance, .orderNotFound:
            return .high
        case .networkError, .timeout:
            return .medium
        case .invalidSymbol, .invalidQuantity:
            return .low
        default:
            return .medium
        }
    }
    
    private func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    private func startErrorMonitoring() {
        // Monitor error patterns
        errorTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.analyzeErrorPatterns()
        }
    }
    
    private func analyzeErrorPatterns() {
        let stats = getErrorStatistics()
        
        // Check for error spikes
        if stats.recentErrors > 10 {
            loggingService.warning("High error rate detected", category: "error_handling", metadata: [
                "recentErrors": stats.recentErrors,
                "totalErrors": stats.totalErrors
            ])
        }
        
        // Check for critical error patterns
        if stats.criticalErrors > 0 {
            loggingService.error("Critical errors detected", category: "error_handling", metadata: [
                "criticalErrors": stats.criticalErrors,
                "totalErrors": stats.totalErrors
            ])
        }
    }
    
    // MARK: - Error Export
    func exportErrorReport() -> String {
        let stats = getErrorStatistics()
        
        var report = "=== Error Report ===\n"
        report += "Generated: \(Date())\n"
        report += "Total Errors: \(stats.totalErrors)\n"
        report += "Critical: \(stats.criticalErrors)\n"
        report += "High: \(stats.highErrors)\n"
        report += "Medium: \(stats.mediumErrors)\n"
        report += "Low: \(stats.lowErrors)\n\n"
        
        report += "By Type:\n"
        report += "Bybit: \(stats.bybitErrors)\n"
        report += "Network: \(stats.networkErrors)\n"
        report += "Validation: \(stats.validationErrors)\n\n"
        
        report += "Recent Errors (Last Hour): \(stats.recentErrors)\n\n"
        
        report += "Error Details:\n"
        for (index, error) in errorHistory.enumerated() {
            report += "\(index + 1). [\(error.severity.rawValue.uppercased())] \(error.context)\n"
            report += "   Error: \(error.error.localizedDescription)\n"
            report += "   Time: \(error.timestamp.formatted())\n\n"
        }
        
        return report
    }
}

// MARK: - Models
struct AppError: Identifiable {
    let id = UUID()
    let error: Error
    let context: String
    let severity: ErrorSeverity
    let timestamp: Date
    
    var userMessage: String {
        return getUserFriendlyMessage()
    }
    
    private func getUserFriendlyMessage() -> String {
        if let bybitError = error as? BybitError {
            return getBybitErrorMessage(bybitError)
        } else if let networkError = error as? NetworkError {
            return getNetworkErrorMessage(networkError)
        } else if let validationError = error as? ValidationError {
            return getValidationErrorMessage(validationError)
        } else {
            return "Произошла ошибка: \(error.localizedDescription)"
        }
    }
    
    private func getBybitErrorMessage(_ error: BybitError) -> String {
        switch error {
        case .invalidAPIKey:
            return "Недействительный API ключ. Проверьте настройки."
        case .insufficientBalance:
            return "Недостаточно средств для выполнения операции."
        case .orderNotFound:
            return "Ордер не найден."
        case .invalidSymbol:
            return "Неверный символ торговой пары."
        case .invalidQuantity:
            return "Неверное количество для ордера."
        case .networkError:
            return "Ошибка сети. Проверьте подключение."
        case .timeout:
            return "Превышено время ожидания ответа."
        default:
            return "Ошибка API Bybit: \(error.localizedDescription)"
        }
    }
    
    private func getNetworkErrorMessage(_ error: NetworkError) -> String {
        switch error {
        case .noConnection:
            return "Нет подключения к интернету."
        case .timeout:
            return "Превышено время ожидания."
        case .serverError:
            return "Ошибка сервера. Попробуйте позже."
        case .invalidResponse:
            return "Получен неверный ответ от сервера."
        default:
            return "Ошибка сети: \(error.localizedDescription)"
        }
    }
    
    private func getValidationErrorMessage(_ error: ValidationError) -> String {
        switch error {
        case .invalidInput:
            return "Неверные входные данные."
        case .requiredFieldMissing:
            return "Заполните все обязательные поля."
        case .invalidFormat:
            return "Неверный формат данных."
        default:
            return "Ошибка валидации: \(error.localizedDescription)"
        }
    }
}

enum ErrorSeverity: String, CaseIterable, Comparable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Низкая"
        case .medium: return "Средняя"
        case .high: return "Высокая"
        case .critical: return "Критическая"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "ℹ️"
        case .medium: return "⚠️"
        case .high: return "🚨"
        case .critical: return "💥"
        }
    }
    
    static func < (lhs: ErrorSeverity, rhs: ErrorSeverity) -> Bool {
        let order: [ErrorSeverity] = [.low, .medium, .high, .critical]
        let lhsIndex = order.firstIndex(of: lhs) ?? 0
        let rhsIndex = order.firstIndex(of: rhs) ?? 0
        return lhsIndex < rhsIndex
    }
}

struct ErrorStatistics {
    let totalErrors: Int
    let criticalErrors: Int
    let highErrors: Int
    let mediumErrors: Int
    let lowErrors: Int
    let bybitErrors: Int
    let networkErrors: Int
    let validationErrors: Int
    let recentErrors: Int
}

// MARK: - Error Types
enum BybitError: LocalizedError {
    case invalidAPIKey
    case insufficientBalance
    case orderNotFound
    case invalidSymbol
    case invalidQuantity
    case networkError
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key"
        case .insufficientBalance:
            return "Insufficient balance"
        case .orderNotFound:
            return "Order not found"
        case .invalidSymbol:
            return "Invalid symbol"
        case .invalidQuantity:
            return "Invalid quantity"
        case .networkError:
            return "Network error"
        case .timeout:
            return "Request timeout"
        case .unknown:
            return "Unknown error"
        }
    }
}

enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case serverError
    case invalidResponse
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timeout"
        case .serverError:
            return "Server error"
        case .invalidResponse:
            return "Invalid response"
        case .unknown:
            return "Unknown network error"
        }
    }
}

enum ValidationError: LocalizedError {
    case invalidInput
    case requiredFieldMissing
    case invalidFormat
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input"
        case .requiredFieldMissing:
            return "Required field missing"
        case .invalidFormat:
            return "Invalid format"
        case .unknown:
            return "Unknown validation error"
        }
    }
}

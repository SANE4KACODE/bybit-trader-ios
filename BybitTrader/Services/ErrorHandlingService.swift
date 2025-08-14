import Foundation
import SwiftUI

// MARK: - Error Handling Service
class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    // MARK: - Published Properties
    @Published var currentError: AppError?
    @Published var errorHistory: [AppError] = []
    @Published var isShowingError = false
    @Published var errorCount: Int = 0
    
    // MARK: - Private Properties
    private let loggingService = LoggingService.shared
    private let maxErrorHistory = 100
    
    private init() {
        setupErrorHandling()
    }
    
    // MARK: - Setup
    private func setupErrorHandling() {
        // Настраиваем глобальную обработку ошибок
        NSSetUncaughtExceptionHandler { exception in
            let error = AppError(
                type: .system,
                title: "Системная ошибка",
                message: exception.reason ?? "Неизвестная системная ошибка",
                code: "SYSTEM_ERROR",
                severity: .critical,
                timestamp: Date(),
                metadata: [
                    "exceptionName": exception.name.rawValue,
                    "callStack": exception.callStackSymbols.joined(separator: "\n")
                ]
            )
            
            ErrorHandlingService.shared.handleError(error)
        }
    }
    
    // MARK: - Public Methods
    func handleError(_ error: AppError) {
        DispatchQueue.main.async {
            self.currentError = error
            self.errorHistory.append(error)
            self.errorCount += 1
            self.isShowingError = true
            
            // Логируем ошибку
            self.loggingService.error(
                "\(error.title): \(error.message)",
                category: "error_handling",
                error: error.underlyingError,
                metadata: error.metadata
            )
            
            // Отправляем аналитику
            self.sendErrorAnalytics(error)
            
            // Показываем уведомление для критических ошибок
            if error.severity == .critical {
                self.showCriticalErrorNotification(error)
            }
            
            // Ограничиваем историю ошибок
            if self.errorHistory.count > self.maxErrorHistory {
                self.errorHistory.removeFirst(self.errorHistory.count - self.maxErrorHistory)
            }
        }
    }
    
    func handleError(
        type: AppError.ErrorType,
        title: String,
        message: String,
        code: String? = nil,
        severity: AppError.Severity = .error,
        underlyingError: Error? = nil,
        metadata: [String: Any]? = nil
    ) {
        let error = AppError(
            type: type,
            title: title,
            message: message,
            code: code,
            severity: severity,
            timestamp: Date(),
            underlyingError: underlyingError,
            metadata: metadata
        )
        
        handleError(error)
    }
    
    func clearCurrentError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.isShowingError = false
        }
    }
    
    func clearErrorHistory() {
        DispatchQueue.main.async {
            self.errorHistory.removeAll()
            self.errorCount = 0
        }
    }
    
    func getErrorsByType(_ type: AppError.ErrorType) -> [AppError] {
        return errorHistory.filter { $0.type == type }
    }
    
    func getErrorsBySeverity(_ severity: AppError.Severity) -> [AppError] {
        return errorHistory.filter { $0.severity == severity }
    }
    
    func getErrorsByCode(_ code: String) -> [AppError] {
        return errorHistory.filter { $0.code == code }
    }
    
    // MARK: - Specific Error Handlers
    func handleNetworkError(_ error: Error, context: String? = nil) {
        let networkError = AppError(
            type: .network,
            title: "Ошибка сети",
            message: getNetworkErrorMessage(error),
            code: "NETWORK_ERROR",
            severity: .error,
            timestamp: Date(),
            underlyingError: error,
            metadata: [
                "context": context ?? "unknown",
                "errorType": String(describing: type(of: error))
            ]
        )
        
        handleError(networkError)
    }
    
    func handleAPIError(_ error: Error, endpoint: String, statusCode: Int? = nil) {
        let apiError = AppError(
            type: .api,
            title: "Ошибка API",
            message: getAPIErrorMessage(error, statusCode: statusCode),
            code: "API_ERROR",
            severity: .error,
            timestamp: Date(),
            underlyingError: error,
            metadata: [
                "endpoint": endpoint,
                "statusCode": statusCode ?? 0,
                "errorType": String(describing: type(of: error))
            ]
        )
        
        handleError(apiError)
    }
    
    func handleValidationError(_ field: String, message: String) {
        let validationError = AppError(
            type: .validation,
            title: "Ошибка валидации",
            message: "\(field): \(message)",
            code: "VALIDATION_ERROR",
            severity: .warning,
            timestamp: Date(),
            metadata: [
                "field": field,
                "message": message
            ]
        )
        
        handleError(validationError)
    }
    
    func handleDatabaseError(_ error: Error, operation: String) {
        let dbError = AppError(
            type: .database,
            title: "Ошибка базы данных",
            message: "Не удалось выполнить операцию: \(operation)",
            code: "DATABASE_ERROR",
            severity: .error,
            timestamp: Date(),
            underlyingError: error,
            metadata: [
                "operation": operation,
                "errorType": String(describing: type(of: error))
            ]
        )
        
        handleError(dbError)
    }
    
    func handleSecurityError(_ error: Error, context: String) {
        let securityError = AppError(
            type: .security,
            title: "Ошибка безопасности",
            message: "Проблема с безопасностью: \(context)",
            code: "SECURITY_ERROR",
            severity: .critical,
            timestamp: Date(),
            underlyingError: error,
            metadata: [
                "context": context,
                "errorType": String(describing: type(of: error))
            ]
        )
        
        handleError(securityError)
    }
    
    // MARK: - Private Methods
    private func getNetworkErrorMessage(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "Нет подключения к интернету"
            case .timedOut:
                return "Превышено время ожидания"
            case .cannotFindHost:
                return "Сервер не найден"
            case .cannotConnectToHost:
                return "Не удается подключиться к серверу"
            case .networkConnectionLost:
                return "Соединение с сетью потеряно"
            default:
                return "Ошибка сети: \(urlError.localizedDescription)"
            }
        }
        
        return "Ошибка сети: \(error.localizedDescription)"
    }
    
    private func getAPIErrorMessage(_ error: Error, statusCode: Int?) -> String {
        if let statusCode = statusCode {
            switch statusCode {
            case 400:
                return "Неверный запрос"
            case 401:
                return "Не авторизован"
            case 403:
                return "Доступ запрещен"
            case 404:
                return "Ресурс не найден"
            case 429:
                return "Слишком много запросов"
            case 500:
                return "Внутренняя ошибка сервера"
            case 502:
                return "Сервер недоступен"
            case 503:
                return "Сервис временно недоступен"
            default:
                return "Ошибка API (код: \(statusCode))"
            }
        }
        
        return "Ошибка API: \(error.localizedDescription)"
    }
    
    private func sendErrorAnalytics(_ error: AppError) {
        // Отправляем аналитику об ошибке
        let analyticsData: [String: Any] = [
            "error_type": error.type.rawValue,
            "error_code": error.code ?? "unknown",
            "severity": error.severity.rawValue,
            "timestamp": error.timestamp.timeIntervalSince1970,
            "metadata": error.metadata ?? [:]
        ]
        
        // Здесь можно интегрировать с внешними сервисами аналитики
        loggingService.info("Error analytics sent", category: "analytics", metadata: analyticsData)
    }
    
    private func showCriticalErrorNotification(_ error: AppError) {
        // Показываем критическое уведомление
        let content = UNMutableNotificationContent()
        content.title = "Критическая ошибка"
        content.body = error.message
        content.sound = .default
        content.categoryIdentifier = "CRITICAL_ERROR"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "critical_error_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - App Error Model
struct AppError: Identifiable, Codable {
    let id = UUID()
    let type: ErrorType
    let title: String
    let message: String
    let code: String?
    let severity: Severity
    let timestamp: Date
    let underlyingError: Error?
    let metadata: [String: Any]?
    
    enum ErrorType: String, CaseIterable, Codable {
        case network = "network"
        case api = "api"
        case validation = "validation"
        case database = "database"
        case security = "security"
        case system = "system"
        case user = "user"
        case unknown = "unknown"
        
        var displayName: String {
            switch self {
            case .network: return "Сеть"
            case .api: return "API"
            case .validation: return "Валидация"
            case .database: return "База данных"
            case .security: return "Безопасность"
            case .system: return "Система"
            case .user: return "Пользователь"
            case .unknown: return "Неизвестно"
            }
        }
        
        var icon: String {
            switch self {
            case .network: return "wifi.slash"
            case .api: return "server.rack"
            case .validation: return "exclamationmark.triangle"
            case .database: return "cylinder"
            case .security: return "lock.shield"
            case .system: return "gearshape"
            case .user: return "person.crop.circle"
            case .unknown: return "questionmark.circle"
            }
        }
    }
    
    enum Severity: String, CaseIterable, Codable {
        case low = "low"
        case warning = "warning"
        case error = "error"
        case critical = "critical"
        
        var displayName: String {
            switch self {
            case .low: return "Низкая"
            case .warning: return "Предупреждение"
            case .error: return "Ошибка"
            case .critical: return "Критическая"
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .warning: return .orange
            case .error: return .red
            case .critical: return .purple
            }
        }
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case type, title, message, code, severity, timestamp, metadata
    }
    
    init(type: ErrorType, title: String, message: String, code: String? = nil, severity: Severity = .error, timestamp: Date = Date(), underlyingError: Error? = nil, metadata: [String: Any]? = nil) {
        self.type = type
        self.title = title
        self.message = message
        self.code = code
        self.severity = severity
        self.timestamp = timestamp
        self.underlyingError = underlyingError
        self.metadata = metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(ErrorType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        severity = try container.decode(Severity.self, forKey: .severity)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        metadata = try container.decodeIfPresent([String: Any].self, forKey: .metadata)
        underlyingError = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(code, forKey: .code)
        try container.encode(severity, forKey: .severity)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: AppError
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Иконка ошибки
            Image(systemName: error.type.icon)
                .font(.system(size: 60))
                .foregroundColor(error.severity.color)
            
            // Заголовок
            Text(error.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Сообщение
            Text(error.message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            // Код ошибки (если есть)
            if let code = error.code {
                Text("Код: \(code)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Время ошибки
            Text("Время: \(error.timestamp.formatted())")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Кнопка закрытия
            Button("Закрыть") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

// MARK: - Error Alert
struct ErrorAlert: ViewModifier {
    @ObservedObject var errorService: ErrorHandlingService
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorService.currentError?.title ?? "Ошибка",
                isPresented: $errorService.isShowingError
            ) {
                Button("OK") {
                    errorService.clearCurrentError()
                }
            } message: {
                if let error = errorService.currentError {
                    Text(error.message)
                }
            }
    }
}

// MARK: - View Extension
extension View {
    func errorAlert(_ errorService: ErrorHandlingService) -> some View {
        self.modifier(ErrorAlert(errorService: errorService))
    }
}

import Foundation
import LocalAuthentication
import CryptoKit
import Security
import Combine

class SecurityService: ObservableObject {
    static let shared = SecurityService()
    
    // MARK: - Published Properties
    @Published var isBiometricEnabled = false
    @Published var isBiometricAvailable = false
    @Published var biometricType: BiometricType = .none
    @Published var isLocked = false
    @Published var autoLockTimeout: TimeInterval = 300 // 5 minutes
    @Published var requireBiometricOnLaunch = true
    @Published var requireBiometricOnTrade = true
    @Published var isEncryptionEnabled = true
    @Published var securityLevel: SecurityLevel = .high
    @Published var lastUnlockTime: Date?
    @Published var failedAttempts = 0
    @Published var isLockedOut = false
    @Published var lockoutEndTime: Date?
    
    // MARK: - Private Properties
    private let loggingService = LoggingService.shared
    private let keychainService = KeychainService()
    private var cancellables = Set<AnyCancellable>()
    private var autoLockTimer: Timer?
    private let maxFailedAttempts = 5
    private let lockoutDuration: TimeInterval = 900 // 15 minutes
    
    // MARK: - Constants
    private let biometricContext = LAContext()
    private let encryptionKeyIdentifier = "com.bybittrader.encryption.key"
    private let apiKeyIdentifier = "com.bybittrader.api.key"
    private let apiSecretIdentifier = "com.bybittrader.api.secret"
    
    private init() {
        setupSecurity()
        checkBiometricAvailability()
        loadSecuritySettings()
    }
    
    // MARK: - Setup
    private func setupSecurity() {
        // Start auto-lock timer
        startAutoLockTimer()
        
        // Observe app state changes
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppForeground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppResignActive()
            }
            .store(in: &cancellables)
    }
    
    private func checkBiometricAvailability() {
        var error: NSError?
        
        if biometricContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
            
            switch biometricContext.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            default:
                biometricType = .none
            }
            
            loggingService.info("Biometric authentication available", category: "security", metadata: [
                "type": biometricType.rawValue
            ])
        } else {
            isBiometricAvailable = false
            biometricType = .none
            
            if let error = error {
                loggingService.warning("Biometric authentication not available", category: "security", metadata: [
                    "error": error.localizedDescription
                ])
            }
        }
    }
    
    private func loadSecuritySettings() {
        // Load settings from UserDefaults or Keychain
        isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
        requireBiometricOnLaunch = UserDefaults.standard.bool(forKey: "requireBiometricOnLaunch")
        requireBiometricOnTrade = UserDefaults.standard.bool(forKey: "requireBiometricOnTrade")
        autoLockTimeout = UserDefaults.standard.double(forKey: "autoLockTimeout")
        
        if autoLockTimeout == 0 {
            autoLockTimeout = 300 // Default 5 minutes
        }
        
        // Check if app is locked
        if let lastUnlock = lastUnlockTime {
            let timeSinceUnlock = Date().timeIntervalSince(lastUnlock)
            if timeSinceUnlock > autoLockTimeout {
                isLocked = true
            }
        }
    }
    
    // MARK: - Public Methods
    func enableBiometricAuthentication() async -> Bool {
        guard isBiometricAvailable else {
            loggingService.warning("Cannot enable biometric - not available", category: "security")
            return false
        }
        
        do {
            let success = try await authenticateWithBiometrics(reason: "Включить биометрическую аутентификацию")
            
            if success {
                await MainActor.run {
                    self.isBiometricEnabled = true
                    UserDefaults.standard.set(true, forKey: "biometricEnabled")
                }
                
                loggingService.info("Biometric authentication enabled", category: "security")
                return true
            } else {
                loggingService.warning("Biometric authentication failed during setup", category: "security")
                return false
            }
        } catch {
            loggingService.error("Failed to enable biometric authentication", category: "security", error: error)
            return false
        }
    }
    
    func disableBiometricAuthentication() {
        isBiometricEnabled = false
        UserDefaults.standard.set(false, forKey: "biometricEnabled")
        
        loggingService.info("Biometric authentication disabled", category: "security")
    }
    
    func unlockApp() async -> Bool {
        guard !isLockedOut else {
            if let lockoutEnd = lockoutEndTime, Date() > lockoutEnd {
                // Lockout period ended
                await MainActor.run {
                    self.isLockedOut = false
                    self.failedAttempts = 0
                    self.lockoutEndTime = nil
                }
            } else {
                loggingService.warning("App is locked out", category: "security")
                return false
            }
        }
        
        if isBiometricEnabled && requireBiometricOnLaunch {
            let success = await authenticateWithBiometrics(reason: "Разблокировать приложение")
            
            if success {
                await MainActor.run {
                    self.isLocked = false
                    self.lastUnlockTime = Date()
                    self.failedAttempts = 0
                }
                
                startAutoLockTimer()
                loggingService.info("App unlocked successfully", category: "security")
                return true
            } else {
                await MainActor.run {
                    self.failedAttempts += 1
                    
                    if self.failedAttempts >= self.maxFailedAttempts {
                        self.isLockedOut = true
                        self.lockoutEndTime = Date().addingTimeInterval(self.lockoutDuration)
                        
                        self.loggingService.warning("App locked out due to failed attempts", category: "security", metadata: [
                            "failedAttempts": self.failedAttempts,
                            "lockoutEndTime": self.lockoutEndTime ?? Date()
                        ])
                    }
                }
                
                loggingService.warning("App unlock failed", category: "security", metadata: [
                    "failedAttempts": failedAttempts
                ])
                return false
            }
        } else {
            // No biometric required
            await MainActor.run {
                self.isLocked = false
                self.lastUnlockTime = Date()
            }
            
            startAutoLockTimer()
            loggingService.info("App unlocked without biometric", category: "security")
            return true
        }
    }
    
    func lockApp() {
        isLocked = true
        lastUnlockTime = nil
        stopAutoLockTimer()
        
        loggingService.info("App locked manually", category: "security")
    }
    
    func requireBiometricForTrade() async -> Bool {
        guard isBiometricEnabled && requireBiometricOnTrade else { return true }
        
        let success = await authenticateWithBiometrics(reason: "Подтвердить торговую операцию")
        
        if success {
            loggingService.info("Trade biometric authentication successful", category: "security")
        } else {
            loggingService.warning("Trade biometric authentication failed", category: "security")
        }
        
        return success
    }
    
    func encryptData(_ data: Data) -> Data? {
        guard isEncryptionEnabled else { return data }
        
        do {
            let key = try getOrGenerateEncryptionKey()
            let encryptedData = try ChaChaPoly.seal(data, using: key)
            return encryptedData.combined
        } catch {
            loggingService.error("Failed to encrypt data", category: "security", error: error)
            return nil
        }
    }
    
    func decryptData(_ encryptedData: Data) -> Data? {
        guard isEncryptionEnabled else { return encryptedData }
        
        do {
            let key = try getOrGenerateEncryptionKey()
            let sealedBox = try ChaChaPoly.SealedBox(combined: encryptedData)
            let decryptedData = try ChaChaPoly.open(sealedBox, using: key)
            return decryptedData
        } catch {
            loggingService.error("Failed to decrypt data", category: "security", error: error)
            return nil
        }
    }
    
    func storeAPIKey(_ apiKey: String, secret: String) -> Bool {
        do {
            let encryptedKey = encryptData(apiKey.data(using: .utf8) ?? Data())
            let encryptedSecret = encryptData(secret.data(using: .utf8) ?? Data())
            
            guard let encryptedKey = encryptedKey, let encryptedSecret = encryptedSecret else {
                loggingService.error("Failed to encrypt API credentials", category: "security")
                return false
            }
            
            try keychainService.store(key: apiKeyIdentifier, data: encryptedKey)
            try keychainService.store(key: apiSecretIdentifier, data: encryptedSecret)
            
            loggingService.info("API credentials stored securely", category: "security")
            return true
        } catch {
            loggingService.error("Failed to store API credentials", category: "security", error: error)
            return false
        }
    }
    
    func retrieveAPIKey() -> (key: String, secret: String)? {
        do {
            guard let encryptedKeyData = try keychainService.retrieve(key: apiKeyIdentifier),
                  let encryptedSecretData = try keychainService.retrieve(key: apiSecretIdentifier) else {
                loggingService.warning("API credentials not found", category: "security")
                return nil
            }
            
            guard let decryptedKeyData = decryptData(encryptedKeyData),
                  let decryptedSecretData = decryptData(encryptedSecretData),
                  let apiKey = String(data: decryptedKeyData, encoding: .utf8),
                  let apiSecret = String(data: decryptedSecretData, encoding: .utf8) else {
                loggingService.error("Failed to decrypt API credentials", category: "security")
                return nil
            }
            
            return (key: apiKey, secret: apiSecret)
        } catch {
            loggingService.error("Failed to retrieve API credentials", category: "security", error: error)
            return nil
        }
    }
    
    func clearAPIKey() {
        do {
            try keychainService.delete(key: apiKeyIdentifier)
            try keychainService.delete(key: apiSecretIdentifier)
            
            loggingService.info("API credentials cleared", category: "security")
        } catch {
            loggingService.error("Failed to clear API credentials", category: "security", error: error)
        }
    }
    
    func updateSecuritySettings(
        biometricEnabled: Bool? = nil,
        requireOnLaunch: Bool? = nil,
        requireOnTrade: Bool? = nil,
        autoLockTimeout: TimeInterval? = nil,
        encryptionEnabled: Bool? = nil
    ) {
        if let biometricEnabled = biometricEnabled {
            self.isBiometricEnabled = biometricEnabled
            UserDefaults.standard.set(biometricEnabled, forKey: "biometricEnabled")
        }
        
        if let requireOnLaunch = requireOnLaunch {
            self.requireBiometricOnLaunch = requireOnLaunch
            UserDefaults.standard.set(requireOnLaunch, forKey: "requireBiometricOnLaunch")
        }
        
        if let requireOnTrade = requireOnTrade {
            self.requireBiometricOnTrade = requireOnTrade
            UserDefaults.standard.set(requireOnTrade, forKey: "requireBiometricOnTrade")
        }
        
        if let autoLockTimeout = autoLockTimeout {
            self.autoLockTimeout = autoLockTimeout
            UserDefaults.standard.set(autoLockTimeout, forKey: "autoLockTimeout")
        }
        
        if let encryptionEnabled = encryptionEnabled {
            self.isEncryptionEnabled = encryptionEnabled
        }
        
        loggingService.info("Security settings updated", category: "security", metadata: [
            "biometricEnabled": self.isBiometricEnabled,
            "requireOnLaunch": self.requireBiometricOnLaunch,
            "requireOnTrade": self.requireBiometricOnTrade,
            "autoLockTimeout": self.autoLockTimeout,
            "encryptionEnabled": self.isEncryptionEnabled
        ])
    }
    
    func getSecurityStatus() -> SecurityStatus {
        return SecurityStatus(
            isBiometricEnabled: isBiometricEnabled,
            isBiometricAvailable: isBiometricAvailable,
            biometricType: biometricType,
            isLocked: isLocked,
            isEncryptionEnabled: isEncryptionEnabled,
            securityLevel: securityLevel,
            lastUnlockTime: lastUnlockTime,
            failedAttempts: failedAttempts,
            isLockedOut: isLockedOut,
            lockoutEndTime: lockoutEndTime
        )
    }
    
    func performSecurityAudit() -> SecurityAuditResult {
        var issues: [SecurityIssue] = []
        var recommendations: [String] = []
        
        // Check biometric settings
        if isBiometricAvailable && !isBiometricEnabled {
            issues.append(SecurityIssue(
                type: .warning,
                title: "Биометрическая аутентификация отключена",
                description: "Рекомендуется включить для повышения безопасности",
                severity: .medium
            ))
            recommendations.append("Включить биометрическую аутентификацию")
        }
        
        // Check auto-lock timeout
        if autoLockTimeout > 900 { // More than 15 minutes
            issues.append(SecurityIssue(
                type: .warning,
                title: "Длительное время авто-блокировки",
                description: "Текущий таймаут: \(Int(autoLockTimeout / 60)) минут",
                severity: .low
            ))
            recommendations.append("Уменьшить время авто-блокировки")
        }
        
        // Check encryption
        if !isEncryptionEnabled {
            issues.append(SecurityIssue(
                type: .critical,
                title: "Шифрование отключено",
                description: "Данные не защищены шифрованием",
                severity: .high
            ))
            recommendations.append("Включить шифрование данных")
        }
        
        // Check failed attempts
        if failedAttempts > 0 {
            issues.append(SecurityIssue(
                type: .info,
                title: "Неудачные попытки входа",
                description: "Количество: \(failedAttempts)",
                severity: .low
            ))
        }
        
        let overallScore = calculateSecurityScore(issues: issues)
        
        return SecurityAuditResult(
            score: overallScore,
            issues: issues,
            recommendations: recommendations,
            timestamp: Date()
        )
    }
    
    // MARK: - Private Methods
    private func authenticateWithBiometrics(reason: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            biometricContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if let error = error {
                    self.loggingService.error("Biometric authentication error", category: "security", error: error)
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    private func getOrGenerateEncryptionKey() throws -> SymmetricKey {
        if let existingKey = try? keychainService.retrieve(key: encryptionKeyIdentifier),
           let keyData = decryptData(existingKey) {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        if let encryptedKeyData = encryptData(keyData) {
            try keychainService.store(key: encryptionKeyIdentifier, data: encryptedKeyData)
        }
        
        return newKey
    }
    
    private func startAutoLockTimer() {
        stopAutoLockTimer()
        
        autoLockTimer = Timer.scheduledTimer(withTimeInterval: autoLockTimeout, repeats: false) { [weak self] _ in
            self?.autoLockApp()
        }
    }
    
    private func stopAutoLockTimer() {
        autoLockTimer?.invalidate()
        autoLockTimer = nil
    }
    
    private func autoLockApp() {
        isLocked = true
        lastUnlockTime = nil
        
        loggingService.info("App auto-locked", category: "security", metadata: [
            "timeout": autoLockTimeout
        ])
    }
    
    private func handleAppBackground() {
        // App going to background - start auto-lock timer
        startAutoLockTimer()
        
        loggingService.info("App entered background", category: "security")
    }
    
    private func handleAppForeground() {
        // App coming to foreground - check if locked
        if let lastUnlock = lastUnlockTime {
            let timeSinceUnlock = Date().timeIntervalSince(lastUnlock)
            if timeSinceUnlock > autoLockTimeout {
                isLocked = true
                loggingService.info("App locked due to timeout", category: "security")
            }
        }
        
        loggingService.info("App entered foreground", category: "security")
    }
    
    private func handleAppResignActive() {
        // App becoming inactive - lock immediately if configured
        if securityLevel == .maximum {
            isLocked = true
            lastUnlockTime = nil
            loggingService.info("App locked due to inactivity", category: "security")
        }
    }
    
    private func calculateSecurityScore(issues: [SecurityIssue]) -> Int {
        var score = 100
        
        for issue in issues {
            switch issue.severity {
            case .critical:
                score -= 30
            case .high:
                score -= 20
            case .medium:
                score -= 10
            case .low:
                score -= 5
            }
        }
        
        return max(0, score)
    }
}

// MARK: - Keychain Service
class KeychainService {
    private let service = "com.bybittrader.keychain"
    
    func store(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item already exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            
            if updateStatus != errSecSuccess {
                throw KeychainError.saveFailed(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func retrieve(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw KeychainError.loadFailed(status)
        }
    }
    
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Models
enum BiometricType: String, CaseIterable {
    case none = "none"
    case touchID = "touchID"
    case faceID = "faceID"
    
    var displayName: String {
        switch self {
        case .none: return "Недоступно"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "lock"
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        }
    }
}

enum SecurityLevel: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case maximum = "maximum"
    
    var displayName: String {
        switch self {
        case .low: return "Низкий"
        case .medium: return "Средний"
        case .high: return "Высокий"
        case .maximum: return "Максимальный"
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Базовая защита"
        case .medium: return "Стандартная защита"
        case .high: return "Повышенная защита"
        case .maximum: return "Максимальная защита"
        }
    }
}

struct SecurityStatus {
    let isBiometricEnabled: Bool
    let isBiometricAvailable: Bool
    let biometricType: BiometricType
    let isLocked: Bool
    let isEncryptionEnabled: Bool
    let securityLevel: SecurityLevel
    let lastUnlockTime: Date?
    let failedAttempts: Int
    let isLockedOut: Bool
    let lockoutEndTime: Date?
}

struct SecurityIssue: Identifiable {
    let id = UUID()
    let type: SecurityIssueType
    let title: String
    let description: String
    let severity: SecurityIssueSeverity
}

enum SecurityIssueType: String {
    case info = "info"
    case warning = "warning"
    case critical = "critical"
}

enum SecurityIssueSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var color: String {
        switch self {
        case .low: return "#28a745"
        case .medium: return "#ffc107"
        case .high: return "#fd7e14"
        case .critical: return "#dc3545"
        }
    }
}

struct SecurityAuditResult {
    let score: Int
    let issues: [SecurityIssue]
    let recommendations: [String]
    let timestamp: Date
    
    var scoreColor: String {
        if score >= 80 { return "#28a745" }
        if score >= 60 { return "#ffc107" }
        if score >= 40 { return "#fd7e14" }
        return "#dc3545"
    }
    
    var scoreDescription: String {
        if score >= 80 { return "Отлично" }
        if score >= 60 { return "Хорошо" }
        if score >= 40 { return "Удовлетворительно" }
        return "Требует внимания"
    }
}

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .loadFailed(let status):
            return "Failed to load from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        }
    }
}

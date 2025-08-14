import Foundation
import SwiftUI

class SettingsService: ObservableObject {
    @Published var userSettings: UserSettings
    @Published var notificationSettings: NotificationSettings
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        // Загружаем настройки пользователя
        if let data = userDefaults.data(forKey: "userSettings"),
           let settings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.userSettings = settings
        } else {
            self.userSettings = UserSettings()
        }
        
        // Загружаем настройки уведомлений
        if let data = userDefaults.data(forKey: "notificationSettings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.notificationSettings = settings
        } else {
            self.notificationSettings = NotificationSettings()
        }
    }
    
    // MARK: - User Settings
    func updateUserSettings(_ settings: UserSettings) {
        self.userSettings = settings
        saveUserSettings()
    }
    
    func updateApiKeys(apiKey: String, secretKey: String, testnet: Bool) {
        userSettings.apiKey = apiKey
        userSettings.secretKey = secretKey
        userSettings.testnet = testnet
        saveUserSettings()
    }
    
    func updateSelectedSymbol(_ symbol: String) {
        userSettings.selectedSymbol = symbol
        saveUserSettings()
    }
    
    func toggleAutoRefresh() {
        userSettings.autoRefresh.toggle()
        saveUserSettings()
    }
    
    func updateRefreshInterval(_ interval: Int) {
        userSettings.refreshInterval = interval
        saveUserSettings()
    }
    
    func toggleNotifications() {
        userSettings.notificationsEnabled.toggle()
        saveUserSettings()
    }
    
    func toggleDarkMode() {
        userSettings.darkModeEnabled.toggle()
        saveUserSettings()
    }
    
    func toggleBiometricAuth() {
        userSettings.biometricAuthEnabled.toggle()
        saveUserSettings()
    }
    
    private func saveUserSettings() {
        if let data = try? JSONEncoder().encode(userSettings) {
            userDefaults.set(data, forKey: "userSettings")
        }
    }
    
    // MARK: - Notification Settings
    func updateNotificationSettings(_ settings: NotificationSettings) {
        self.notificationSettings = settings
        saveNotificationSettings()
    }
    
    func togglePriceAlerts() {
        notificationSettings.priceAlerts.toggle()
        saveNotificationSettings()
    }
    
    func toggleOrderExecuted() {
        notificationSettings.orderExecuted.toggle()
        saveNotificationSettings()
    }
    
    func togglePositionClosed() {
        notificationSettings.positionClosed.toggle()
        saveNotificationSettings()
    }
    
    func toggleBalanceChanges() {
        notificationSettings.balanceChanges.toggle()
        saveNotificationSettings()
    }
    
    func toggleSound() {
        notificationSettings.soundEnabled.toggle()
        saveNotificationSettings()
    }
    
    func toggleVibration() {
        notificationSettings.vibrationEnabled.toggle()
        saveNotificationSettings()
    }
    
    private func saveNotificationSettings() {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            userDefaults.set(data, forKey: "notificationSettings")
        }
    }
    
    // MARK: - Data Export
    func exportSettings() -> String {
        let userSettingsJson = try? JSONEncoder().encode(userSettings)
        let notificationSettingsJson = try? JSONEncoder().encode(notificationSettings)
        
        let export = """
        === НАСТРОЙКИ ПОЛЬЗОВАТЕЛЯ ===
        \(String(data: userSettingsJson ?? Data(), encoding: .utf8) ?? "Ошибка кодирования")
        
        === НАСТРОЙКИ УВЕДОМЛЕНИЙ ===
        \(String(data: notificationSettingsJson ?? Data(), encoding: .utf8) ?? "Ошибка кодирования")
        
        Экспортировано: \(Date())
        """
        
        return export
    }
    
    // MARK: - Reset Settings
    func resetToDefaults() {
        userSettings = UserSettings()
        notificationSettings = NotificationSettings()
        
        userDefaults.removeObject(forKey: "userSettings")
        userDefaults.removeObject(forKey: "notificationSettings")
    }
    
    // MARK: - Security
    func clearSensitiveData() {
        userSettings.apiKey = ""
        userSettings.secretKey = ""
        saveUserSettings()
    }
    
    // MARK: - Validation
    func validateApiKeys() -> Bool {
        return !userSettings.apiKey.isEmpty && !userSettings.secretKey.isEmpty
    }
    
    func validateSymbol(_ symbol: String) -> Bool {
        // Простая валидация символа торговой пары
        let pattern = "^[A-Z0-9]+USDT$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: symbol.utf16.count)
        return regex?.firstMatch(in: symbol, range: range) != nil
    }
}

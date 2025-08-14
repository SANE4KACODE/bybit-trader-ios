import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var settingsService: SettingsService
    
    var body: some View {
        List {
            Section("Типы уведомлений") {
                Toggle("Уведомления о ценах", isOn: $settingsService.notificationSettings.priceAlerts)
                    .onChange(of: settingsService.notificationSettings.priceAlerts) { _ in
                        settingsService.togglePriceAlerts()
                    }
                
                Toggle("Исполнение ордеров", isOn: $settingsService.notificationSettings.orderExecuted)
                    .onChange(of: settingsService.notificationSettings.orderExecuted) { _ in
                        settingsService.toggleOrderExecuted()
                    }
                
                Toggle("Закрытие позиций", isOn: $settingsService.notificationSettings.positionClosed)
                    .onChange(of: settingsService.notificationSettings.positionClosed) { _ in
                        settingsService.togglePositionClosed()
                    }
                
                Toggle("Изменения баланса", isOn: $settingsService.notificationSettings.balanceChanges)
                    .onChange(of: settingsService.notificationSettings.balanceChanges) { _ in
                        settingsService.toggleBalanceChanges()
                    }
            }
            
            Section("Способы уведомлений") {
                Toggle("Звук", isOn: $settingsService.notificationSettings.soundEnabled)
                    .onChange(of: settingsService.notificationSettings.soundEnabled) { _ in
                        settingsService.toggleSound()
                    }
                
                Toggle("Вибрация", isOn: $settingsService.notificationSettings.vibrationEnabled)
                    .onChange(of: settingsService.notificationSettings.vibrationEnabled) { _ in
                        settingsService.toggleVibration()
                    }
            }
            
            Section("Информация") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Уведомления помогут вам быть в курсе важных событий на рынке и в вашем аккаунте.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Для получения уведомлений убедитесь, что они включены в настройках системы.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Уведомления")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView()
            .environmentObject(SettingsService())
    }
}

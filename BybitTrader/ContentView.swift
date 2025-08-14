import SwiftUI

struct ContentView: View {
    @StateObject private var bybitService = BybitService()
    @StateObject private var settingsService = SettingsService()
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var aiChatService = AIChatService.shared
    
    var body: some View {
        if bybitService.isAuthenticated {
            MainTabView()
                .environmentObject(bybitService)
                .environmentObject(settingsService)
                .environmentObject(supabaseService)
                .environmentObject(aiChatService)
        } else {
            AppleSignInView()
                .environmentObject(supabaseService)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            BalanceView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("Баланс")
                }
                .tag(0)
            
            TradingView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    Text("Торговля")
                }
                .tag(1)
            
            PositionsView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Позиции")
                }
                .tag(2)
            
            TradeDiaryView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Дневник")
                }
                .tag(3)
            
            ChartsTabView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Графики")
                }
                .tag(4)
            
            AIChatView()
                .tabItem {
                    Image(systemName: "brain.head.profile.fill")
                    Text("AI Чат")
                }
                .tag(5)
            
            LearningView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Обучение")
                }
                .tag(6)
            
            AnimatedCardsView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Анимации")
                }
                .tag(7)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Настройки")
                }
                .tag(8)
        }
        .accentColor(.blue)
    }
}

struct ChartsTabView: View {
    @EnvironmentObject var bybitService: BybitService
    @EnvironmentObject var settingsService: SettingsService
    @State private var chartData: [ChartData] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading && chartData.isEmpty {
                    ProgressView("Загрузка графиков...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if chartData.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Нет данных для графиков")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button("Загрузить данные") {
                            fetchChartData()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    PriceChartView(
                        symbol: settingsService.userSettings.selectedSymbol,
                        chartData: chartData
                    )
                }
            }
            .navigationTitle("Графики")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchChartData) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            if chartData.isEmpty {
                fetchChartData()
            }
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func fetchChartData() {
        isLoading = true
        
        Task {
            do {
                let data = try await bybitService.fetchChartData(
                    symbol: settingsService.userSettings.selectedSymbol,
                    interval: "1",
                    limit: 200
                )
                await MainActor.run {
                    self.chartData = data
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                    self.isLoading = false
                }
            }
        }
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var bybitService: BybitService
    @EnvironmentObject var settingsService: SettingsService
    @State private var apiKey = ""
    @State private var secretKey = ""
    @State private var isTestnet = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Градиентный фон
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Логотип и заголовок
                    VStack(spacing: 20) {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Bybit Trader")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Торговля криптовалютой на Bybit")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Форма входа
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Введите ваш API ключ", text: $apiKey)
                                .textFieldStyle(ModernTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Secret Key")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            SecureField("Введите ваш Secret ключ", text: $secretKey)
                                .textFieldStyle(ModernTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Toggle("Использовать Testnet", isOn: $isTestnet)
                            .font(.headline)
                            .toggleStyle(ModernToggleStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    // Кнопка входа
                    Button(action: authenticate) {
                        HStack {
                            if bybitService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            
                            Text("Войти")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(apiKey.isEmpty || secretKey.isEmpty || bybitService.isLoading)
                    .padding(.horizontal, 20)
                    
                    // Информация о безопасности
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("Ваши ключи хранятся локально на устройстве")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "iphone")
                                .foregroundColor(.blue)
                            Text("Приложение работает только с вашими API ключами")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.top, 50)
            }
            .navigationBarHidden(true)
        }
        .alert("Ошибка", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func authenticate() {
        guard !apiKey.isEmpty && !secretKey.isEmpty else { return }
        
        bybitService.isLoading = true
        
        // Сохраняем настройки
        settingsService.updateApiKeys(apiKey: apiKey, secretKey: secretKey, testnet: isTestnet)
        
        // Настраиваем сервис
        bybitService.configure(apiKey: apiKey, secretKey: secretKey, testnet: isTestnet)
        
        // Проверяем подключение
        Task {
            do {
                _ = try await bybitService.fetchBalance()
                DispatchQueue.main.async {
                    bybitService.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    bybitService.isLoading = false
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    bybitService.isAuthenticated = false
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var bybitService: BybitService
    @EnvironmentObject var settingsService: SettingsService
    @State private var showingLogoutAlert = false
    @State private var showingExportSheet = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("API Настройки") {
                    HStack {
                        Text("API Key")
                        Spacer()
                        Text(settingsService.userSettings.apiKey.prefix(8) + "...")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Secret Key")
                        Spacer()
                        Text(settingsService.userSettings.secretKey.prefix(8) + "...")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Среда")
                        Spacer()
                        Text(settingsService.userSettings.testnet ? "Testnet" : "Mainnet")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Торговля") {
                    HStack {
                        Text("Выбранная пара")
                        Spacer()
                        Text(settingsService.userSettings.selectedSymbol)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Автообновление", isOn: $settingsService.userSettings.autoRefresh)
                        .onChange(of: settingsService.userSettings.autoRefresh) { _ in
                            settingsService.toggleAutoRefresh()
                        }
                    
                    if settingsService.userSettings.autoRefresh {
                        HStack {
                            Text("Интервал обновления")
                            Spacer()
                            Picker("Интервал", selection: $settingsService.userSettings.refreshInterval) {
                                Text("15 сек").tag(15)
                                Text("30 сек").tag(30)
                                Text("1 мин").tag(60)
                                Text("5 мин").tag(300)
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: settingsService.userSettings.refreshInterval) { _ in
                                settingsService.updateRefreshInterval(settingsService.userSettings.refreshInterval)
                            }
                        }
                    }
                }
                
                Section("Внешний вид") {
                    Toggle("Темная тема", isOn: $settingsService.userSettings.darkModeEnabled)
                        .onChange(of: settingsService.userSettings.darkModeEnabled) { _ in
                            settingsService.toggleDarkMode()
                        }
                }
                
                Section("Уведомления") {
                    Toggle("Уведомления", isOn: $settingsService.userSettings.notificationsEnabled)
                        .onChange(of: settingsService.userSettings.notificationsEnabled) { _ in
                            settingsService.toggleNotifications()
                        }
                    
                    if settingsService.userSettings.notificationsEnabled {
                        NavigationLink("Настройки уведомлений") {
                            NotificationSettingsView()
                                .environmentObject(settingsService)
                        }
                    }
                }
                
                Section("Безопасность") {
                    Toggle("Биометрическая аутентификация", isOn: $settingsService.userSettings.biometricAuthEnabled)
                        .onChange(of: settingsService.userSettings.biometricAuthEnabled) { _ in
                            settingsService.toggleBiometricAuth()
                        }
                }
                
                Section("Данные") {
                    Button("Экспорт настроек") {
                        showingExportSheet = true
                    }
                    
                    Button("Сбросить настройки", role: .destructive) {
                        showingResetAlert = true
                    }
                }
                
                Section("О приложении") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastUpdate = bybitService.lastUpdateTime {
                        HStack {
                            Text("Последнее обновление")
                            Spacer()
                            Text(lastUpdate, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button("Выйти", role: .destructive) {
                        showingLogoutAlert = true
                    }
                }
            }
            .navigationTitle("Настройки")
        }
        .alert("Выйти из аккаунта?", isPresented: $showingLogoutAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Выйти", role: .destructive) {
                logout()
            }
        } message: {
            Text("Вы уверены, что хотите выйти? Все данные будут удалены.")
        }
        .alert("Сбросить настройки?", isPresented: $showingResetAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Сбросить", role: .destructive) {
                settingsService.resetToDefaults()
            }
        } message: {
            Text("Все настройки будут возвращены к значениям по умолчанию.")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSettingsView(settings: settingsService.exportSettings())
        }
    }
    
    private func logout() {
        settingsService.clearSensitiveData()
        bybitService.clearCache()
        bybitService.isAuthenticated = false
    }
}

// MARK: - Custom Styles
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.blue : Color(.systemGray4))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(.white)
                        .shadow(radius: 2)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}

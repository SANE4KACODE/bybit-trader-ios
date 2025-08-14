import SwiftUI

struct BalanceView: View {
    @EnvironmentObject var bybitService: BybitService
    @EnvironmentObject var settingsService: SettingsService
    @State private var balances: [Balance] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && balances.isEmpty {
                    ProgressView("Загрузка баланса...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if balances.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Нет данных о балансе")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button("Обновить") {
                            fetchBalance()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Общий баланс
                            TotalBalanceCard(balances: balances)
                            
                            // Время последнего обновления
                            if let lastUpdate = bybitService.lastUpdateTime {
                                LastUpdateCard(lastUpdate: lastUpdate)
                            }
                            
                            // Детали по монетам
                            ForEach(balances) { balance in
                                BalanceCard(balance: balance)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Баланс")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchBalance) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .refreshable {
                await fetchBalanceAsync()
            }
        }
        .onAppear {
            if balances.isEmpty {
                fetchBalance()
            }
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func fetchBalance() {
        isLoading = true
        
        Task {
            await fetchBalanceAsync()
        }
    }
    
    private func fetchBalanceAsync() async {
        do {
            let fetchedBalances = try await bybitService.fetchBalance()
            await MainActor.run {
                self.balances = fetchedBalances
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

struct TotalBalanceCard: View {
    let balances: [Balance]
    
    private var totalUSDT: Double {
        balances.compactMap { Double($0.walletBalance) }.reduce(0, +)
    }
    
    private var totalUnrealizedPnl: Double {
        balances.compactMap { Double($0.unrealizedPnl) }.reduce(0, +)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Общий баланс")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(totalUSDT, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("P&L")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(totalUnrealizedPnl, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(totalUnrealizedPnl >= 0 ? .green : .red)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Монет")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(balances.count)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Статус")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(totalUnrealizedPnl >= 0 ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(totalUnrealizedPnl >= 0 ? "Прибыль" : "Убыток")
                            .font(.caption)
                            .foregroundColor(totalUnrealizedPnl >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

struct LastUpdateCard: View {
    let lastUpdate: Date
    
    var body: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.blue)
            
            Text("Последнее обновление: \(lastUpdate, style: .relative)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct BalanceCard: View {
    let balance: Balance
    
    private var walletBalance: Double {
        Double(balance.walletBalance) ?? 0
    }
    
    private var availableBalance: Double {
        Double(balance.availableBalance) ?? 0
    }
    
    private var unrealizedPnl: Double {
        Double(balance.unrealizedPnl) ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(balance.coin)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Доступно: \(availableBalance, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(walletBalance, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("P&L: \(unrealizedPnl, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(unrealizedPnl >= 0 ? .green : .red)
                }
            }
            
            // Прогресс-бар для доступного баланса
            if walletBalance > 0 {
                ProgressView(value: availableBalance, total: walletBalance)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        )
    }
}

#Preview {
    BalanceView()
        .environmentObject(BybitService())
        .environmentObject(SettingsService())
}

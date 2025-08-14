import SwiftUI

struct PositionsView: View {
    @EnvironmentObject var bybitService: BybitService
    @EnvironmentObject var settingsService: SettingsService
    @State private var positions: [Position] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingCloseAlert = false
    @State private var selectedPosition: Position?
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && positions.isEmpty {
                    ProgressView("Загрузка позиций...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if positions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Нет открытых позиций")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Откройте позицию в разделе Торговля")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Обновить") {
                            fetchPositions()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Сводка по позициям
                            PositionsSummaryCard(positions: positions)
                            
                            // Время последнего обновления
                            if let lastUpdate = bybitService.lastUpdateTime {
                                LastUpdateCard(lastUpdate: lastUpdate)
                            }
                            
                            // Список позиций
                            ForEach(positions) { position in
                                PositionCard(
                                    position: position,
                                    onClose: {
                                        selectedPosition = position
                                        showingCloseAlert = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Позиции")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchPositions) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .refreshable {
                await fetchPositionsAsync()
            }
        }
        .onAppear {
            if positions.isEmpty {
                fetchPositions()
            }
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Закрыть позицию?", isPresented: $showingCloseAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Закрыть", role: .destructive) {
                if let position = selectedPosition {
                    closePosition(position)
                }
            }
        } message: {
            if let position = selectedPosition {
                Text("Вы уверены, что хотите закрыть позицию \(position.symbol) размером \(position.size)?")
            }
        }
    }
    
    private func fetchPositions() {
        isLoading = true
        
        Task {
            await fetchPositionsAsync()
        }
    }
    
    private func fetchPositionsAsync() async {
        do {
            let fetchedPositions = try await bybitService.fetchPositions()
            await MainActor.run {
                self.positions = fetchedPositions
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
    
    private func closePosition(_ position: Position) {
        Task {
            do {
                _ = try await bybitService.closePosition(
                    symbol: position.symbol,
                    side: position.side,
                    qty: position.size
                )
                
                await MainActor.run {
                    // Обновляем список позиций
                    fetchPositions()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
}

struct PositionsSummaryCard: View {
    let positions: [Position]
    
    private var totalPositions: Int {
        positions.count
    }
    
    private var totalUnrealizedPnl: Double {
        positions.compactMap { Double($0.unrealizedPnl) }.reduce(0, +)
    }
    
    private var totalPositionValue: Double {
        positions.compactMap { Double($0.positionValue) }.reduce(0, +)
    }
    
    private var isPositive: Bool {
        totalUnrealizedPnl >= 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Открытые позиции")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(totalPositions)")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Общий P&L")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(totalUnrealizedPnl, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(isPositive ? .green : .red)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Общая стоимость")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(totalPositionValue, specifier: "%.2f")")
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
                            .fill(isPositive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(isPositive ? "Прибыль" : "Убыток")
                            .font(.caption)
                            .foregroundColor(isPositive ? .green : .red)
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

struct PositionCard: View {
    let position: Position
    let onClose: () -> Void
    
    private var size: Double {
        Double(position.size) ?? 0
    }
    
    private var entryPrice: Double {
        Double(position.entryPrice) ?? 0
    }
    
    private var markPrice: Double {
        Double(position.markPrice) ?? 0
    }
    
    private var unrealizedPnl: Double {
        Double(position.unrealizedPnl) ?? 0
    }
    
    private var leverage: Double {
        Double(position.leverage) ?? 0
    }
    
    private var positionValue: Double {
        Double(position.positionValue) ?? 0
    }
    
    private var isLong: Bool {
        position.side == "Buy"
    }
    
    private var isPositive: Bool {
        unrealizedPnl >= 0
    }
    
    private var priceChange: Double {
        if isLong {
            return ((markPrice - entryPrice) / entryPrice) * 100
        } else {
            return ((entryPrice - markPrice) / entryPrice) * 100
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Заголовок позиции
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(position.symbol)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Text(isLong ? "LONG" : "SHORT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isLong ? Color.green : Color.red)
                            )
                        
                        Text("x\(leverage, specifier: "%.0f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(positionValue, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("P&L: \(unrealizedPnl, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(isPositive ? .green : .red)
                }
            }
            
            // Детали позиции
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Размер")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(size, specifier: "%.4f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Цена входа")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(entryPrice, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Текущая цена")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(markPrice, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            
            // Изменение цены
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Изменение цены")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                            .foregroundColor(isPositive ? .green : .red)
                        
                        Text("\(priceChange, specifier: "%.2f")%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isPositive ? .green : .red)
                    }
                }
                
                Spacer()
                
                // Кнопка закрытия
                Button(action: onClose) {
                    Text("Закрыть")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red)
                        )
                }
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
    PositionsView()
        .environmentObject(BybitService())
        .environmentObject(SettingsService())
}

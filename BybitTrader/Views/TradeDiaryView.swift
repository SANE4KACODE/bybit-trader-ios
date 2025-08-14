import SwiftUI

struct TradeDiaryView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @State private var trades: [Trade] = []
    @State private var isLoading = false
    @State private var showingAddTrade = false
    @State private var showingExportOptions = false
    @State private var selectedDateRange: DateRange = .week
    @State private var searchText = ""
    @State private var selectedTags: Set<String> = []
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Заголовок с статистикой
                TradeDiaryHeader(trades: filteredTrades)
                
                // Фильтры и поиск
                TradeDiaryFilters(
                    selectedDateRange: $selectedDateRange,
                    searchText: $searchText,
                    selectedTags: $selectedTags,
                    availableTags: availableTags
                )
                
                // Список сделок
                if isLoading {
                    ProgressView("Загрузка сделок...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredTrades.isEmpty {
                    EmptyTradesView()
                } else {
                    List(filteredTrades) { trade in
                        TradeDiaryCard(trade: trade) {
                            // Редактировать сделку
                            editTrade(trade)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Дневник сделок")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Экспорт") {
                        showingExportOptions = true
                    }
                    .disabled(trades.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTrade = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTrade) {
            AddTradeView { trade in
                addTrade(trade)
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(
                trades: filteredTrades,
                dateRange: selectedDateRange
            )
        }
        .onAppear {
            loadTrades()
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var filteredTrades: [Trade] {
        var filtered = trades
        
        // Фильтр по дате
        let startDate = selectedDateRange.startDate
        filtered = filtered.filter { $0.createdAt >= startDate }
        
        // Фильтр по поиску
        if !searchText.isEmpty {
            filtered = filtered.filter { trade in
                trade.symbol.localizedCaseInsensitiveContains(searchText) ||
                trade.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                trade.tags?.contains { $0.localizedCaseInsensitiveContains(searchText) } == true
            }
        }
        
        // Фильтр по тегам
        if !selectedTags.isEmpty {
            filtered = filtered.filter { trade in
                guard let tradeTags = trade.tags else { return false }
                return !selectedTags.isDisjoint(with: Set(tradeTags))
            }
        }
        
        return filtered
    }
    
    private var availableTags: [String] {
        let allTags = trades.compactMap { $0.tags }.flatMap { $0 }
        return Array(Set(allTags)).sorted()
    }
    
    private func loadTrades() {
        isLoading = true
        
        Task {
            do {
                let userId = "current_user_id" // Получить из аутентификации
                let fetchedTrades = try await supabaseService.getTrades(userId: userId, limit: 1000)
                
                await MainActor.run {
                    self.trades = fetchedTrades
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
    
    private func addTrade(_ trade: Trade) {
        Task {
            do {
                try await supabaseService.saveTrade(trade)
                await MainActor.run {
                    loadTrades()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    private func editTrade(_ trade: Trade) {
        // Показать форму редактирования
        print("Редактировать сделку: \(trade.id)")
    }
}

struct TradeDiaryHeader: View {
    let trades: [Trade]
    
    private var totalPnl: Decimal {
        trades.compactMap { $0.totalAmount }.reduce(0, +)
    }
    
    private var winRate: Double {
        let total = trades.count
        let winning = trades.filter { $0.totalAmount ?? 0 > 0 }.count
        return total > 0 ? Double(winning) / Double(total) * 100 : 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatCard(
                    title: "Всего сделок",
                    value: "\(trades.count)",
                    color: .blue
                )
                
                StatCard(
                    title: "P&L",
                    value: "\(totalPnl, specifier: "%.2f")",
                    color: totalPnl >= 0 ? .green : .red
                )
                
                StatCard(
                    title: "Винрейт",
                    value: "\(winRate, specifier: "%.1f")%",
                    color: winRate >= 50 ? .green : .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct TradeDiaryFilters: View {
    @Binding var selectedDateRange: DateRange
    @Binding var searchText: String
    @Binding var selectedTags: Set<String>
    let availableTags: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            // Поиск
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Поиск по символу, заметкам или тегам", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Фильтр по дате
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        FilterChip(
                            title: range.displayName,
                            isSelected: selectedDateRange == range
                        ) {
                            selectedDateRange = range
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Фильтр по тегам
            if !availableTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableTags, id: \.self) { tag in
                            TagChip(
                                tag: tag,
                                isSelected: selectedTags.contains(tag)
                            ) {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(tag)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TradeDiaryCard: View {
    let trade: Trade
    let onEdit: () -> Void
    
    private var side: OrderSide {
        OrderSide(rawValue: trade.side) ?? .buy
    }
    
    private var orderType: OrderType {
        OrderType(rawValue: trade.orderType) ?? .market
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Заголовок
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trade.symbol)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Text(side.displayName)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(side == .buy ? Color.green : Color.red)
                            .cornerRadius(6)
                        
                        Text(orderType.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(trade.totalAmount ?? 0, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor((trade.totalAmount ?? 0) >= 0 ? .green : .red)
                    
                    Text(trade.status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Детали сделки
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Количество")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(trade.quantity, specifier: "%.4f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Цена")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(trade.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Комиссия")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(trade.fee, specifier: "%.4f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            
            // Теги и заметки
            if let tags = trade.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            if let notes = trade.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Время и действия
            HStack {
                Text(trade.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Редактировать") {
                    onEdit()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

struct EmptyTradesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Нет сделок")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Добавьте свою первую сделку, чтобы начать вести дневник")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum DateRange: CaseIterable {
    case day, week, month, quarter, year, all
    
    var displayName: String {
        switch self {
        case .day: return "День"
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .quarter: return "Квартал"
        case .year: return "Год"
        case .all: return "Все"
        }
    }
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .quarter:
            let quarter = (calendar.component(.month, from: now) - 1) / 3
            let startMonth = quarter * 3 + 1
            return calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: startMonth)) ?? now
        case .year:
            return calendar.dateInterval(of: .year, for: now)?.start ?? now
        case .all:
            return Date.distantPast
        }
    }
}

#Preview {
    TradeDiaryView()
        .environmentObject(SupabaseService.shared)
}

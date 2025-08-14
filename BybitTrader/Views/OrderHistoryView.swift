import SwiftUI

struct OrderHistoryView: View {
    @EnvironmentObject var bybitService: BybitService
    @EnvironmentObject var userSettings: UserSettings
    @State private var orders: [OrderHistory] = []
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedFilter: OrderStatus? = nil
    @State private var searchText = ""
    @State private var showingCancelAlert = false
    @State private var selectedOrder: OrderHistory?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Фильтры
                FilterBar(
                    selectedFilter: $selectedFilter,
                    searchText: $searchText
                )
                
                // Список ордеров
                ZStack {
                    if isLoading && orders.isEmpty {
                        ProgressView("Загрузка истории ордеров...")
                            .progressViewStyle(CircularProgressViewStyle())
                    } else if filteredOrders.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("Нет ордеров")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            if !searchText.isEmpty || selectedFilter != nil {
                                Text("Попробуйте изменить фильтры")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Ваши ордера появятся здесь")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Обновить") {
                                fetchOrderHistory()
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        List(filteredOrders) { order in
                            OrderHistoryCard(
                                order: order,
                                onCancel: {
                                    selectedOrder = order
                                    showingCancelAlert = true
                                }
                            )
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("История ордеров")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchOrderHistory) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .refreshable {
                await fetchOrderHistoryAsync()
            }
        }
        .onAppear {
            if orders.isEmpty {
                fetchOrderHistory()
            }
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Отменить ордер?", isPresented: $showingCancelAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Отменить", role: .destructive) {
                if let order = selectedOrder {
                    cancelOrder(order)
                }
            }
        } message: {
            if let order = selectedOrder {
                Text("Вы уверены, что хотите отменить ордер \(order.symbol) размером \(order.qty)?")
            }
        }
    }
    
    private var filteredOrders: [OrderHistory] {
        var filtered = orders
        
        // Фильтр по статусу
        if let filter = selectedFilter {
            filtered = filtered.filter { $0.status == filter.rawValue }
        }
        
        // Поиск по тексту
        if !searchText.isEmpty {
            filtered = filtered.filter { order in
                order.symbol.localizedCaseInsensitiveContains(searchText) ||
                order.orderId.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    private func fetchOrderHistory() {
        isLoading = true
        
        Task {
            await fetchOrderHistoryAsync()
        }
    }
    
    private func fetchOrderHistoryAsync() async {
        do {
            let fetchedOrders = try await bybitService.fetchOrderHistory(
                symbol: userSettings.selectedSymbol,
                limit: 100
            )
            await MainActor.run {
                self.orders = fetchedOrders
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
    
    private func cancelOrder(_ order: OrderHistory) {
        Task {
            do {
                _ = try await bybitService.cancelOrder(
                    symbol: order.symbol,
                    orderId: order.orderId
                )
                
                await MainActor.run {
                    // Обновляем список ордеров
                    fetchOrderHistory()
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

struct FilterBar: View {
    @Binding var selectedFilter: OrderStatus?
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Поиск
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Поиск по символу или ID", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Фильтры по статусу
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "Все",
                        isSelected: selectedFilter == nil,
                        action: { selectedFilter = nil }
                    )
                    
                    ForEach(OrderStatus.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.displayName,
                            isSelected: selectedFilter == status,
                            action: { selectedFilter = status }
                        )
                    }
                }
                .padding(.horizontal)
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
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(16)
        }
    }
}

struct OrderHistoryCard: View {
    let order: OrderHistory
    let onCancel: () -> Void
    
    private var status: OrderStatus {
        OrderStatus(rawValue: order.status) ?? .pending
    }
    
    private var side: OrderSide {
        OrderSide(rawValue: order.side) ?? .buy
    }
    
    private var orderType: OrderType {
        OrderType(rawValue: order.orderType) ?? .market
    }
    
    private var qty: Double {
        Double(order.qty) ?? 0
    }
    
    private var price: Double {
        Double(order.price) ?? 0
    }
    
    private var executedQty: Double {
        Double(order.executedQty) ?? 0
    }
    
    private var avgPrice: Double {
        Double(order.avgPrice) ?? 0
    }
    
    private var createTime: Date {
        let timestamp = Double(order.createTime) ?? 0
        return Date(timeIntervalSince1970: timestamp / 1000)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Заголовок
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.symbol)
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
                    Text(status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(status.color))
                        .cornerRadius(6)
                    
                    Text(order.orderId.prefix(8) + "...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Детали ордера
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Количество")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(qty, specifier: "%.4f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Цена")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(price, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Исполнено")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(executedQty, specifier: "%.4f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            
            // Время создания и кнопка отмены
            HStack {
                Text("Создан: \(createTime, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if status == .pending {
                    Button(action: onCancel) {
                        Text("Отменить")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

#Preview {
    OrderHistoryView()
        .environmentObject(BybitService())
        .environmentObject(UserSettings())
}

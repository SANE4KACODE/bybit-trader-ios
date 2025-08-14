import SwiftUI

struct TradingView: View {
    @EnvironmentObject var bybitService: BybitService
    @EnvironmentObject var settingsService: SettingsService
    @State private var tickerData: TickerData?
    @State private var isLoading = false
    @State private var showingOrderSheet = false
    @State private var selectedOrderSide: OrderSide = .buy
    @State private var selectedOrderType: OrderType = .market
    @State private var selectedTimeInForce: TimeInForce = .gtc
    @State private var quantity = ""
    @State private var price = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Рыночные данные
                    if let ticker = tickerData {
                        MarketDataCard(ticker: ticker)
                    }
                    
                    // Форма торговли
                    TradingFormCard(
                        selectedOrderSide: $selectedOrderSide,
                        selectedOrderType: $selectedOrderType,
                        selectedTimeInForce: $selectedTimeInForce,
                        quantity: $quantity,
                        price: $price,
                        onTrade: placeOrder
                    )
                    
                    // Информация о рисках
                    RiskWarningCard()
                }
                .padding()
            }
            .navigationTitle("Торговля")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Новый ордер") {
                        showingOrderSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingOrderSheet) {
                OrderSheetView(
                    selectedOrderSide: $selectedOrderSide,
                    selectedOrderType: $selectedOrderType,
                    selectedTimeInForce: $selectedTimeInForce,
                    quantity: $quantity,
                    price: $price,
                    onPlaceOrder: placeOrder
                )
            }
            .onAppear {
                fetchTickerData()
            }
            .alert(isSuccess ? "Успех" : "Ошибка", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func fetchTickerData() {
        Task {
            do {
                let ticker = try await bybitService.fetchTicker(symbol: settingsService.userSettings.selectedSymbol)
                await MainActor.run {
                    self.tickerData = ticker
                }
            } catch {
                print("Ошибка загрузки тикера: \(error)")
            }
        }
    }
    
    private func placeOrder() {
        guard !quantity.isEmpty else {
            alertMessage = "Введите количество"
            showingAlert = true
            return
        }
        
        if selectedOrderType == .limit && price.isEmpty {
            alertMessage = "Введите цену для лимитного ордера"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let result = try await bybitService.placeOrder(
                    symbol: settingsService.userSettings.selectedSymbol,
                    side: selectedOrderSide.rawValue,
                    orderType: selectedOrderType.rawValue,
                    qty: quantity,
                    price: selectedOrderType == .limit ? price : nil,
                    timeInForce: selectedTimeInForce.rawValue
                )
                
                await MainActor.run {
                    isLoading = false
                    isSuccess = true
                    alertMessage = "Ордер размещен успешно! ID: \(result.orderId)"
                    showingAlert = true
                    
                    // Сброс формы
                    quantity = ""
                    price = ""
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    isSuccess = false
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct MarketDataCard: View {
    let ticker: TickerData
    
    private var lastPrice: Double {
        Double(ticker.lastPrice) ?? 0
    }
    
    private var priceChange: Double {
        Double(ticker.price24hPcnt) ?? 0
    }
    
    private var isPositive: Bool {
        priceChange >= 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticker.symbol)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Последняя цена")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(lastPrice, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 4) {
                        Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                            .foregroundColor(isPositive ? .green : .red)
                        
                        Text("\(priceChange * 100, specifier: "%.2f")%")
                            .font(.caption)
                            .foregroundColor(isPositive ? .green : .red)
                    }
                }
            }
            
            // Дополнительная информация
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("24h High")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(Double(ticker.highPrice24h) ?? 0, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("24h Low")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(Double(ticker.lowPrice24h) ?? 0, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Объем 24h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Double(ticker.volume24h) ?? 0, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
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

struct TradingFormCard: View {
    @Binding var selectedOrderSide: OrderSide
    @Binding var selectedOrderType: OrderType
    @Binding var selectedTimeInForce: TimeInForce
    @Binding var quantity: String
    @Binding var price: String
    let onTrade: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Быстрая торговля")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Сторона ордера
            VStack(alignment: .leading, spacing: 8) {
                Text("Сторона")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(OrderSide.allCases, id: \.self) { side in
                        Button(action: {
                            selectedOrderSide = side
                        }) {
                            Text(side.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedOrderSide == side ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedOrderSide == side ? 
                                              (side == .buy ? Color.green : Color.red) : 
                                              Color(.systemGray5))
                                )
                        }
                    }
                }
            }
            
            // Тип ордера
            VStack(alignment: .leading, spacing: 8) {
                Text("Тип ордера")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Тип ордера", selection: $selectedOrderType) {
                    ForEach(OrderType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Количество
            VStack(alignment: .leading, spacing: 8) {
                Text("Количество")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $quantity)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
            
            // Цена (только для лимитных ордеров)
            if selectedOrderType == .limit {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Цена")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", text: $price)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
            }
            
            // Время действия (только для лимитных ордеров)
            if selectedOrderType == .limit {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Время действия")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Время действия", selection: $selectedTimeInForce) {
                        ForEach(TimeInForce.allCases, id: \.self) { tif in
                            Text(tif.displayName).tag(tif)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            // Кнопка торговли
            Button(action: onTrade) {
                HStack {
                    Image(systemName: selectedOrderSide == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    Text("\(selectedOrderSide == .buy ? "Купить" : "Продать") \(settingsService.userSettings.selectedSymbol)")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(selectedOrderSide == .buy ? Color.green : Color.red)
                )
            }
            .disabled(quantity.isEmpty || (selectedOrderType == .limit && price.isEmpty))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

struct OrderSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsService: SettingsService
    @Binding var selectedOrderSide: OrderSide
    @Binding var selectedOrderType: OrderType
    @Binding var selectedTimeInForce: TimeInForce
    @Binding var quantity: String
    @Binding var price: String
    let onPlaceOrder: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TradingFormCard(
                    selectedOrderSide: $selectedOrderSide,
                    selectedOrderType: $selectedOrderType,
                    selectedTimeInForce: $selectedTimeInForce,
                    quantity: $quantity,
                    price: $price,
                    onTrade: {
                        onPlaceOrder()
                        dismiss()
                    }
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Новый ордер")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RiskWarningCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Предупреждение о рисках")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            Text("Торговля криптовалютами связана с высокими рисками. Цены могут резко изменяться, что может привести к потере ваших инвестиций. Торгуйте только теми средствами, потерю которых вы можете себе позволить.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    TradingView()
        .environmentObject(BybitService())
        .environmentObject(SettingsService())
}

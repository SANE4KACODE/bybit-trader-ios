import SwiftUI

struct AddTradeView: View {
    let onSave: (Trade) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var symbol = ""
    @State private var selectedSide: OrderSide = .buy
    @State private var selectedOrderType: OrderType = .market
    @State private var quantity = ""
    @State private var price = ""
    @State private var fee = ""
    @State private var notes = ""
    @State private var tags = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Основная информация
                Section("Основная информация") {
                    HStack {
                        Text("Символ")
                        Spacer()
                        TextField("BTCUSDT", text: $symbol)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Сторона")
                        Spacer()
                        Picker("Сторона", selection: $selectedSide) {
                            ForEach(OrderSide.allCases, id: \.self) { side in
                                Text(side.displayName).tag(side)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Тип ордера")
                        Spacer()
                        Picker("Тип", selection: $selectedOrderType) {
                            ForEach(OrderType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                }
                
                // Детали сделки
                Section("Детали сделки") {
                    HStack {
                        Text("Количество")
                        Spacer()
                        TextField("0.001", text: $quantity)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    if selectedOrderType != .market {
                        HStack {
                            Text("Цена")
                            Spacer()
                            TextField("50000", text: $price)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                    HStack {
                        Text("Комиссия")
                        Spacer()
                        TextField("0.1", text: $fee)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
                
                // Дополнительная информация
                Section("Дополнительно") {
                    HStack {
                        Text("Заметки")
                        Spacer()
                        TextField("Описание сделки", text: $notes)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Теги")
                        Spacer()
                        TextField("scalping, btc", text: $tags)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Предварительный просмотр
                Section("Предварительный просмотр") {
                    TradePreviewCard(
                        symbol: symbol,
                        side: selectedSide,
                        orderType: selectedOrderType,
                        quantity: quantity,
                        price: price,
                        fee: fee,
                        notes: notes,
                        tags: tags
                    )
                }
            }
            .navigationTitle("Новая сделка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveTrade()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .alert("Ошибка", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        !symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(quantity) != nil &&
        (selectedOrderType == .market || !price.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    private func saveTrade() {
        guard isFormValid else { return }
        
        do {
            let trade = try createTrade()
            onSave(trade)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func createTrade() throws -> Trade {
        guard let quantityValue = Double(quantity) else {
            throw TradeError.invalidQuantity
        }
        
        let priceValue: Double
        if selectedOrderType == .market {
            priceValue = 0 // Для рыночных ордеров цена не нужна
        } else {
            guard let priceDouble = Double(price) else {
                throw TradeError.invalidPrice
            }
            priceValue = priceDouble
        }
        
        let feeValue = Double(fee) ?? 0
        
        let tagsArray = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return Trade(
            id: UUID().uuidString,
            userId: "current_user_id", // Получить из аутентификации
            symbol: symbol.uppercased(),
            side: selectedSide.rawValue.lowercased(),
            orderType: selectedOrderType.rawValue.lowercased(),
            quantity: Decimal(quantityValue),
            price: Decimal(priceValue),
            executedPrice: nil,
            totalAmount: nil,
            fee: Decimal(feeValue),
            status: "pending",
            orderId: nil,
            bybitOrderId: nil,
            notes: notes.isEmpty ? nil : notes,
            tags: tagsArray.isEmpty ? nil : tagsArray,
            createdAt: Date(),
            executedAt: nil,
            updatedAt: Date()
        )
    }
}

struct TradePreviewCard: View {
    let symbol: String
    let side: OrderSide
    let orderType: OrderType
    let quantity: String
    let price: String
    let fee: String
    let notes: String
    let tags: String
    
    private var calculatedAmount: Double {
        guard let qty = Double(quantity),
              let prc = Double(price) else { return 0 }
        return qty * prc
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Заголовок
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(symbol.isEmpty ? "SYMBOL" : symbol)
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
                    if !price.isEmpty && !quantity.isEmpty {
                        Text("$\(calculatedAmount, specifier: "%.2f")")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Предварительный просмотр")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Детали
            if !quantity.isEmpty || !price.isEmpty || !fee.isEmpty {
                HStack(spacing: 20) {
                    if !quantity.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Количество")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(quantity)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if !price.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Цена")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("$\(price)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if !fee.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Комиссия")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("$\(fee)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Заметки и теги
            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Заметки")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if !tags.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Теги")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(tags.split(separator: ","), id: \.self) { tag in
                                Text(tag.trimmingCharacters(in: .whitespacesAndNewlines))
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
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

enum TradeError: Error, LocalizedError {
    case invalidQuantity
    case invalidPrice
    case invalidSymbol
    
    var errorDescription: String? {
        switch self {
        case .invalidQuantity:
            return "Неверное количество"
        case .invalidPrice:
            return "Неверная цена"
        case .invalidSymbol:
            return "Неверный символ"
        }
    }
}

#Preview {
    AddTradeView { trade in
        print("Сохранена сделка: \(trade.symbol)")
    }
}

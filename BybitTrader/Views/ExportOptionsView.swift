import SwiftUI
import UniformTypeIdentifiers

struct ExportOptionsView: View {
    let trades: [Trade]
    let dateRange: DateRange
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedDateRange: ExportDateRange = .custom
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Заголовок
                VStack(spacing: 8) {
                    Text("Экспорт сделок")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Выберите формат и период для экспорта")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Формат экспорта
                VStack(alignment: .leading, spacing: 12) {
                    Text("Формат файла")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            FormatOptionCard(
                                format: format,
                                isSelected: selectedFormat == format
                            ) {
                                selectedFormat = format
                            }
                        }
                    }
                }
                
                // Период экспорта
                VStack(alignment: .leading, spacing: 12) {
                    Text("Период экспорта")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(ExportDateRange.allCases, id: \.self) { range in
                            DateRangeOptionCard(
                                range: range,
                                isSelected: selectedDateRange == range
                            ) {
                                selectedDateRange = range
                            }
                        }
                    }
                    
                    // Кастомные даты
                    if selectedDateRange == .custom {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("С")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                DatePicker("", selection: $customStartDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("По")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                DatePicker("", selection: $customEndDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                
                // Статистика
                ExportStatsView(trades: filteredTrades)
                
                Spacer()
                
                // Кнопка экспорта
                Button(action: exportTrades) {
                    HStack(spacing: 8) {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Text(isExporting ? "Экспорт..." : "Экспортировать")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(selectedFormat.color)
                    )
                }
                .disabled(isExporting || filteredTrades.isEmpty)
            }
            .padding()
            .navigationTitle("Экспорт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .onAppear {
            setupCustomDates()
        }
    }
    
    private var filteredTrades: [Trade] {
        let startDate: Date
        let endDate: Date
        
        switch selectedDateRange {
        case .all:
            return trades
        case .today:
            startDate = Calendar.current.startOfDay(for: Date())
            endDate = Date()
        case .week:
            startDate = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            endDate = Date()
        case .month:
            startDate = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
            endDate = Date()
        case .custom:
            startDate = customStartDate
            endDate = customEndDate
        }
        
        return trades.filter { trade in
            trade.createdAt >= startDate && trade.createdAt <= endDate
        }
    }
    
    private func setupCustomDates() {
        customStartDate = dateRange.startDate
        customEndDate = Date()
    }
    
    private func exportTrades() {
        isExporting = true
        
        Task {
            do {
                let content = generateExportContent()
                let fileName = "trades_\(Date().timeIntervalSince1970)"
                let fileExtension = selectedFormat.fileExtension
                
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsPath.appendingPathComponent("\(fileName).\(fileExtension)")
                
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                
                await MainActor.run {
                    exportedFileURL = fileURL
                    isExporting = false
                    showingShareSheet = true
                }
                
            } catch {
                await MainActor.run {
                    isExporting = false
                    // Показать ошибку
                }
            }
        }
    }
    
    private func generateExportContent() -> String {
        switch selectedFormat {
        case .csv:
            return generateCSV()
        case .excel:
            return generateExcel()
        case .json:
            return generateJSON()
        }
    }
    
    private func generateCSV() -> String {
        let headers = "Дата,Время,Символ,Сторона,Тип,Количество,Цена,Сумма,Комиссия,Статус,Заметки,Теги\n"
        
        let rows = filteredTrades.map { trade in
            let date = formatDate(trade.createdAt)
            let time = formatTime(trade.createdAt)
            let side = trade.side == "buy" ? "Покупка" : "Продажа"
            let type = trade.orderType == "market" ? "Рыночный" : "Лимитный"
            let amount = trade.quantity * trade.price
            let notes = trade.notes ?? ""
            let tags = trade.tags?.joined(separator: "; ") ?? ""
            
            return "\(date),\(time),\(trade.symbol),\(side),\(type),\(trade.quantity),\(trade.price),\(amount),\(trade.fee),\(trade.status),\(notes),\(tags)"
        }.joined(separator: "\n")
        
        return headers + rows
    }
    
    private func generateExcel() -> String {
        // Простой HTML формат, который Excel может открыть
        let headers = ["Дата", "Время", "Символ", "Сторона", "Тип", "Количество", "Цена", "Сумма", "Комиссия", "Статус", "Заметки", "Теги"]
        
        let headerRow = headers.map { "<th>\($0)</th>" }.joined()
        let headerHTML = "<tr>\(headerRow)</tr>"
        
        let dataRows = filteredTrades.map { trade in
            let date = formatDate(trade.createdAt)
            let time = formatTime(trade.createdAt)
            let side = trade.side == "buy" ? "Покупка" : "Продажа"
            let type = trade.orderType == "market" ? "Рыночный" : "Лимитный"
            let amount = trade.quantity * trade.price
            let notes = trade.notes ?? ""
            let tags = trade.tags?.joined(separator: "; ") ?? ""
            
            let cells = [date, time, trade.symbol, side, type, "\(trade.quantity)", "\(trade.price)", "\(amount)", "\(trade.fee)", trade.status, notes, tags]
            let rowHTML = cells.map { "<td>\($0)</td>" }.joined()
            
            return "<tr>\(rowHTML)</tr>"
        }.joined()
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Торговые сделки</title>
        </head>
        <body>
            <table border="1">
                \(headerHTML)
                \(dataRows)
            </table>
        </body>
        </html>
        """
    }
    
    private func generateJSON() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(filteredTrades)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "{}"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Enums
enum ExportFormat: CaseIterable {
    case csv, excel, json
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .excel: return "Excel"
        case .json: return "JSON"
        }
    }
    
    var description: String {
        switch self {
        case .csv: return "Универсальный формат"
        case .excel: return "Для Microsoft Excel"
        case .json: return "Для разработчиков"
        }
    }
    
    var icon: String {
        switch self {
        case .csv: return "doc.text"
        case .excel: return "tablecells"
        case .json: return "curlybraces"
        }
    }
    
    var color: Color {
        switch self {
        case .csv: return .green
        case .excel: return .blue
        case .json: return .orange
        }
    }
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .excel: return "html"
        case .json: return "json"
        }
    }
}

enum ExportDateRange: CaseIterable {
    case all, today, week, month, custom
    
    var displayName: String {
        switch self {
        case .all: return "Все"
        case .today: return "Сегодня"
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .custom: return "Кастомный"
        }
    }
    
    var description: String {
        switch self {
        case .all: return "Все сделки"
        case .today: return "За сегодня"
        case .week: return "За неделю"
        case .month: return "За месяц"
        case .custom: return "Выбрать даты"
        }
    }
}

// MARK: - Supporting Views
struct FormatOptionCard: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: format.icon)
                    .font(.title2)
                    .foregroundColor(format.color)
                
                Text(format.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(format.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? format.color.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? format.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DateRangeOptionCard: View {
    let range: ExportDateRange
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(range.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(range.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExportStatsView: View {
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Статистика экспорта")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                StatItem(title: "Сделок", value: "\(trades.count)", color: .blue)
                StatItem(title: "P&L", value: "\(totalPnl, specifier: "%.2f")", color: totalPnl >= 0 ? .green : .red)
                StatItem(title: "Винрейт", value: "\(winRate, specifier: "%.1f")%", color: winRate >= 50 ? .green : .orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
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
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportOptionsView(
        trades: [],
        dateRange: .week
    )
}

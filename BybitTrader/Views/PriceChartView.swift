import SwiftUI
import Charts

struct PriceChartView: View {
    let symbol: String
    let chartData: [ChartData]
    @State private var selectedTimeframe: Timeframe = .h1
    @State private var animateChart = false
    @State private var showVolume = true
    
    var body: some View {
        VStack(spacing: 16) {
            // Заголовок и настройки
            HStack {
                Text(symbol)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Переключатель временных интервалов
                Picker("Временной интервал", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.displayName).tag(timeframe)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // График цен
            Chart {
                ForEach(filteredChartData) { data in
                    LineMark(
                        x: .value("Время", data.timestamp),
                        y: .value("Цена", Double(data.close) ?? 0)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    
                    if showVolume {
                        BarMark(
                            x: .value("Время", data.timestamp),
                            y: .value("Объем", Double(data.volume) ?? 0)
                        )
                        .foregroundStyle(.blue.opacity(0.3))
                        .position(by: .value("Объем", Double(data.volume) ?? 0))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let timestamp = value.as(Int.self) {
                            Text(formatTimestamp(timestamp))
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let price = value.as(Double.self) {
                            Text("$\(price, specifier: "%.2f")")
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(height: 300)
            .scaleEffect(animateChart ? 1.0 : 0.8)
            .opacity(animateChart ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 1.0), value: animateChart)
            
            // Статистика
            HStack(spacing: 20) {
                StatCard(
                    title: "24h High",
                    value: "$\(highPrice, specifier: "%.2f")",
                    color: .green
                )
                
                StatCard(
                    title: "24h Low",
                    value: "$\(lowPrice, specifier: "%.2f")",
                    color: .red
                )
                
                StatCard(
                    title: "Изменение",
                    value: "\(priceChange, specifier: "%.2f")%",
                    color: priceChange >= 0 ? .green : .red
                )
            }
            
            // Переключатели
            HStack {
                Toggle("Показать объем", isOn: $showVolume)
                    .toggleStyle(ModernToggleStyle())
                
                Spacer()
                
                Button("Обновить") {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animateChart = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            animateChart = true
                        }
                    }
                }
                .buttonStyle(ModernButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            animateChart = true
        }
    }
    
    private var filteredChartData: [ChartData] {
        let limit = selectedTimeframe.dataPoints
        return Array(chartData.suffix(limit))
    }
    
    private var highPrice: Double {
        filteredChartData.compactMap { Double($0.high) }.max() ?? 0
    }
    
    private var lowPrice: Double {
        filteredChartData.compactMap { Double($0.low) }.min() ?? 0
    }
    
    private var priceChange: Double {
        guard let first = filteredChartData.first,
              let last = filteredChartData.last,
              let firstPrice = Double(first.close),
              let lastPrice = Double(last.close),
              firstPrice > 0 else { return 0 }
        
        return ((lastPrice - firstPrice) / firstPrice) * 100
    }
    
    private func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        
        switch selectedTimeframe {
        case .m15, .h1:
            formatter.dateFormat = "HH:mm"
        case .h4, .d1:
            formatter.dateFormat = "MM/dd"
        case .w1:
            formatter.dateFormat = "MM/dd"
        }
        
        return formatter.string(from: date)
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

enum Timeframe: String, CaseIterable {
    case m15 = "15m"
    case h1 = "1h"
    case h4 = "4h"
    case d1 = "1d"
    case w1 = "1w"
    
    var displayName: String {
        switch self {
        case .m15: return "15м"
        case .h1: return "1ч"
        case .h4: return "4ч"
        case .d1: return "1д"
        case .w1: return "1н"
        }
    }
    
    var dataPoints: Int {
        switch self {
        case .m15: return 96
        case .h1: return 168
        case .h4: return 168
        case .d1: return 365
        case .w1: return 52
        }
    }
}

struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    PriceChartView(
        symbol: "BTCUSDT",
        chartData: [
            ChartData(timestamp: 1640995200000, open: "50000", high: "51000", low: "49000", close: "50500", volume: "1000"),
            ChartData(timestamp: 1640998800000, open: "50500", high: "52000", low: "50000", close: "51500", volume: "1200"),
            ChartData(timestamp: 1641002400000, open: "51500", high: "53000", low: "51000", close: "52500", volume: "1100")
        ]
    )
    .padding()
}

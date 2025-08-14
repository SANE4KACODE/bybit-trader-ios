import Foundation
import Combine
import Charts

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    // MARK: - Published Properties
    @Published var tradingStats: TradingStatistics = TradingStatistics()
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var riskMetrics: RiskMetrics = RiskMetrics()
    @Published var portfolioAllocation: [PortfolioAllocation] = []
    @Published var monthlyReturns: [MonthlyReturn] = []
    @Published var drawdownAnalysis: DrawdownAnalysis = DrawdownAnalysis()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let supabaseService = SupabaseService.shared
    private let localDatabaseService = LocalDatabaseService.shared
    private let loggingService = LoggingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAnalytics()
    }
    
    // MARK: - Setup
    private func setupAnalytics() {
        // Start periodic analytics updates
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateAnalytics()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func updateAnalytics() {
        Task {
            await calculateTradingStatistics()
            await calculatePerformanceMetrics()
            await calculateRiskMetrics()
            await calculatePortfolioAllocation()
            await calculateMonthlyReturns()
            await calculateDrawdownAnalysis()
        }
    }
    
    func generateTradingReport(dateRange: DateRange, format: ExportFormat) async -> TradingReport? {
        isLoading = true
        
        do {
            let trades = try await supabaseService.getTrades()
            let filteredTrades = filterTradesByDateRange(trades, dateRange: dateRange)
            
            let report = TradingReport(
                id: UUID(),
                userId: "current_user", // Get from auth
                dateRange: dateRange.displayName,
                startDate: dateRange.getDateRange().0,
                endDate: dateRange.getDateRange().1,
                totalTrades: filteredTrades.count,
                profitableTrades: filteredTrades.filter { $0.realizedPnl > 0 }.count,
                totalVolume: filteredTrades.reduce(0) { $0 + $1.quantity },
                totalPnl: filteredTrades.reduce(0) { $0 + $1.realizedPnl },
                totalFees: filteredTrades.reduce(0) { $0 + $1.fee },
                winRate: calculateWinRate(trades: filteredTrades),
                averageTradeSize: calculateAverageTradeSize(trades: filteredTrades),
                largestWin: filteredTrades.max(by: { $0.realizedPnl < $1.realizedPnl })?.realizedPnl ?? 0,
                largestLoss: filteredTrades.min(by: { $0.realizedPnl < $1.realizedPnl })?.realizedPnl ?? 0,
                sharpeRatio: calculateSharpeRatio(trades: filteredTrades),
                maxDrawdown: calculateMaxDrawdown(trades: filteredTrades),
                profitFactor: calculateProfitFactor(trades: filteredTrades),
                averageHoldingTime: calculateAverageHoldingTime(trades: filteredTrades),
                topPerformingSymbols: getTopPerformingSymbols(trades: filteredTrades),
                worstPerformingSymbols: getWorstPerformingSymbols(trades: filteredTrades),
                tradingHours: analyzeTradingHours(trades: filteredTrades),
                marketConditions: analyzeMarketConditions(trades: filteredTrades),
                recommendations: generateRecommendations(trades: filteredTrades),
                createdAt: Date()
            )
            
            await MainActor.run {
                self.isLoading = false
            }
            
            loggingService.info("Trading report generated", category: "analytics", metadata: [
                "dateRange": dateRange.displayName,
                "totalTrades": report.totalTrades,
                "totalPnl": report.totalPnl
            ])
            
            return report
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Не удалось сгенерировать отчет"
                self.loggingService.error("Failed to generate trading report", category: "analytics", error: error)
            }
            return nil
        }
    }
    
    func exportReport(_ report: TradingReport, format: ExportFormat) -> String {
        switch format {
        case .csv:
            return exportReportToCSV(report)
        case .excel:
            return exportReportToExcel(report)
        case .json:
            return exportReportToJSON(report)
        }
    }
    
    // MARK: - Private Analytics Methods
    private func calculateTradingStatistics() async {
        do {
            let trades = try await supabaseService.getTrades()
            
            await MainActor.run {
                self.tradingStats = TradingStatistics(
                    totalTrades: trades.count,
                    buyTrades: trades.filter { $0.side == "Buy" }.count,
                    sellTrades: trades.filter { $0.side == "Sell" }.count,
                    totalVolume: trades.reduce(0) { $0 + $1.quantity },
                    totalValue: trades.reduce(0) { $0 + ($1.quantity * $1.price) },
                    totalFees: trades.reduce(0) { $0 + $1.fee },
                    profitableTrades: trades.filter { $0.realizedPnl > 0 }.count,
                    winRate: calculateWinRate(trades: trades),
                    averageTradeSize: calculateAverageTradeSize(trades: trades),
                    totalPnl: trades.reduce(0) { $0 + $1.realizedPnl }
                )
            }
        } catch {
            loggingService.error("Failed to calculate trading statistics", category: "analytics", error: error)
        }
    }
    
    private func calculatePerformanceMetrics() async {
        do {
            let trades = try await supabaseService.getTrades()
            
            await MainActor.run {
                self.performanceMetrics = PerformanceMetrics(
                    totalReturn: calculateTotalReturn(trades: trades),
                    annualizedReturn: calculateAnnualizedReturn(trades: trades),
                    sharpeRatio: calculateSharpeRatio(trades: trades),
                    sortinoRatio: calculateSortinoRatio(trades: trades),
                    calmarRatio: calculateCalmarRatio(trades: trades),
                    profitFactor: calculateProfitFactor(trades: trades),
                    averageWin: calculateAverageWin(trades: trades),
                    averageLoss: calculateAverageLoss(trades: trades),
                    largestWin: trades.max(by: { $0.realizedPnl < $1.realizedPnl })?.realizedPnl ?? 0,
                    largestLoss: trades.min(by: { $0.realizedPnl < $1.realizedPnl })?.realizedPnl ?? 0,
                    consecutiveWins: calculateConsecutiveWins(trades: trades),
                    consecutiveLosses: calculateConsecutiveLosses(trades: trades)
                )
            }
        } catch {
            loggingService.error("Failed to calculate performance metrics", category: "analytics", error: error)
        }
    }
    
    private func calculateRiskMetrics() async {
        do {
            let trades = try await supabaseService.getTrades()
            
            await MainActor.run {
                self.riskMetrics = RiskMetrics(
                    maxDrawdown: calculateMaxDrawdown(trades: trades),
                    valueAtRisk: calculateValueAtRisk(trades: trades),
                    volatility: calculateVolatility(trades: trades),
                    downsideDeviation: calculateDownsideDeviation(trades: trades),
                    beta: calculateBeta(trades: trades),
                    correlation: calculateCorrelation(trades: trades),
                    kurtosis: calculateKurtosis(trades: trades),
                    skewness: calculateSkewness(trades: trades)
                )
            }
        } catch {
            loggingService.error("Failed to calculate risk metrics", category: "analytics", error: error)
        }
    }
    
    private func calculatePortfolioAllocation() async {
        do {
            let positions = try await supabaseService.getPositions()
            
            let allocation = Dictionary(grouping: positions, by: { $0.symbol })
                .map { symbol, positions in
                    let totalValue = positions.reduce(0) { $0 + ($1.size * $1.markPrice) }
                    return PortfolioAllocation(
                        symbol: symbol,
                        value: totalValue,
                        percentage: 0, // Calculate percentage of total portfolio
                        quantity: positions.reduce(0) { $0 + $1.size },
                        averagePrice: positions.reduce(0) { $0 + $1.entryPrice } / Double(positions.count)
                    )
                }
                .sorted { $0.value > $1.value }
            
            await MainActor.run {
                self.portfolioAllocation = allocation
            }
        } catch {
            loggingService.error("Failed to calculate portfolio allocation", category: "analytics", error: error)
        }
    }
    
    private func calculateMonthlyReturns() async {
        do {
            let trades = try await supabaseService.getTrades()
            
            let monthlyData = Dictionary(grouping: trades) { trade in
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month], from: trade.timestamp)
                return calendar.date(from: components) ?? trade.timestamp
            }
            
            let monthlyReturns = monthlyData.map { month, trades in
                let totalPnl = trades.reduce(0) { $0 + $1.realizedPnl }
                let totalValue = trades.reduce(0) { $0 + ($1.quantity * $1.price) }
                let returnRate = totalValue > 0 ? (totalPnl / totalValue) * 100 : 0
                
                return MonthlyReturn(
                    month: month,
                    totalPnl: totalPnl,
                    returnRate: returnRate,
                    tradeCount: trades.count,
                    volume: trades.reduce(0) { $0 + $1.quantity }
                )
            }.sorted { $0.month < $1.month }
            
            await MainActor.run {
                self.monthlyReturns = monthlyReturns
            }
        } catch {
            loggingService.error("Failed to calculate monthly returns", category: "analytics", error: error)
        }
    }
    
    private func calculateDrawdownAnalysis() async {
        do {
            let trades = try await supabaseService.getTrades()
            
            await MainActor.run {
                self.drawdownAnalysis = DrawdownAnalysis(
                    maxDrawdown: calculateMaxDrawdown(trades: trades),
                    currentDrawdown: calculateCurrentDrawdown(trades: trades),
                    drawdownDuration: calculateDrawdownDuration(trades: trades),
                    recoveryTime: calculateRecoveryTime(trades: trades),
                    underwaterPeriods: calculateUnderwaterPeriods(trades: trades)
                )
            }
        } catch {
            loggingService.error("Failed to calculate drawdown analysis", category: "analytics", error: error)
        }
    }
    
    // MARK: - Calculation Helper Methods
    private func calculateWinRate(trades: [Trade]) -> Double {
        guard !trades.isEmpty else { return 0 }
        let profitableTrades = trades.filter { $0.realizedPnl > 0 }.count
        return Double(profitableTrades) / Double(trades.count) * 100
    }
    
    private func calculateAverageTradeSize(trades: [Trade]) -> Double {
        guard !trades.isEmpty else { return 0 }
        let totalVolume = trades.reduce(0) { $0 + $1.quantity }
        return totalVolume / Double(trades.count)
    }
    
    private func calculateTotalReturn(trades: [Trade]) -> Double {
        return trades.reduce(0) { $0 + $1.realizedPnl }
    }
    
    private func calculateAnnualizedReturn(trades: [Trade]) -> Double {
        guard !trades.isEmpty else { return 0 }
        
        let totalReturn = calculateTotalReturn(trades: trades)
        let firstTrade = trades.min(by: { $0.timestamp < $1.timestamp })?.timestamp ?? Date()
        let lastTrade = trades.max(by: { $0.timestamp < $1.timestamp })?.timestamp ?? Date()
        
        let timeSpan = lastTrade.timeIntervalSince(firstTrade)
        let years = timeSpan / (365 * 24 * 60 * 60)
        
        guard years > 0 else { return 0 }
        return pow(1 + totalReturn, 1/years) - 1
    }
    
    private func calculateSharpeRatio(trades: [Trade]) -> Double {
        guard trades.count > 1 else { return 0 }
        
        let returns = trades.map { $0.realizedPnl }
        let averageReturn = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.reduce(0) { $0 + pow($1 - averageReturn, 2) } / Double(returns.count)
        let standardDeviation = sqrt(variance)
        
        guard standardDeviation > 0 else { return 0 }
        return averageReturn / standardDeviation
    }
    
    private func calculateSortinoRatio(trades: [Trade]) -> Double {
        guard trades.count > 1 else { return 0 }
        
        let returns = trades.map { $0.realizedPnl }
        let averageReturn = returns.reduce(0, +) / Double(returns.count)
        let downsideReturns = returns.filter { $0 < 0 }
        
        guard !downsideReturns.isEmpty else { return 0 }
        
        let downsideVariance = downsideReturns.reduce(0) { $0 + pow($1, 2) } / Double(downsideReturns.count)
        let downsideDeviation = sqrt(downsideVariance)
        
        guard downsideDeviation > 0 else { return 0 }
        return averageReturn / downsideDeviation
    }
    
    private func calculateCalmarRatio(trades: [Trade]) -> Double {
        let annualizedReturn = calculateAnnualizedReturn(trades: trades)
        let maxDrawdown = calculateMaxDrawdown(trades: trades)
        
        guard maxDrawdown > 0 else { return 0 }
        return annualizedReturn / abs(maxDrawdown)
    }
    
    private func calculateProfitFactor(trades: [Trade]) -> Double {
        let grossProfit = trades.filter { $0.realizedPnl > 0 }.reduce(0) { $0 + $1.realizedPnl }
        let grossLoss = abs(trades.filter { $0.realizedPnl < 0 }.reduce(0) { $0 + $1.realizedPnl })
        
        guard grossLoss > 0 else { return grossProfit > 0 ? Double.infinity : 0 }
        return grossProfit / grossLoss
    }
    
    private func calculateAverageWin(trades: [Trade]) -> Double {
        let winningTrades = trades.filter { $0.realizedPnl > 0 }
        guard !winningTrades.isEmpty else { return 0 }
        return winningTrades.reduce(0) { $0 + $1.realizedPnl } / Double(winningTrades.count)
    }
    
    private func calculateAverageLoss(trades: [Trade]) -> Double {
        let losingTrades = trades.filter { $0.realizedPnl < 0 }
        guard !losingTrades.isEmpty else { return 0 }
        return losingTrades.reduce(0) { $0 + $1.realizedPnl } / Double(losingTrades.count)
    }
    
    private func calculateConsecutiveWins(trades: [Trade]) -> Int {
        var maxConsecutive = 0
        var currentConsecutive = 0
        
        for trade in trades.sorted(by: { $0.timestamp < $1.timestamp }) {
            if trade.realizedPnl > 0 {
                currentConsecutive += 1
                maxConsecutive = max(maxConsecutive, currentConsecutive)
            } else {
                currentConsecutive = 0
            }
        }
        
        return maxConsecutive
    }
    
    private func calculateConsecutiveLosses(trades: [Trade]) -> Int {
        var maxConsecutive = 0
        var currentConsecutive = 0
        
        for trade in trades.sorted(by: { $0.timestamp < $1.timestamp }) {
            if trade.realizedPnl < 0 {
                currentConsecutive += 1
                maxConsecutive = max(maxConsecutive, currentConsecutive)
            } else {
                currentConsecutive = 0
            }
        }
        
        return maxConsecutive
    }
    
    private func calculateMaxDrawdown(trades: [Trade]) -> Double {
        let sortedTrades = trades.sorted(by: { $0.timestamp < $1.timestamp })
        var peak = 0.0
        var maxDrawdown = 0.0
        var runningTotal = 0.0
        
        for trade in sortedTrades {
            runningTotal += trade.realizedPnl
            if runningTotal > peak {
                peak = runningTotal
            }
            
            let drawdown = peak - runningTotal
            if drawdown > maxDrawdown {
                maxDrawdown = drawdown
            }
        }
        
        return maxDrawdown
    }
    
    private func calculateValueAtRisk(trades: [Trade], confidence: Double = 0.95) -> Double {
        guard trades.count > 1 else { return 0 }
        
        let returns = trades.map { $0.realizedPnl }
        let sortedReturns = returns.sorted()
        let index = Int((1 - confidence) * Double(sortedReturns.count))
        
        return sortedReturns[index]
    }
    
    private func calculateVolatility(trades: [Trade]) -> Double {
        guard trades.count > 1 else { return 0 }
        
        let returns = trades.map { $0.realizedPnl }
        let averageReturn = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.reduce(0) { $0 + pow($1 - averageReturn, 2) } / Double(returns.count)
        
        return sqrt(variance)
    }
    
    private func calculateDownsideDeviation(trades: [Trade]) -> Double {
        guard trades.count > 1 else { return 0 }
        
        let returns = trades.map { $0.realizedPnl }
        let averageReturn = returns.reduce(0, +) / Double(returns.count)
        let downsideReturns = returns.filter { $0 < averageReturn }
        
        guard !downsideReturns.isEmpty else { return 0 }
        
        let downsideVariance = downsideReturns.reduce(0) { $0 + pow($1 - averageReturn, 2) } / Double(downsideReturns.count)
        return sqrt(downsideVariance)
    }
    
    private func calculateBeta(trades: [Trade]) -> Double {
        // Simplified beta calculation - would need market data for proper calculation
        return 1.0
    }
    
    private func calculateCorrelation(trades: [Trade]) -> Double {
        // Simplified correlation calculation
        return 0.0
    }
    
    private func calculateKurtosis(trades: [Trade]) -> Double {
        // Simplified kurtosis calculation
        return 0.0
    }
    
    private func calculateSkewness(trades: [Trade]) -> Double {
        // Simplified skewness calculation
        return 0.0
    }
    
    private func calculateCurrentDrawdown(trades: [Trade]) -> Double {
        let maxDrawdown = calculateMaxDrawdown(trades: trades)
        let totalReturn = calculateTotalReturn(trades: trades)
        return max(0, maxDrawdown - totalReturn)
    }
    
    private func calculateDrawdownDuration(trades: [Trade]) -> TimeInterval {
        // Simplified duration calculation
        return 0
    }
    
    private func calculateRecoveryTime(trades: [Trade]) -> TimeInterval {
        // Simplified recovery time calculation
        return 0
    }
    
    private func calculateUnderwaterPeriods(trades: [Trade]) -> Int {
        // Simplified underwater periods calculation
        return 0
    }
    
    // MARK: - Analysis Helper Methods
    private func filterTradesByDateRange(_ trades: [Trade], dateRange: DateRange) -> [Trade] {
        let (startDate, endDate) = dateRange.getDateRange()
        return trades.filter { trade in
            trade.timestamp >= startDate && trade.timestamp <= endDate
        }
    }
    
    private func getTopPerformingSymbols(trades: [Trade]) -> [String] {
        let symbolPerformance = Dictionary(grouping: trades, by: { $0.symbol })
            .mapValues { trades in
                trades.reduce(0) { $0 + $1.realizedPnl }
            }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
        
        return Array(symbolPerformance)
    }
    
    private func getWorstPerformingSymbols(trades: [Trade]) -> [String] {
        let symbolPerformance = Dictionary(grouping: trades, by: { $0.symbol })
            .mapValues { trades in
                trades.reduce(0) { $0 + $1.realizedPnl }
            }
            .sorted { $0.value < $1.value }
            .prefix(5)
            .map { $0.key }
        
        return Array(symbolPerformance)
    }
    
    private func analyzeTradingHours(trades: [Trade]) -> [Int: Int] {
        let hourDistribution = Dictionary(grouping: trades) { trade in
            Calendar.current.component(.hour, from: trade.timestamp)
        }
        .mapValues { $0.count }
        
        return hourDistribution
    }
    
    private func analyzeMarketConditions(trades: [Trade]) -> String {
        // Simplified market condition analysis
        let volatility = calculateVolatility(trades: trades)
        let winRate = calculateWinRate(trades: trades)
        
        if volatility > 100 && winRate < 40 {
            return "Высокая волатильность, низкая доходность"
        } else if volatility < 50 && winRate > 60 {
            return "Низкая волатильность, высокая доходность"
        } else {
            return "Смешанные условия"
        }
    }
    
    private func generateRecommendations(trades: [Trade]) -> [String] {
        var recommendations: [String] = []
        
        let winRate = calculateWinRate(trades: trades)
        let profitFactor = calculateProfitFactor(trades: trades)
        let maxDrawdown = calculateMaxDrawdown(trades: trades)
        
        if winRate < 40 {
            recommendations.append("Рассмотрите улучшение стратегии входа в позиции")
        }
        
        if profitFactor < 1.5 {
            recommendations.append("Оптимизируйте управление рисками")
        }
        
        if maxDrawdown > 20 {
            recommendations.append("Уменьшите размер позиций для снижения риска")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Продолжайте текущую стратегию")
        }
        
        return recommendations
    }
    
    // MARK: - Export Methods
    private func exportReportToCSV(_ report: TradingReport) -> String {
        var csv = "Параметр,Значение\n"
        csv += "Период,\(report.dateRange)\n"
        csv += "Всего сделок,\(report.totalTrades)\n"
        csv += "Прибыльных сделок,\(report.profitableTrades)\n"
        csv += "Общий объем,\(report.totalVolume)\n"
        csv += "Общий P&L,\(report.totalPnl)\n"
        csv += "Общие комиссии,\(report.totalFees)\n"
        csv += "Винрейт,\(String(format: "%.2f", report.winRate))%\n"
        csv += "Средний размер сделки,\(String(format: "%.2f", report.averageTradeSize))\n"
        csv += "Максимальная прибыль,\(report.largestWin)\n"
        csv += "Максимальный убыток,\(report.largestLoss)\n"
        csv += "Коэффициент Шарпа,\(String(format: "%.2f", report.sharpeRatio))\n"
        csv += "Максимальная просадка,\(String(format: "%.2f", report.maxDrawdown))\n"
        csv += "Profit Factor,\(String(format: "%.2f", report.profitFactor))\n"
        
        return csv
    }
    
    private func exportReportToExcel(_ report: TradingReport) -> String {
        // Simplified Excel export - would use proper Excel library in production
        return exportReportToCSV(report)
    }
    
    private func exportReportToJSON(_ report: TradingReport) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        if let data = try? encoder.encode(report),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
}

// MARK: - Models
struct TradingStatistics {
    var totalTrades: Int = 0
    var buyTrades: Int = 0
    var sellTrades: Int = 0
    var totalVolume: Double = 0
    var totalValue: Double = 0
    var totalFees: Double = 0
    var profitableTrades: Int = 0
    var winRate: Double = 0
    var averageTradeSize: Double = 0
    var totalPnl: Double = 0
}

struct PerformanceMetrics {
    var totalReturn: Double = 0
    var annualizedReturn: Double = 0
    var sharpeRatio: Double = 0
    var sortinoRatio: Double = 0
    var calmarRatio: Double = 0
    var profitFactor: Double = 0
    var averageWin: Double = 0
    var averageLoss: Double = 0
    var largestWin: Double = 0
    var largestLoss: Double = 0
    var consecutiveWins: Int = 0
    var consecutiveLosses: Int = 0
}

struct RiskMetrics {
    var maxDrawdown: Double = 0
    var valueAtRisk: Double = 0
    var volatility: Double = 0
    var downsideDeviation: Double = 0
    var beta: Double = 0
    var correlation: Double = 0
    var kurtosis: Double = 0
    var skewness: Double = 0
}

struct PortfolioAllocation {
    let symbol: String
    let value: Double
    let percentage: Double
    let quantity: Double
    let averagePrice: Double
}

struct MonthlyReturn {
    let month: Date
    let totalPnl: Double
    let returnRate: Double
    let tradeCount: Int
    let volume: Double
}

struct DrawdownAnalysis {
    var maxDrawdown: Double = 0
    var currentDrawdown: Double = 0
    var drawdownDuration: TimeInterval = 0
    var recoveryTime: TimeInterval = 0
    var underwaterPeriods: Int = 0
}

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case excel = "Excel"
    case json = "JSON"
}

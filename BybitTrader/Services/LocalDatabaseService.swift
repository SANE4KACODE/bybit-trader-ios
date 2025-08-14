import Foundation
import CoreData
import Combine

class LocalDatabaseService: ObservableObject {
    static let shared = LocalDatabaseService()
    
    // MARK: - Published Properties
    @Published var trades: [LocalTrade] = []
    @Published var positions: [LocalPosition] = []
    @Published var balances: [LocalBalance] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let container: NSPersistentContainer
    private let loggingService = LoggingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    private init() {
        container = NSPersistentContainer(name: "BybitTraderDataModel")
        setupContainer()
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupContainer() {
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                self?.loggingService.error("Failed to load Core Data container", category: "database", error: error)
                self?.errorMessage = "Ошибка загрузки базы данных"
            } else {
                self?.loggingService.info("Core Data container loaded successfully", category: "database")
                self?.loadInitialData()
            }
        }
        
        // Configure automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    private func setupObservers() {
        // Observe context changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: container.viewContext)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Initial Data Loading
    private func loadInitialData() {
        Task {
            await loadTrades()
            await loadPositions()
            await loadBalances()
        }
    }
    
    // MARK: - Trade Management
    func saveTrade(_ trade: Trade) async {
        await MainActor.run {
            let localTrade = LocalTrade(context: self.viewContext)
            localTrade.id = trade.id
            localTrade.symbol = trade.symbol
            localTrade.side = trade.side
            localTrade.quantity = trade.quantity
            localTrade.price = trade.price
            localTrade.timestamp = trade.timestamp
            localTrade.tags = trade.tags
            localTrade.notes = trade.notes
            localTrade.fee = trade.fee
            localTrade.orderType = trade.orderType
            localTrade.status = trade.status
            localTrade.createdAt = Date()
            localTrade.updatedAt = Date()
            
            self.saveContext()
            
            self.loggingService.info("Trade saved to local database", category: "database", metadata: [
                "symbol": trade.symbol,
                "side": trade.side,
                "quantity": trade.quantity
            ])
        }
    }
    
    func updateTrade(_ trade: Trade) async {
        await MainActor.run {
            let request: NSFetchRequest<LocalTrade> = LocalTrade.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", trade.id.uuidString)
            
            do {
                let results = try self.viewContext.fetch(request)
                if let localTrade = results.first {
                    localTrade.symbol = trade.symbol
                    localTrade.side = trade.side
                    localTrade.quantity = trade.quantity
                    localTrade.price = trade.price
                    localTrade.timestamp = trade.timestamp
                    localTrade.tags = trade.tags
                    localTrade.notes = trade.notes
                    localTrade.fee = trade.fee
                    localTrade.orderType = trade.orderType
                    localTrade.status = trade.status
                    localTrade.updatedAt = Date()
                    
                    self.saveContext()
                    
                    self.loggingService.info("Trade updated in local database", category: "database", metadata: [
                        "id": trade.id.uuidString,
                        "symbol": trade.symbol
                    ])
                }
            } catch {
                self.loggingService.error("Failed to update trade", category: "database", error: error)
            }
        }
    }
    
    func deleteTrade(_ trade: Trade) async {
        await MainActor.run {
            let request: NSFetchRequest<LocalTrade> = LocalTrade.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", trade.id.uuidString)
            
            do {
                let results = try self.viewContext.fetch(request)
                if let localTrade = results.first {
                    self.viewContext.delete(localTrade)
                    self.saveContext()
                    
                    self.loggingService.info("Trade deleted from local database", category: "database", metadata: [
                        "id": trade.id.uuidString,
                        "symbol": trade.symbol
                    ])
                }
            } catch {
                self.loggingService.error("Failed to delete trade", category: "database", error: error)
            }
        }
    }
    
    func loadTrades() async {
        await MainActor.run {
            let request: NSFetchRequest<LocalTrade> = LocalTrade.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \LocalTrade.timestamp, ascending: false)]
            
            do {
                let results = try self.viewContext.fetch(request)
                self.trades = results
                
                self.loggingService.info("Trades loaded from local database", category: "database", metadata: [
                    "count": results.count
                ])
            } catch {
                self.loggingService.error("Failed to load trades", category: "database", error: error)
                self.errorMessage = "Не удалось загрузить сделки"
            }
        }
    }
    
    func searchTrades(query: String, dateRange: DateRange?, tags: Set<String>) async -> [LocalTrade] {
        await MainActor.run {
            let request: NSFetchRequest<LocalTrade> = LocalTrade.fetchRequest()
            
            var predicates: [NSPredicate] = []
            
            // Text search
            if !query.isEmpty {
                let textPredicate = NSPredicate(format: "symbol CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", query, query)
                predicates.append(textPredicate)
            }
            
            // Date range
            if let dateRange = dateRange {
                let (startDate, endDate) = dateRange.getDateRange()
                let datePredicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)
                predicates.append(datePredicate)
            }
            
            // Tags
            if !tags.isEmpty {
                let tagPredicates = tags.map { NSPredicate(format: "ANY tags CONTAINS[cd] %@", $0) }
                let tagPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: tagPredicates)
                predicates.append(tagPredicate)
            }
            
            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            request.sortDescriptors = [NSSortDescriptor(keyPath: \LocalTrade.timestamp, ascending: false)]
            
            do {
                let results = try self.viewContext.fetch(request)
                return results
            } catch {
                self.loggingService.error("Failed to search trades", category: "database", error: error)
                return []
            }
        }
    }
    
    // MARK: - Position Management
    func savePosition(_ position: Position) async {
        await MainActor.run {
            let localPosition = LocalPosition(context: self.viewContext)
            localPosition.id = position.id
            localPosition.symbol = position.symbol
            localPosition.side = position.side
            localPosition.size = position.size
            localPosition.entryPrice = position.entryPrice
            localPosition.markPrice = position.markPrice
            localPosition.unrealizedPnl = position.unrealizedPnl
            localPosition.realizedPnl = position.realizedPnl
            localPosition.leverage = position.leverage
            localPosition.createdAt = Date()
            localPosition.updatedAt = Date()
            
            self.saveContext()
        }
    }
    
    func loadPositions() async {
        await MainActor.run {
            let request: NSFetchRequest<LocalPosition> = LocalPosition.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \LocalPosition.updatedAt, ascending: false)]
            
            do {
                let results = try self.viewContext.fetch(request)
                self.positions = results
            } catch {
                self.loggingService.error("Failed to load positions", category: "database", error: error)
            }
        }
    }
    
    // MARK: - Balance Management
    func saveBalance(_ balance: Balance) async {
        await MainActor.run {
            let localBalance = LocalBalance(context: self.viewContext)
            localBalance.id = balance.id
            localBalance.coin = balance.coin
            localBalance.walletBalance = balance.walletBalance
            localBalance.transferBalance = balance.transferBalance
            localBalance.bonusBalance = balance.bonusBalance
            localBalance.createdAt = Date()
            localBalance.updatedAt = Date()
            
            self.saveContext()
        }
    }
    
    func loadBalances() async {
        await MainActor.run {
            let request: NSFetchRequest<LocalBalance> = LocalBalance.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \LocalBalance.updatedAt, ascending: false)]
            
            do {
                let results = try self.viewContext.fetch(request)
                self.balances = results
            } catch {
                self.loggingService.error("Failed to load balances", category: "database", error: error)
            }
        }
    }
    
    // MARK: - Data Export
    func exportTradesToCSV() -> String {
        var csv = "Symbol,Side,Quantity,Price,Timestamp,Tags,Notes,Fee,OrderType,Status\n"
        
        for trade in trades {
            let tags = trade.tags?.joined(separator: ";") ?? ""
            let notes = trade.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            let timestamp = trade.timestamp?.formatted() ?? ""
            
            csv += "\(trade.symbol ?? ""),\(trade.side ?? ""),\(trade.quantity),\(trade.price),\(timestamp),\(tags),\(notes),\(trade.fee),\(trade.orderType ?? ""),\(trade.status ?? "")\n"
        }
        
        return csv
    }
    
    func exportTradesToJSON() -> Data? {
        let tradeData = trades.map { trade in
            [
                "id": trade.id?.uuidString ?? "",
                "symbol": trade.symbol ?? "",
                "side": trade.side ?? "",
                "quantity": trade.quantity,
                "price": trade.price,
                "timestamp": trade.timestamp?.timeIntervalSince1970 ?? 0,
                "tags": trade.tags ?? [],
                "notes": trade.notes ?? "",
                "fee": trade.fee,
                "orderType": trade.orderType ?? "",
                "status": trade.status ?? ""
            ]
        }
        
        return try? JSONSerialization.data(withJSONObject: tradeData, options: .prettyPrinted)
    }
    
    // MARK: - Statistics
    func getTradeStatistics() -> TradeStatistics {
        let totalTrades = trades.count
        let buyTrades = trades.filter { $0.side == "Buy" }.count
        let sellTrades = trades.filter { $0.side == "Sell" }.count
        
        let totalVolume = trades.reduce(0) { $0 + $1.quantity }
        let totalValue = trades.reduce(0) { $0 + ($1.quantity * $1.price) }
        let totalFees = trades.reduce(0) { $0 + $1.fee }
        
        let profitableTrades = trades.filter { trade in
            if let pnl = trade.unrealizedPnl {
                return pnl > 0
            }
            return false
        }.count
        
        let winRate = totalTrades > 0 ? Double(profitableTrades) / Double(totalTrades) : 0
        
        return TradeStatistics(
            totalTrades: totalTrades,
            buyTrades: buyTrades,
            sellTrades: sellTrades,
            totalVolume: totalVolume,
            totalValue: totalValue,
            totalFees: totalFees,
            profitableTrades: profitableTrades,
            winRate: winRate
        )
    }
    
    // MARK: - Data Synchronization
    func syncWithSupabase() async {
        // This method would sync local data with Supabase
        // Implementation depends on your sync strategy
        loggingService.info("Starting data synchronization with Supabase", category: "database")
        
        // Sync trades
        await syncTrades()
        
        // Sync positions
        await syncPositions()
        
        // Sync balances
        await syncBalances()
        
        loggingService.info("Data synchronization completed", category: "database")
    }
    
    private func syncTrades() async {
        // Implementation for syncing trades
    }
    
    private func syncPositions() async {
        // Implementation for syncing positions
    }
    
    private func syncBalances() async {
        // Implementation for syncing balances
    }
    
    // MARK: - Database Maintenance
    func clearOldData(olderThan days: Int) async {
        await MainActor.run {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            
            // Clear old trades
            let tradeRequest: NSFetchRequest<LocalTrade> = LocalTrade.fetchRequest()
            tradeRequest.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)
            
            do {
                let oldTrades = try self.viewContext.fetch(tradeRequest)
                for trade in oldTrades {
                    self.viewContext.delete(trade)
                }
                
                self.saveContext()
                
                self.loggingService.info("Old data cleared", category: "database", metadata: [
                    "cutoffDate": cutoffDate,
                    "tradesDeleted": oldTrades.count
                ])
            } catch {
                self.loggingService.error("Failed to clear old data", category: "database", error: error)
            }
        }
    }
    
    func compactDatabase() async {
        await MainActor.run {
            do {
                try self.container.persistentStoreCoordinator.persistentStores.forEach { store in
                    try self.container.persistentStoreCoordinator.remove(store)
                    try self.container.persistentStoreCoordinator.addPersistentStore(
                        ofType: store.type,
                        configurationName: store.configurationName,
                        at: store.url,
                        options: store.options
                    )
                }
                
                self.loggingService.info("Database compacted successfully", category: "database")
            } catch {
                self.loggingService.error("Failed to compact database", category: "database", error: error)
            }
        }
    }
    
    // MARK: - Private Methods
    private func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                loggingService.error("Failed to save Core Data context", category: "database", error: error)
                errorMessage = "Ошибка сохранения данных"
            }
        }
    }
}

// MARK: - Models
struct TradeStatistics {
    let totalTrades: Int
    let buyTrades: Int
    let sellTrades: Int
    let totalVolume: Double
    let totalValue: Double
    let totalFees: Double
    let profitableTrades: Int
    let winRate: Double
}

enum DateRange: CaseIterable {
    case today
    case week
    case month
    case quarter
    case year
    case custom
    
    func getDateRange() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
            return (startOfDay, endOfDay)
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) ?? now
            return (startOfWeek, endOfWeek)
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
            return (startOfMonth, endOfMonth)
        case .quarter:
            let startOfQuarter = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
            let endOfQuarter = calendar.date(byAdding: .quarter, value: 1, to: startOfQuarter) ?? now
            return (startOfQuarter, endOfQuarter)
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) ?? now
            return (startOfYear, endOfYear)
        case .custom:
            return (now, now)
        }
    }
    
    var displayName: String {
        switch self {
        case .today: return "Сегодня"
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .quarter: return "Квартал"
        case .year: return "Год"
        case .custom: return "Произвольно"
        }
    }
}

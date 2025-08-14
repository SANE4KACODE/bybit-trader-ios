import Foundation
import Security
import Combine

class APIKeyManagementService: ObservableObject {
    static let shared = APIKeyManagementService()
    
    // MARK: - Published Properties
    @Published var userAPIKeys: [UserAPIKey] = []
    @Published var currentAPIKey: UserAPIKey?
    @Published var isTestnet: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // MARK: - Private Properties
    private let keychainService = "com.bybittrader.apikeys"
    private let loggingService = LoggingService.shared
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadUserAPIKeys()
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Observe API key changes
        $currentAPIKey
            .sink { [weak self] apiKey in
                if let apiKey = apiKey {
                    self?.loggingService.info("API key changed", category: "apikeys", metadata: [
                        "keyId": apiKey.id.uuidString,
                        "isTestnet": apiKey.isTestnet
                    ])
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func addAPIKey(name: String, apiKey: String, apiSecret: String, isTestnet: Bool = true) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Validate API key format
        guard validateAPIKeyFormat(apiKey, apiSecret: apiSecret) else {
            await MainActor.run {
                self.errorMessage = "Неверный формат API ключа или секрета"
                self.isLoading = false
            }
            return
        }
        
        // Test API key with Bybit
        let isValid = await testAPIKey(apiKey: apiKey, apiSecret: apiSecret, isTestnet: isTestnet)
        
        guard isValid else {
            await MainActor.run {
                self.errorMessage = "API ключ недействителен или не имеет необходимых разрешений"
                self.isLoading = false
            }
            return
        }
        
        // Create new user API key
        let newUserKey = UserAPIKey(
            name: name,
            apiKey: apiKey,
            apiSecret: apiSecret,
            isTestnet: isTestnet,
            isActive: true
        )
        
        // Save to keychain
        let saved = saveToKeychain(newUserKey)
        
        guard saved else {
            await MainActor.run {
                self.errorMessage = "Не удалось сохранить API ключ"
                self.isLoading = false
            }
            return
        }
        
        // Save to Supabase
        do {
            try await supabaseService.saveUserAPIKey(newUserKey)
            
            await MainActor.run {
                self.userAPIKeys.append(newUserKey)
                self.currentAPIKey = newUserKey
                self.isTestnet = isTestnet
                self.successMessage = "API ключ успешно добавлен"
                self.isLoading = false
                
                self.loggingService.info("API key added successfully", category: "apikeys", metadata: [
                    "keyId": newUserKey.id.uuidString,
                    "name": name,
                    "isTestnet": isTestnet
                ])
            }
        } catch {
            await MainActor.run {
                self.loggingService.error("Failed to save API key to Supabase", category: "apikeys", error: error)
                self.errorMessage = "Не удалось сохранить API ключ в облаке"
                self.isLoading = false
            }
        }
    }
    
    func updateAPIKey(_ apiKey: UserAPIKey, name: String? = nil, isActive: Bool? = nil) async {
        isLoading = true
        errorMessage = nil
        
        var updatedKey = apiKey
        
        if let name = name {
            updatedKey.name = name
        }
        
        if let isActive = isActive {
            updatedKey.isActive = isActive
        }
        
        updatedKey.updatedAt = Date()
        
        // Update in keychain
        let updated = updateInKeychain(updatedKey)
        
        guard updated else {
            await MainActor.run {
                self.errorMessage = "Не удалось обновить API ключ"
                self.isLoading = false
            }
            return
        }
        
        // Update in Supabase
        do {
            try await supabaseService.updateUserAPIKey(updatedKey)
            
            await MainActor.run {
                if let index = self.userAPIKeys.firstIndex(where: { $0.id == updatedKey.id }) {
                    self.userAPIKeys[index] = updatedKey
                }
                
                if updatedKey.id == self.currentAPIKey?.id {
                    self.currentAPIKey = updatedKey
                }
                
                self.successMessage = "API ключ обновлен"
                self.isLoading = false
                
                self.loggingService.info("API key updated", category: "apikeys", metadata: [
                    "keyId": updatedKey.id.uuidString,
                    "name": updatedKey.name,
                    "isActive": updatedKey.isActive
                ])
            }
        } catch {
            await MainActor.run {
                self.loggingService.error("Failed to update API key in Supabase", category: "apikeys", error: error)
                self.errorMessage = "Не удалось обновить API ключ в облаке"
                self.isLoading = false
            }
        }
    }
    
    func deleteAPIKey(_ apiKey: UserAPIKey) async {
        isLoading = true
        errorMessage = nil
        
        // Remove from keychain
        let removed = removeFromKeychain(apiKey.id)
        
        guard removed else {
            await MainActor.run {
                self.errorMessage = "Не удалось удалить API ключ"
                self.isLoading = false
            }
            return
        }
        
        // Remove from Supabase
        do {
            try await supabaseService.deleteUserAPIKey(apiKey.id)
            
            await MainActor.run {
                self.userAPIKeys.removeAll { $0.id == apiKey.id }
                
                if self.currentAPIKey?.id == apiKey.id {
                    self.currentAPIKey = self.userAPIKeys.first { $0.isActive }
                }
                
                self.successMessage = "API ключ удален"
                self.isLoading = false
                
                self.loggingService.info("API key deleted", category: "apikeys", metadata: [
                    "keyId": apiKey.id.uuidString
                ])
            }
        } catch {
            await MainActor.run {
                self.loggingService.error("Failed to delete API key from Supabase", category: "apikeys", error: error)
                self.errorMessage = "Не удалось удалить API ключ из облака"
                self.isLoading = false
            }
        }
    }
    
    func activateAPIKey(_ apiKey: UserAPIKey) async {
        // Deactivate all other keys
        for key in userAPIKeys where key.isActive {
            var deactivatedKey = key
            deactivatedKey.isActive = false
            await updateAPIKey(deactivatedKey, isActive: false)
        }
        
        // Activate selected key
        await updateAPIKey(apiKey, isActive: true)
        
        await MainActor.run {
            self.currentAPIKey = apiKey
            self.isTestnet = apiKey.isTestnet
        }
    }
    
    func getCurrentAPIKey() -> UserAPIKey? {
        return currentAPIKey
    }
    
    func getAPIKeyCredentials() -> (apiKey: String, apiSecret: String)? {
        guard let currentKey = currentAPIKey else { return nil }
        return (currentKey.apiKey, currentKey.apiSecret)
    }
    
    func validateCurrentAPIKey() async -> Bool {
        guard let currentKey = currentAPIKey else { return false }
        
        return await testAPIKey(
            apiKey: currentKey.apiKey,
            apiSecret: currentKey.apiSecret,
            isTestnet: currentKey.isTestnet
        )
    }
    
    // MARK: - Private Methods
    private func validateAPIKeyFormat(_ apiKey: String, apiSecret: String) -> Bool {
        // Basic validation - API key should be alphanumeric and reasonable length
        let apiKeyValid = apiKey.count >= 10 && apiKey.count <= 100 && apiKey.range(of: "^[a-zA-Z0-9]+$", options: .regularExpression) != nil
        let apiSecretValid = apiSecret.count >= 20 && apiSecret.count <= 100 && apiSecret.range(of: "^[a-zA-Z0-9]+$", options: .regularExpression) != nil
        
        return apiKeyValid && apiSecretValid
    }
    
    private func testAPIKey(apiKey: String, apiSecret: String, isTestnet: Bool) async -> Bool {
        let baseURL = isTestnet ? "https://api-testnet.bybit.com" : "https://api.bybit.com"
        let endpoint = "/v5/account/wallet-balance"
        let url = baseURL + endpoint
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let headers = createHeaders(endpoint: endpoint, method: "GET", apiKey: apiKey, apiSecret: apiSecret)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            
            return false
        } catch {
            loggingService.error("API key test failed", category: "apikeys", error: error)
            return false
        }
    }
    
    private func createHeaders(endpoint: String, method: String, apiKey: String, apiSecret: String) -> [String: String] {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let signature = generateSignature(endpoint: endpoint, method: method, timestamp: timestamp, apiSecret: apiSecret)
        
        return [
            "X-BAPI-API-KEY": apiKey,
            "X-BAPI-SIGNATURE": signature,
            "X-BAPI-SIGNATURE-TYPE": "2",
            "X-BAPI-TIMESTAMP": String(timestamp)
        ]
    }
    
    private func generateSignature(endpoint: String, method: String, timestamp: Int64, apiSecret: String) -> String {
        let queryString = "api_key=\(apiKey)&timestamp=\(timestamp)"
        let signature = HMAC.SHA256.sign(data: queryString.data(using: .utf8)!, key: apiSecret.data(using: .utf8)!)
        return signature.map { String(format: "%02hhx", $0) }.joined()
    }
    
    // MARK: - Keychain Management
    private func saveToKeychain(_ userKey: UserAPIKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userKey.id.uuidString,
            kSecValueData as String: try? JSONEncoder().encode(userKey),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item already exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: userKey.id.uuidString
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: try? JSONEncoder().encode(userKey)
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            return updateStatus == errSecSuccess
        }
        
        return status == errSecSuccess
    }
    
    private func updateInKeychain(_ userKey: UserAPIKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userKey.id.uuidString
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: try? JSONEncoder().encode(userKey)
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        return status == errSecSuccess
    }
    
    private func removeFromKeychain(_ id: UUID) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: id.uuidString
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    private func loadUserAPIKeys() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let items = result as? [[String: Any]] {
            var loadedKeys: [UserAPIKey] = []
            
            for item in items {
                if let data = item[kSecValueData as String] as? Data,
                   let userKey = try? JSONDecoder().decode(UserAPIKey.self, from: data) {
                    loadedKeys.append(userKey)
                }
            }
            
            DispatchQueue.main.async {
                self.userAPIKeys = loadedKeys
                self.currentAPIKey = loadedKeys.first { $0.isActive }
                
                if let currentKey = self.currentAPIKey {
                    self.isTestnet = currentKey.isTestnet
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    func exportAPIKeys() -> String {
        var export = "=== API Keys Export ===\n"
        export += "Generated: \(Date())\n"
        export += "Total Keys: \(userAPIKeys.count)\n\n"
        
        for (index, key) in userAPIKeys.enumerated() {
            export += "\(index + 1). \(key.name)\n"
            export += "   ID: \(key.id.uuidString)\n"
            export += "   API Key: \(key.apiKey)\n"
            export += "   Testnet: \(key.isTestnet ? "Yes" : "No")\n"
            export += "   Active: \(key.isActive ? "Yes" : "No")\n"
            export += "   Created: \(key.createdAt.formatted())\n"
            export += "   Updated: \(key.updatedAt.formatted())\n\n"
        }
        
        return export
    }
}

// MARK: - Models
struct UserAPIKey: Identifiable, Codable {
    let id = UUID()
    var name: String
    let apiKey: String
    let apiSecret: String
    let isTestnet: Bool
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    
    init(name: String, apiKey: String, apiSecret: String, isTestnet: Bool = true, isActive: Bool = false) {
        self.name = name
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.isTestnet = isTestnet
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, apiKey, apiSecret, isTestnet, isActive, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        apiKey = try container.decode(String.self, forKey: .apiKey)
        apiSecret = try container.decode(String.self, forKey: .apiSecret)
        isTestnet = try container.decode(Bool.self, forKey: .isTestnet)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(apiSecret, forKey: .apiSecret)
        try container.encode(isTestnet, forKey: .isTestnet)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

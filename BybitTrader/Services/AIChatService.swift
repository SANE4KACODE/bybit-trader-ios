import Foundation

class AIChatService: ObservableObject {
    static let shared = AIChatService()
    
    private let apiKey = "sk-UJSfLa_vaSuXl4zi5rVbxw"
    private let baseURL = "https://api.artemox.com/v1"
    
    @Published var isTyping = false
    @Published var chatHistory: [ChatMessage] = []
    
    private init() {
        // Добавляем приветственное сообщение
        addSystemMessage("Привет! Я ваш AI-ассистент для торговли на Bybit. Могу помочь с анализом рынка, стратегиями торговли и ответить на вопросы по криптовалютам.")
    }
    
    // MARK: - Chat Functions
    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(role: .user, content: text, timestamp: Date())
        
        await MainActor.run {
            chatHistory.append(userMessage)
            isTyping = true
        }
        
        do {
            let response = try await generateResponse(for: text)
            let aiMessage = ChatMessage(role: .assistant, content: response, timestamp: Date())
            
            await MainActor.run {
                chatHistory.append(aiMessage)
                isTyping = false
            }
        } catch {
            let errorMessage = ChatMessage(
                role: .assistant,
                content: "Извините, произошла ошибка: \(error.localizedDescription)",
                timestamp: Date()
            )
            
            await MainActor.run {
                chatHistory.append(errorMessage)
                isTyping = false
            }
        }
    }
    
    private func generateResponse(for message: String) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = ChatRequest(
            model: "gpt-4o-mini",
            messages: [
                ChatMessageRequest(role: "system", content: systemPrompt),
                ChatMessageRequest(role: "user", content: message)
            ],
            maxTokens: 1000,
            temperature: 0.7
        )
        
        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIChatError.requestFailed
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return chatResponse.choices.first?.message.content ?? "Не удалось получить ответ"
    }
    
    private func addSystemMessage(_ content: String) {
        let systemMessage = ChatMessage(role: .system, content: content, timestamp: Date())
        chatHistory.append(systemMessage)
    }
    
    func clearChat() {
        chatHistory.removeAll()
        addSystemMessage("Привет! Я ваш AI-ассистент для торговли на Bybit. Могу помочь с анализом рынка, стратегиями торговли и ответить на вопросы по криптовалютам.")
    }
    
    // MARK: - System Prompt
    private var systemPrompt: String {
        """
        Ты - эксперт по криптовалютной торговле и платформе Bybit. Твоя задача - помогать пользователям с:
        
        1. Анализом рынка криптовалют
        2. Стратегиями торговли
        3. Использованием платформы Bybit
        4. Управлением рисками
        5. Техническим и фундаментальным анализом
        
        Всегда давай практические советы, объясняй сложные концепции простым языком и предупреждай о рисках.
        Отвечай на русском языке, используя профессиональную терминологию, но понятную для начинающих трейдеров.
        
        Если пользователь спрашивает о конкретных монетах или ценах, объясни, что это не финансовые рекомендации,
        а только образовательная информация.
        """
    }
}

// MARK: - Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
}

enum MessageRole {
    case user
    case assistant
    case system
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessageRequest]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
        case temperature
    }
}

struct ChatMessageRequest: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}

enum AIChatError: Error, LocalizedError {
    case requestFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .requestFailed:
            return "Ошибка при отправке запроса"
        case .invalidResponse:
            return "Неверный ответ от сервера"
        }
    }
}

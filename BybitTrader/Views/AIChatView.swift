import SwiftUI

struct AIChatView: View {
    @EnvironmentObject var aiChatService: AIChatService
    @State private var messageText = ""
    @State private var scrollToBottom = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // История чата
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(aiChatService.chatHistory) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if aiChatService.isTyping {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: aiChatService.chatHistory.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: aiChatService.isTyping) { isTyping in
                        if isTyping {
                            scrollToBottom(proxy: proxy)
                        }
                    }
                }
                
                // Поле ввода
                ChatInputView(
                    messageText: $messageText,
                    onSend: sendMessage,
                    isTyping: aiChatService.isTyping
                )
            }
            .navigationTitle("AI Ассистент")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Очистить") {
                        aiChatService.clearChat()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            scrollToBottom = true
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = messageText
        messageText = ""
        
        Task {
            await aiChatService.sendMessage(message)
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewReader) {
        withAnimation(.easeOut(duration: 0.3)) {
            if let lastMessage = aiChatService.chatHistory.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            } else if aiChatService.isTyping {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Аватар и роль
                HStack(spacing: 8) {
                    if message.role != .user {
                        Image(systemName: message.role == .assistant ? "brain.head.profile" : "gear")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(roleDisplayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if message.role == .user {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // Сообщение
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.role == .user ? Color.blue : Color(.systemGray6))
                    )
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)
                
                // Время
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role != .user {
                Spacer()
            }
        }
    }
    
    private var roleDisplayName: String {
        switch message.role {
        case .user:
            return "Вы"
        case .assistant:
            return "AI Ассистент"
        case .system:
            return "Система"
        }
    }
}

struct ChatInputView: View {
    @Binding var messageText: String
    let onSend: () -> Void
    let isTyping: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Поле ввода
                TextField("Введите сообщение...", text: $messageText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                    .disabled(isTyping)
                
                // Кнопка отправки
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping ? .secondary : .blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .onSubmit {
            onSend()
        }
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemGray6))
            )
            
            Spacer()
        }
        .onAppear {
            animationOffset = 1.0
        }
    }
}

#Preview {
    AIChatView()
        .environmentObject(AIChatService.shared)
}

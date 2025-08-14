import SwiftUI
import AuthenticationServices

struct AppleSignInView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @State private var isSigningIn = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isAuthenticated = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Логотип и заголовок
            VStack(spacing: 20) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .yellow]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Bybit Trader")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Торговля криптовалютами с AI-ассистентом")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Кнопка входа через Apple
            VStack(spacing: 16) {
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        handleSignInResult(result)
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(25)
                
                Text("Безопасный вход через Apple ID")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Дополнительная информация
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    FeatureItem(
                        icon: "shield.checkered",
                        title: "Безопасность",
                        description: "Ваши данные защищены"
                    )
                    
                    FeatureItem(
                        icon: "brain.head.profile",
                        title: "AI Ассистент",
                        description: "Помощь в торговле"
                    )
                }
                
                HStack(spacing: 16) {
                    FeatureItem(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Аналитика",
                        description: "Подробные графики"
                    )
                    
                    FeatureItem(
                        icon: "doc.text",
                        title: "Дневник",
                        description: "Отслеживание сделок"
                    )
                }
            }
            
            Spacer()
            
            // Условия использования
            VStack(spacing: 8) {
                Text("Входя в приложение, вы принимаете")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Button("Условия использования") {
                        // Показать условия
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Text("и")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Политику конфиденциальности") {
                        // Показать политику
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .alert("Ошибка входа", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $isAuthenticated) {
            MainTabView()
        }
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await signInWithApple(credential: appleIDCredential)
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isSigningIn = true
        
        do {
            let userId = credential.user
            let email = credential.email ?? ""
            let fullName = credential.fullName
            
            // Создаем профиль пользователя в Supabase
            try await supabaseService.createUserProfile(
                userId: userId,
                email: email,
                countryCode: getCountryCode(),
                currency: getCurrency()
            )
            
            await MainActor.run {
                isAuthenticated = true
                isSigningIn = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                isSigningIn = false
            }
        }
    }
    
    private func getCountryCode() -> String {
        let locale = Locale.current
        return locale.regionCode ?? "RU"
    }
    
    private func getCurrency() -> String {
        let locale = Locale.current
        return locale.currencyCode ?? "RUB"
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SignInWithAppleButton: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleSignIn), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void
        
        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void, onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }
        
        @objc func handleSignIn() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                fatalError("No window found")
            }
            return window
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }
    }
}

#Preview {
    AppleSignInView()
        .environmentObject(SupabaseService.shared)
}

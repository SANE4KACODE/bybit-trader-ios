import Foundation
import SwiftUI
import CoreHaptics

// MARK: - Enhanced Animation Service
class EnhancedAnimationService: ObservableObject {
    static let shared = EnhancedAnimationService()
    
    // MARK: - Published Properties
    @Published var isAnimating = false
    @Published var currentAnimation: AnimationType?
    @Published var animationProgress: Double = 0.0
    
    // MARK: - Private Properties
    private var engine: CHHapticEngine?
    private let loggingService = LoggingService.shared
    private var animationTimers: [Timer] = []
    
    private init() {
        setupHaptics()
    }
    
    // MARK: - Setup
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            loggingService.info("Haptics not supported on this device", category: "animations")
            return
        }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            loggingService.info("Haptic engine started successfully", category: "animations")
        } catch {
            loggingService.error("Failed to start haptic engine", category: "animations", error: error)
        }
    }
    
    // MARK: - Public Animation Methods
    
    // MARK: - Chart Animations
    func animateChartData<T: View>(_ view: T, delay: Double = 0.0) -> some View {
        return view
            .opacity(0)
            .scaleEffect(0.8)
            .rotationEffect(.degrees(-5))
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.0).delay(delay)) {
                    // Анимация появления
                }
            }
            .animation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.0).delay(delay), value: true)
    }
    
    func animateChartLine<T: View>(_ view: T, progress: Double) -> some View {
        return view
            .scaleEffect(x: progress, y: 1.0, anchor: .leading)
            .animation(.easeInOut(duration: 1.5), value: progress)
    }
    
    func animateCandlestick<T: View>(_ view: T, isGreen: Bool) -> some View {
        return view
            .scaleEffect(0.1)
            .opacity(0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double.random(in: 0...0.5))) {
                    // Анимация появления свечи
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .fill(isGreen ? Color.green : Color.red)
                    .scaleEffect(isGreen ? 1.0 : 1.0)
                    .opacity(isGreen ? 0.3 : 0.3)
                    .animation(.easeInOut(duration: 0.3).repeatCount(2, autoreverses: true), value: isGreen)
            )
    }
    
    // MARK: - Trading Animations
    func animateTradeExecution<T: View>(_ view: T, isBuy: Bool) -> some View {
        return view
            .overlay(
                ZStack {
                    // Эффект взрыва
                    ForEach(0..<8) { index in
                        Circle()
                            .fill(isBuy ? Color.green : Color.red)
                            .frame(width: 4, height: 4)
                            .scaleEffect(0)
                            .offset(
                                x: cos(Double(index) * .pi / 4) * 50,
                                y: sin(Double(index) * .pi / 4) * 50
                            )
                            .animation(
                                .easeOut(duration: 0.6)
                                .delay(Double(index) * 0.05),
                                value: true
                            )
                    }
                    
                    // Центральная вспышка
                    Circle()
                        .fill(isBuy ? Color.green : Color.red)
                        .frame(width: 20, height: 20)
                        .scaleEffect(0)
                        .opacity(0.8)
                        .animation(.easeOut(duration: 0.4), value: true)
                }
            )
            .onAppear {
                triggerHapticFeedback(.success)
            }
    }
    
    func animateOrderPlacement<T: View>(_ view: T) -> some View {
        return view
            .overlay(
                // Эффект пульсации
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .scaleEffect(1.5)
                    .opacity(0)
                    .animation(
                        .easeOut(duration: 1.0)
                        .repeatCount(3, autoreverses: false),
                        value: true
                    )
            )
            .onAppear {
                triggerHapticFeedback(.light)
            }
    }
    
    // MARK: - UI Animations
    func animateCardAppearance<T: View>(_ view: T, delay: Double = 0.0) -> some View {
        return view
            .opacity(0)
            .offset(y: 50)
            .scaleEffect(0.9)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    // Анимация появления карточки
                }
            }
    }
    
    func animateButtonPress<T: View>(_ view: T) -> some View {
        return view
            .scaleEffect(0.95)
            .animation(.easeInOut(duration: 0.1), value: true)
            .onTapGesture {
                triggerHapticFeedback(.light)
            }
    }
    
    func animateLoadingSpinner<T: View>(_ view: T) -> some View {
        return view
            .rotationEffect(.degrees(0))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    // Бесконечное вращение
                }
            }
    }
    
    // MARK: - Particle Effects
    func createParticleEffect<T: View>(_ view: T, particleCount: Int = 20) -> some View {
        return view
            .overlay(
                ZStack {
                    ForEach(0..<particleCount, id: \.self) { index in
                        Circle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 4, height: 4)
                            .offset(
                                x: CGFloat.random(in: -100...100),
                                y: CGFloat.random(in: -100...100)
                            )
                            .scaleEffect(0)
                            .opacity(0)
                            .animation(
                                .easeOut(duration: Double.random(in: 0.5...1.5))
                                .delay(Double.random(in: 0...0.5)),
                                value: true
                            )
                    }
                }
            )
    }
    
    // MARK: - Price Change Animations
    func animatePriceChange<T: View>(_ view: T, isPositive: Bool) -> some View {
        return view
            .overlay(
                // Эффект изменения цены
                Text(isPositive ? "↗" : "↘")
                    .font(.title2)
                    .foregroundColor(isPositive ? .green : .red)
                    .scaleEffect(0)
                    .opacity(0)
                    .offset(y: -20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(0.1),
                        value: true
                    )
            )
            .onAppear {
                triggerHapticFeedback(.medium)
            }
    }
    
    // MARK: - Success/Error Animations
    func animateSuccess<T: View>(_ view: T) -> some View {
        return view
            .overlay(
                ZStack {
                    // Галочка
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .scaleEffect(0)
                        .opacity(0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: true)
                    
                    // Концентрические круги
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.green, lineWidth: 2)
                            .scaleEffect(0)
                            .opacity(0.6)
                            .animation(
                                .easeOut(duration: 0.8)
                                .delay(Double(index) * 0.2),
                                value: true
                            )
                    }
                }
            )
            .onAppear {
                triggerHapticFeedback(.success)
            }
    }
    
    func animateError<T: View>(_ view: T) -> some View {
        return view
            .overlay(
                ZStack {
                    // Крестик
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .scaleEffect(0)
                        .opacity(0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: true)
                    
                    // Эффект тряски
                    view
                        .offset(x: 0)
                        .animation(
                            .easeInOut(duration: 0.1)
                            .repeatCount(3, autoreverses: true),
                            value: true
                        )
                }
            )
            .onAppear {
                triggerHapticFeedback(.error)
            }
    }
    
    // MARK: - Data Loading Animations
    func animateDataLoading<T: View>(_ view: T) -> some View {
        return view
            .overlay(
                // Skeleton loading
                VStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 16)
                            .scaleEffect(x: 0.8, y: 1.0, anchor: .leading)
                            .opacity(0.6)
                            .animation(
                                .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: true
                            )
                    }
                }
                .padding()
            )
    }
    
    // MARK: - Transition Animations
    func slideTransition<T: View>(_ view: T, from edge: Edge = .trailing) -> some View {
        return view
            .transition(
                .asymmetric(
                    insertion: .move(edge: edge).combined(with: .opacity),
                    removal: .move(edge: edge).combined(with: .opacity)
                )
            )
    }
    
    func scaleTransition<T: View>(_ view: T) -> some View {
        return view
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 1.2).combined(with: .opacity)
                )
            )
    }
    
    // MARK: - Haptic Feedback
    func triggerHapticFeedback(_ style: HapticStyle) {
        guard let engine = engine else { return }
        
        do {
            let pattern = createHapticPattern(for: style)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            
            loggingService.debug("Haptic feedback triggered", category: "animations", metadata: [
                "style": style.rawValue
            ])
        } catch {
            loggingService.error("Failed to trigger haptic feedback", category: "animations", error: error)
        }
    }
    
    private func createHapticPattern(for style: HapticStyle) -> CHHapticPattern {
        switch style {
        case .light:
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            return try! CHHapticPattern(events: [event], parameters: [])
            
        case .medium:
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            return try! CHHapticPattern(events: [event], parameters: [])
            
        case .heavy:
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            return try! CHHapticPattern(events: [event], parameters: [])
            
        case .success:
            let intensity1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
            let sharpness1 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity1, sharpness1], relativeTime: 0)
            
            let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            let sharpness2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity2, sharpness2], relativeTime: 0.1)
            
            return try! CHHapticPattern(events: [event1, event2], parameters: [])
            
        case .error:
            let intensity1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            let sharpness1 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity1, sharpness1], relativeTime: 0)
            
            let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            let sharpness2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity2, sharpness2], relativeTime: 0.05)
            
            let intensity3 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
            let sharpness3 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let event3 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity3, sharpness3], relativeTime: 0.1)
            
            return try! CHHapticPattern(events: [event1, event2, event3], parameters: [])
        }
    }
    
    // MARK: - Animation Control
    func startAnimation(_ type: AnimationType) {
        DispatchQueue.main.async {
            self.currentAnimation = type
            self.isAnimating = true
            self.animationProgress = 0.0
            
            self.loggingService.info("Animation started", category: "animations", metadata: [
                "type": type.rawValue
            ])
        }
    }
    
    func stopAnimation() {
        DispatchQueue.main.async {
            self.currentAnimation = nil
            self.isAnimating = false
            self.animationProgress = 0.0
            
            // Останавливаем все таймеры
            self.animationTimers.forEach { $0.invalidate() }
            self.animationTimers.removeAll()
            
            self.loggingService.info("Animation stopped", category: "animations")
        }
    }
    
    func updateAnimationProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.animationProgress = max(0.0, min(1.0, progress))
        }
    }
    
    // MARK: - Cleanup
    deinit {
        animationTimers.forEach { $0.invalidate() }
        try? engine?.stop()
    }
}

// MARK: - Enums
enum AnimationType: String, CaseIterable {
    case chart = "chart"
    case trade = "trade"
    case order = "order"
    case success = "success"
    case error = "error"
    case loading = "loading"
    case particle = "particle"
    case priceChange = "price_change"
    
    var displayName: String {
        switch self {
        case .chart: return "График"
        case .trade: return "Сделка"
        case .order: return "Ордер"
        case .success: return "Успех"
        case .error: return "Ошибка"
        case .loading: return "Загрузка"
        case .particle: return "Частицы"
        case .priceChange: return "Изменение цены"
        }
    }
}

enum HapticStyle: String, CaseIterable {
    case light = "light"
    case medium = "medium"
    case heavy = "heavy"
    case success = "success"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .light: return "Легкий"
        case .medium: return "Средний"
        case .heavy: return "Сильный"
        case .success: return "Успех"
        case .error: return "Ошибка"
        }
    }
}

// MARK: - View Extensions
extension View {
    func enhancedAnimation(_ animation: AnimationType, delay: Double = 0.0) -> some View {
        let service = EnhancedAnimationService.shared
        
        return self
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    service.startAnimation(animation)
                }
            }
            .onDisappear {
                service.stopAnimation()
            }
    }
    
    func hapticFeedback(_ style: HapticStyle) -> some View {
        return self
            .onTapGesture {
                EnhancedAnimationService.shared.triggerHapticFeedback(style)
            }
    }
}

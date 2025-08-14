import Foundation
import SwiftUI
import Combine

class AdvancedAnimationService: ObservableObject {
    static let shared = AdvancedAnimationService()
    
    // MARK: - Published Properties
    @Published var isAnimating = false
    @Published var currentAnimation: AnimationType = .none
    @Published var particleCount = 0
    @Published var animationSpeed: Double = 1.0
    
    // MARK: - Private Properties
    private let loggingService = LoggingService.shared
    private var cancellables = Set<AnyCancellable>()
    private var animationTimer: Timer?
    
    // MARK: - Animation Types
    enum AnimationType: String, CaseIterable {
        case none = "none"
        case priceUp = "price_up"
        case priceDown = "price_down"
        case tradeSuccess = "trade_success"
        case tradeError = "trade_error"
        case chartUpdate = "chart_update"
        case loading = "loading"
        case celebration = "celebration"
        case warning = "warning"
        case success = "success"
        
        var displayName: String {
            switch self {
            case .none: return "Нет"
            case .priceUp: return "Рост цены"
            case .priceDown: return "Падение цены"
            case .tradeSuccess: return "Успешная сделка"
            case .tradeError: return "Ошибка сделки"
            case .chartUpdate: return "Обновление графика"
            case .loading: return "Загрузка"
            case .celebration: return "Празднование"
            case .warning: return "Предупреждение"
            case .success: return "Успех"
            }
        }
        
        var color: Color {
            switch self {
            case .none: return .clear
            case .priceUp: return .green
            case .priceDown: return .red
            case .tradeSuccess: return .green
            case .tradeError: return .red
            case .chartUpdate: return .blue
            case .loading: return .orange
            case .celebration: return .yellow
            case .warning: return .orange
            case .success: return .green
            }
        }
    }
    
    private init() {
        setupService()
    }
    
    // MARK: - Setup
    private func setupService() {
        // Setup animation speed changes
        $animationSpeed
            .sink { [weak self] speed in
                self?.updateAnimationSpeed(speed)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func startAnimation(_ type: AnimationType, duration: TimeInterval = 2.0) {
        guard type != .none else { return }
        
        currentAnimation = type
        isAnimating = true
        
        loggingService.info("Animation started", category: "animations", metadata: [
            "type": type.rawValue,
            "duration": duration
        ])
        
        // Start specific animation
        switch type {
        case .priceUp:
            startPriceUpAnimation(duration: duration)
        case .priceDown:
            startPriceDownAnimation(duration: duration)
        case .tradeSuccess:
            startTradeSuccessAnimation(duration: duration)
        case .tradeError:
            startTradeErrorAnimation(duration: duration)
        case .chartUpdate:
            startChartUpdateAnimation(duration: duration)
        case .loading:
            startLoadingAnimation(duration: duration)
        case .celebration:
            startCelebrationAnimation(duration: duration)
        case .warning:
            startWarningAnimation(duration: duration)
        case .success:
            startSuccessAnimation(duration: duration)
        case .none:
            break
        }
        
        // Auto-stop animation after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopAnimation()
        }
    }
    
    func stopAnimation() {
        isAnimating = false
        currentAnimation = .none
        particleCount = 0
        
        // Stop any running timers
        animationTimer?.invalidate()
        animationTimer = nil
        
        loggingService.info("Animation stopped", category: "animations")
    }
    
    func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
        
        loggingService.debug("Haptic feedback triggered", category: "animations", metadata: [
            "style": style.rawValue
        ])
    }
    
    // MARK: - Specific Animations
    private func startPriceUpAnimation(duration: TimeInterval) {
        // Green particles moving upward
        particleCount = 50
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.particleCount = max(0, (self?.particleCount ?? 0) - 2)
        }
        
        // Haptic feedback
        triggerHapticFeedback(.light)
    }
    
    private func startPriceDownAnimation(duration: TimeInterval) {
        // Red particles moving downward
        particleCount = 50
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.particleCount = max(0, (self?.particleCount ?? 0) - 2)
        }
        
        // Haptic feedback
        triggerHapticFeedback(.medium)
    }
    
    private func startTradeSuccessAnimation(duration: TimeInterval) {
        // Celebration particles
        particleCount = 100
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.particleCount = max(0, (self?.particleCount ?? 0) - 3)
        }
        
        // Haptic feedback
        triggerHapticFeedback(.heavy)
    }
    
    private func startTradeErrorAnimation(duration: TimeInterval) {
        // Error shake effect
        particleCount = 30
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.particleCount = max(0, (self?.particleCount ?? 0) - 1)
        }
        
        // Haptic feedback
        triggerHapticFeedback(.rigid)
    }
    
    private func startChartUpdateAnimation(duration: TimeInterval) {
        // Smooth chart update effect
        particleCount = 20
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.particleCount = max(0, (self?.particleCount ?? 0) - 1)
        }
    }
    
    private func startLoadingAnimation(duration: TimeInterval) {
        // Continuous loading animation
        particleCount = 10
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.particleCount = self.particleCount == 10 ? 20 : 10
        }
    }
    
    private func startCelebrationAnimation(duration: TimeInterval) {
        // Fireworks effect
        particleCount = 200
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            self?.particleCount = max(0, (self?.particleCount ?? 0) - 5)
        }
        
        // Haptic feedback
        triggerHapticFeedback(.heavy)
    }
    
    private func startWarningAnimation(duration: TimeInterval) {
        // Warning pulse effect
        particleCount = 40
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.particleCount = self.particleCount == 40 ? 60 : 40
        }
        
        // Haptic feedback
        triggerHapticFeedback(.medium)
    }
    
    private func startSuccessAnimation(duration: TimeInterval) {
        // Success ripple effect
        particleCount = 80
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            self?.particleCount = max(0, (self?.particleCount ?? 0) - 2)
        }
        
        // Haptic feedback
        triggerHapticFeedback(.light)
    }
    
    // MARK: - Chart Animations
    func animateChartUpdate<T: View>(_ view: T, delay: TimeInterval = 0.0) -> some View {
        view
            .scaleEffect(isAnimating && currentAnimation == .chartUpdate ? 1.02 : 1.0)
            .opacity(isAnimating && currentAnimation == .chartUpdate ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.3).delay(delay), value: isAnimating)
    }
    
    func animatePriceChange<T: View>(_ view: T, isPositive: Bool) -> some View {
        let animationType: AnimationType = isPositive ? .priceUp : .priceDown
        
        return view
            .scaleEffect(isAnimating && currentAnimation == animationType ? 1.1 : 1.0)
            .foregroundColor(isAnimating && currentAnimation == animationType ? animationType.color : .primary)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAnimating)
    }
    
    // MARK: - Particle Effects
    func createParticleEffect<T: View>(_ view: T) -> some View {
        view
            .overlay(
                ZStack {
                    ForEach(0..<min(particleCount, 50), id: \.self) { index in
                        Circle()
                            .fill(currentAnimation.color)
                            .frame(width: 4, height: 4)
                            .offset(
                                x: CGFloat.random(in: -100...100),
                                y: CGFloat.random(in: -100...100)
                            )
                            .opacity(Double.random(in: 0.3...1.0))
                            .animation(
                                .easeOut(duration: 1.0)
                                .repeatCount(1, autoreverses: false),
                                value: particleCount
                            )
                    }
                }
            )
    }
    
    // MARK: - Loading Animations
    func createLoadingSpinner() -> some View {
        ZStack {
            Circle()
                .stroke(currentAnimation.color.opacity(0.3), lineWidth: 4)
                .frame(width: 40, height: 40)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(currentAnimation.color, lineWidth: 4)
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1.0)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
    }
    
    func createPulseEffect<T: View>(_ view: T) -> some View {
        view
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .opacity(isAnimating ? 0.7 : 1.0)
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
    }
    
    // MARK: - Trade Animations
    func animateTradeSuccess<T: View>(_ view: T) -> some View {
        view
            .scaleEffect(isAnimating && currentAnimation == .tradeSuccess ? 1.05 : 1.0)
            .rotationEffect(.degrees(isAnimating && currentAnimation == .tradeSuccess ? 2 : 0))
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isAnimating)
    }
    
    func animateTradeError<T: View>(_ view: T) -> some View {
        view
            .offset(x: isAnimating && currentAnimation == .tradeError ? 10 : 0)
            .animation(
                .easeInOut(duration: 0.1)
                .repeatCount(3, autoreverses: true),
                value: isAnimating
            )
    }
    
    // MARK: - Chart Specific Animations
    func animateChartLine<T: View>(_ view: T, isNewData: Bool) -> some View {
        view
            .opacity(isNewData ? 0.0 : 1.0)
            .animation(.easeInOut(duration: 0.5), value: isNewData)
    }
    
    func animateChartBar<T: View>(_ view: T, value: Double, maxValue: Double) -> some View {
        let normalizedValue = value / maxValue
        
        return view
            .scaleEffect(y: isAnimating ? normalizedValue : 0.0, anchor: .bottom)
            .animation(.easeOut(duration: 0.8), value: isAnimating)
    }
    
    // MARK: - Private Methods
    private func updateAnimationSpeed(_ speed: Double) {
        // Update animation timers with new speed
        if let timer = animationTimer {
            timer.invalidate()
            
            let newInterval = timer.timeInterval / speed
            animationTimer = Timer.scheduledTimer(withTimeInterval: newInterval, repeats: true) { [weak self] _ in
                // Recreate timer with new interval
                self?.updateParticleCount()
            }
        }
    }
    
    private func updateParticleCount() {
        guard isAnimating else { return }
        
        switch currentAnimation {
        case .priceUp, .priceDown:
            particleCount = max(0, particleCount - 2)
        case .tradeSuccess:
            particleCount = max(0, particleCount - 3)
        case .tradeError:
            particleCount = max(0, particleCount - 1)
        case .chartUpdate:
            particleCount = max(0, particleCount - 1)
        case .loading:
            particleCount = particleCount == 10 ? 20 : 10
        case .celebration:
            particleCount = max(0, particleCount - 5)
        case .warning:
            particleCount = particleCount == 40 ? 60 : 40
        case .success:
            particleCount = max(0, particleCount - 2)
        case .none:
            break
        }
    }
    
    // MARK: - Utility Methods
    func getAnimationDescription() -> String {
        return "Текущая анимация: \(currentAnimation.displayName), Частицы: \(particleCount), Скорость: \(String(format: "%.1fx", animationSpeed))"
    }
    
    func resetAnimations() {
        stopAnimation()
        animationSpeed = 1.0
        
        loggingService.info("Animations reset", category: "animations")
    }
}

// MARK: - Animation Modifiers
struct AnimatedChartModifier: ViewModifier {
    @ObservedObject var animationService: AdvancedAnimationService
    let animationType: AdvancedAnimationService.AnimationType
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(animationService.isAnimating && animationService.currentAnimation == animationType ? 1.02 : 1.0)
            .opacity(animationService.isAnimating && animationService.currentAnimation == animationType ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: animationService.isAnimating)
    }
}

struct ParticleEffectModifier: ViewModifier {
    @ObservedObject var animationService: AdvancedAnimationService
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    ForEach(0..<min(animationService.particleCount, 50), id: \.self) { index in
                        Circle()
                            .fill(animationService.currentAnimation.color)
                            .frame(width: 4, height: 4)
                            .offset(
                                x: CGFloat.random(in: -100...100),
                                y: CGFloat.random(in: -100...100)
                            )
                            .opacity(Double.random(in: 0.3...1.0))
                            .animation(
                                .easeOut(duration: 1.0)
                                .repeatCount(1, autoreverses: false),
                                value: animationService.particleCount
                            )
                    }
                }
            )
    }
}

// MARK: - View Extensions
extension View {
    func animatedChart(_ animationService: AdvancedAnimationService, type: AdvancedAnimationService.AnimationType) -> some View {
        self.modifier(AnimatedChartModifier(animationService: animationService, animationType: type))
    }
    
    func particleEffect(_ animationService: AdvancedAnimationService) -> some View {
        self.modifier(ParticleEffectModifier(animationService: animationService))
    }
}

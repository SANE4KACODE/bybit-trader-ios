import Foundation
import SwiftUI
import Combine

class AnimationService: ObservableObject {
    static let shared = AnimationService()
    
    // MARK: - Published Properties
    @Published var isAnimationsEnabled = true
    @Published var animationSpeed: AnimationSpeed = .normal
    @Published var particleEffectsEnabled = true
    @Published var hapticFeedbackEnabled = true
    @Published var customAnimations: [CustomAnimation] = []
    @Published var currentTheme: AnimationTheme = .default
    @Published var isPerformingAnimation = false
    
    // MARK: - Private Properties
    private let loggingService = LoggingService.shared
    private var cancellables = Set<AnyCancellable>()
    private var animationQueue: [AnimationTask] = []
    private var isProcessingQueue = false
    
    // MARK: - Constants
    private let defaultAnimationDuration: Double = 0.3
    private let maxParticleCount = 100
    private let maxAnimationQueueSize = 50
    
    private init() {
        loadAnimationSettings()
        setupAnimationQueue()
    }
    
    // MARK: - Setup
    private func loadAnimationSettings() {
        isAnimationsEnabled = UserDefaults.standard.bool(forKey: "animationsEnabled")
        if !UserDefaults.standard.bool(forKey: "animationsSettingsLoaded") {
            isAnimationsEnabled = true
            UserDefaults.standard.set(true, forKey: "animationsEnabled")
            UserDefaults.standard.set(true, forKey: "animationsSettingsLoaded")
        }
        
        animationSpeed = AnimationSpeed(rawValue: UserDefaults.standard.string(forKey: "animationSpeed") ?? "normal") ?? .normal
        particleEffectsEnabled = UserDefaults.standard.bool(forKey: "particleEffectsEnabled")
        hapticFeedbackEnabled = UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
        
        if !UserDefaults.standard.bool(forKey: "particleEffectsSettingsLoaded") {
            particleEffectsEnabled = true
            hapticFeedbackEnabled = true
            UserDefaults.standard.set(true, forKey: "particleEffectsEnabled")
            UserDefaults.standard.set(true, forKey: "hapticFeedbackEnabled")
            UserDefaults.standard.set(true, forKey: "particleEffectsSettingsLoaded")
        }
    }
    
    private func setupAnimationQueue() {
        // Process animation queue every 16ms (60 FPS)
        Timer.publish(every: 1.0/60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.processAnimationQueue()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func animate<T: View>(_ view: T, animation: AnimationType, delay: Double = 0) -> some View {
        guard isAnimationsEnabled else { return AnyView(view) }
        
        let task = AnimationTask(
            id: UUID(),
            animation: animation,
            delay: delay,
            timestamp: Date()
        )
        
        addToAnimationQueue(task)
        
        return AnyView(
            view.modifier(AnimationModifier(animation: animation, service: self))
        )
    }
    
    func performHapticFeedback(_ type: HapticFeedbackType) {
        guard hapticFeedbackEnabled else { return }
        
        let impactFeedbackGenerator: UIImpactFeedbackGenerator
        
        switch type {
        case .light:
            impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        case .medium:
            impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:
            impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        case .rigid:
            impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
        case .soft:
            impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
        }
        
        impactFeedbackGenerator.impactOccurred()
        
        loggingService.debug("Haptic feedback performed", category: "animations", metadata: [
            "type": type.rawValue
        ])
    }
    
    func createParticleEffect(at position: CGPoint, count: Int = 20) -> [Particle] {
        guard particleEffectsEnabled else { return [] }
        
        let actualCount = min(count, maxParticleCount)
        var particles: [Particle] = []
        
        for _ in 0..<actualCount {
            let particle = Particle(
                position: position,
                velocity: CGVector(
                    dx: Double.random(in: -100...100),
                    dy: Double.random(in: -100...100)
                ),
                color: getRandomColor(),
                size: Double.random(in: 2...8),
                life: Double.random(in: 0.5...2.0),
                type: ParticleType.allCases.randomElement() ?? .circle
            )
            particles.append(particle)
        }
        
        loggingService.debug("Particle effect created", category: "animations", metadata: [
            "position": "\(position.x), \(position.y)",
            "count": actualCount
        ])
        
        return particles
    }
    
    func createConfettiEffect(at position: CGPoint) -> [ConfettiPiece] {
        guard particleEffectsEnabled else { return [] }
        
        var confetti: [ConfettiPiece] = []
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        
        for _ in 0..<30 {
            let piece = ConfettiPiece(
                position: position,
                velocity: CGVector(
                    dx: Double.random(in: -150...150),
                    dy: Double.random(in: -200...(-50))
                ),
                color: colors.randomElement() ?? .blue,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -720...720),
                size: CGSize(
                    width: Double.random(in: 4...12),
                    height: Double.random(in: 4...12)
                )
            )
            confetti.append(piece)
        }
        
        return confetti
    }
    
    func createRippleEffect(at position: CGPoint) -> RippleEffect {
        return RippleEffect(
            center: position,
            startRadius: 0,
            endRadius: 100,
            duration: 1.0,
            color: .blue.opacity(0.3)
        )
    }
    
    func createWaveEffect() -> WaveEffect {
        return WaveEffect(
            amplitude: 20,
            frequency: 2,
            phase: 0,
            duration: 2.0
        )
    }
    
    func createShimmerEffect() -> ShimmerEffect {
        return ShimmerEffect(
            gradient: LinearGradient(
                colors: [.clear, .white.opacity(0.6), .clear],
                startPoint: .leading,
                endPoint: .trailing
            ),
            duration: 1.5
        )
    }
    
    func createBounceEffect() -> BounceEffect {
        return BounceEffect(
            scale: 1.2,
            duration: 0.3,
            damping: 0.6
        )
    }
    
    func createPulseEffect() -> PulseEffect {
        return PulseEffect(
            scale: 1.1,
            duration: 1.0,
            repeatCount: .infinity
        )
    }
    
    func createShakeEffect() -> ShakeEffect {
        return ShakeEffect(
            intensity: 10,
            duration: 0.5,
            repeatCount: 3
        )
    }
    
    func createFlipEffect() -> FlipEffect {
        return FlipEffect(
            axis: .horizontal,
            duration: 0.6,
            perspective: 0.5
        )
    }
    
    func createMorphingEffect() -> MorphingEffect {
        return MorphingEffect(
            fromShape: .circle,
            toShape: .square,
            duration: 1.0
        )
    }
    
    func createLiquidEffect() -> LiquidEffect {
        return LiquidEffect(
            viscosity: 0.8,
            tension: 0.3,
            duration: 2.0
        )
    }
    
    func createFireworkEffect(at position: CGPoint) -> [FireworkParticle] {
        guard particleEffectsEnabled else { return [] }
        
        var fireworks: [FireworkParticle] = []
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .white]
        
        for _ in 0..<50 {
            let angle = Double.random(in: 0...2 * .pi)
            let speed = Double.random(in: 100...300)
            
            let firework = FireworkParticle(
                position: position,
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed
                ),
                color: colors.randomElement() ?? .white,
                size: Double.random(in: 3...10),
                life: Double.random(in: 1.0...3.0),
                trailLength: Int.random(in: 5...15)
            )
            fireworks.append(firework)
        }
        
        return fireworks
    }
    
    func createMagneticEffect() -> MagneticEffect {
        return MagneticEffect(
            strength: 0.8,
            range: 100,
            duration: 0.3
        )
    }
    
    func createElasticEffect() -> ElasticEffect {
        return ElasticEffect(
            stiffness: 100,
            damping: 10,
            mass: 1.0
        )
    }
    
    func createSpringEffect() -> SpringEffect {
        return SpringEffect(
            response: 0.5,
            dampingFraction: 0.8,
            blendDuration: 0.1
        )
    }
    
    func createCustomAnimation(name: String, duration: Double, curve: AnimationCurve, properties: [String: Any]) -> CustomAnimation {
        let animation = CustomAnimation(
            name: name,
            duration: duration,
            curve: curve,
            properties: properties,
            createdAt: Date()
        )
        
        customAnimations.append(animation)
        
        loggingService.info("Custom animation created", category: "animations", metadata: [
            "name": name,
            "duration": duration,
            "curve": curve.rawValue
        ])
        
        return animation
    }
    
    func updateAnimationSettings(
        enabled: Bool? = nil,
        speed: AnimationSpeed? = nil,
        particles: Bool? = nil,
        haptics: Bool? = nil
    ) {
        if let enabled = enabled {
            isAnimationsEnabled = enabled
            UserDefaults.standard.set(enabled, forKey: "animationsEnabled")
        }
        
        if let speed = speed {
            animationSpeed = speed
            UserDefaults.standard.set(speed.rawValue, forKey: "animationSpeed")
        }
        
        if let particles = particles {
            particleEffectsEnabled = particles
            UserDefaults.standard.set(particles, forKey: "particleEffectsEnabled")
        }
        
        if let haptics = haptics {
            hapticFeedbackEnabled = haptics
            UserDefaults.standard.set(haptics, forKey: "hapticFeedbackEnabled")
        }
        
        loggingService.info("Animation settings updated", category: "animations", metadata: [
            "enabled": isAnimationsEnabled,
            "speed": animationSpeed.rawValue,
            "particles": particleEffectsEnabled,
            "haptics": hapticFeedbackEnabled
        ])
    }
    
    func getAnimationPerformance() -> AnimationPerformance {
        let queueSize = animationQueue.count
        let isQueueOverloaded = queueSize > maxAnimationQueueSize
        let averageProcessingTime = calculateAverageProcessingTime()
        
        return AnimationPerformance(
            queueSize: queueSize,
            isOverloaded: isQueueOverloaded,
            averageProcessingTime: averageProcessingTime,
            totalAnimations: customAnimations.count,
            timestamp: Date()
        )
    }
    
    // MARK: - Private Methods
    private func addToAnimationQueue(_ task: AnimationTask) {
        guard animationQueue.count < maxAnimationQueueSize else {
            loggingService.warning("Animation queue is full", category: "animations", metadata: [
                "queueSize": animationQueue.count,
                "maxSize": maxAnimationQueueSize
            ])
            return
        }
        
        animationQueue.append(task)
    }
    
    private func processAnimationQueue() {
        guard !isProcessingQueue && !animationQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        let currentTime = Date()
        let readyTasks = animationQueue.filter { task in
            currentTime.timeIntervalSince(task.timestamp) >= task.delay
        }
        
        for task in readyTasks {
            executeAnimation(task)
            animationQueue.removeAll { $0.id == task.id }
        }
        
        isProcessingQueue = false
    }
    
    private func executeAnimation(_ task: AnimationTask) {
        isPerformingAnimation = true
        
        // Execute the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + task.delay) {
            self.isPerformingAnimation = false
            
            self.loggingService.debug("Animation executed", category: "animations", metadata: [
                "type": task.animation.rawValue,
                "delay": task.delay
            ])
        }
    }
    
    private func getRandomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan, .mint, .indigo]
        return colors.randomElement() ?? .blue
    }
    
    private func calculateAverageProcessingTime() -> Double {
        // Simplified calculation - would track actual processing times in production
        return 0.016 // 16ms (60 FPS)
    }
}

// MARK: - Models
enum AnimationType: String, CaseIterable {
    case fade = "fade"
    case slide = "slide"
    case scale = "scale"
    case rotate = "rotate"
    case bounce = "bounce"
    case pulse = "pulse"
    case shake = "shake"
    case flip = "flip"
    case morph = "morph"
    case liquid = "liquid"
    case magnetic = "magnetic"
    case elastic = "elastic"
    case spring = "spring"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .fade: return "Появление"
        case .slide: return "Скольжение"
        case .scale: return "Масштабирование"
        case .rotate: return "Вращение"
        case .bounce: return "Отскок"
        case .pulse: return "Пульсация"
        case .shake: return "Тряска"
        case .flip: return "Переворот"
        case .morph: return "Морфинг"
        case .liquid: return "Жидкость"
        case .magnetic: return "Магнитный"
        case .elastic: return "Эластичный"
        case .spring: return "Пружина"
        case .custom: return "Пользовательский"
        }
    }
}

enum AnimationSpeed: String, CaseIterable {
    case slow = "slow"
    case normal = "normal"
    case fast = "fast"
    case instant = "instant"
    
    var multiplier: Double {
        switch self {
        case .slow: return 2.0
        case .normal: return 1.0
        case .fast: return 0.5
        case .instant: return 0.0
        }
    }
    
    var displayName: String {
        switch self {
        case .slow: return "Медленно"
        case .normal: return "Нормально"
        case .fast: return "Быстро"
        case .instant: return "Мгновенно"
        }
    }
}

enum AnimationTheme: String, CaseIterable {
    case `default` = "default"
    case smooth = "smooth"
    case bouncy = "bouncy"
    case dramatic = "dramatic"
    case subtle = "subtle"
    
    var displayName: String {
        switch self {
        case .default: return "По умолчанию"
        case .smooth: return "Плавно"
        case .bouncy: return "Пружинисто"
        case .dramatic: return "Драматично"
        case .subtle: return "Тонко"
        }
    }
}

enum HapticFeedbackType: String, CaseIterable {
    case light = "light"
    case medium = "medium"
    case heavy = "heavy"
    case rigid = "rigid"
    case soft = "soft"
}

enum AnimationCurve: String, CaseIterable {
    case linear = "linear"
    case easeIn = "easeIn"
    case easeOut = "easeOut"
    case easeInOut = "easeInOut"
    case spring = "spring"
    case bounce = "bounce"
    case elastic = "elastic"
}

enum ParticleType: String, CaseIterable {
    case circle = "circle"
    case square = "square"
    case triangle = "triangle"
    case star = "star"
    case diamond = "diamond"
}

struct AnimationTask: Identifiable {
    let id: UUID
    let animation: AnimationType
    let delay: Double
    let timestamp: Date
}

struct CustomAnimation: Identifiable, Codable {
    let id = UUID()
    let name: String
    let duration: Double
    let curve: AnimationCurve
    let properties: [String: Any]
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case name, duration, curve, createdAt
    }
    
    init(name: String, duration: Double, curve: AnimationCurve, properties: [String: Any], createdAt: Date) {
        self.name = name
        self.duration = duration
        self.curve = curve
        self.properties = properties
        self.createdAt = createdAt
    }
}

struct AnimationPerformance {
    let queueSize: Int
    let isOverloaded: Bool
    let averageProcessingTime: Double
    let totalAnimations: Int
    let timestamp: Date
}

// MARK: - Animation Effects
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    let color: Color
    let size: Double
    var life: Double
    let type: ParticleType
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    let color: Color
    var rotation: Double
    var rotationSpeed: Double
    let size: CGSize
}

struct RippleEffect {
    let center: CGPoint
    var startRadius: Double
    let endRadius: Double
    let duration: Double
    let color: Color
}

struct WaveEffect {
    let amplitude: Double
    let frequency: Double
    var phase: Double
    let duration: Double
}

struct ShimmerEffect {
    let gradient: LinearGradient
    let duration: Double
}

struct BounceEffect {
    let scale: Double
    let duration: Double
    let damping: Double
}

struct PulseEffect {
    let scale: Double
    let duration: Double
    let repeatCount: RepeatMode
}

struct ShakeEffect {
    let intensity: Double
    let duration: Double
    let repeatCount: Int
}

struct FlipEffect {
    let axis: FlipAxis
    let duration: Double
    let perspective: Double
}

struct MorphingEffect {
    let fromShape: MorphingShape
    let toShape: MorphingShape
    let duration: Double
}

struct LiquidEffect {
    let viscosity: Double
    let tension: Double
    let duration: Double
}

struct FireworkParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    let color: Color
    let size: Double
    var life: Double
    let trailLength: Int
}

struct MagneticEffect {
    let strength: Double
    let range: Double
    let duration: Double
}

struct ElasticEffect {
    let stiffness: Double
    let damping: Double
    let mass: Double
}

struct SpringEffect {
    let response: Double
    let dampingFraction: Double
    let blendDuration: Double
}

// MARK: - Supporting Types
enum RepeatMode {
    case once
    case times(Int)
    case infinity
}

enum FlipAxis {
    case horizontal
    case vertical
}

enum MorphingShape {
    case circle
    case square
    case triangle
    case star
}

// MARK: - Animation Modifier
struct AnimationModifier: ViewModifier {
    let animation: AnimationType
    let service: AnimationService
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Apply animation when view appears
            }
    }
}

import SwiftUI

struct AnimatedCardsView: View {
    @State private var animateCards = false
    @State private var selectedCard: Int? = nil
    @State private var showGlow = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Анимированный заголовок
                AnimatedTitle()
                
                // Карточки с анимациями
                LazyVStack(spacing: 16) {
                    ForEach(0..<5) { index in
                        AnimatedCard(
                            index: index,
                            isSelected: selectedCard == index,
                            animateCards: animateCards
                        ) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedCard = selectedCard == index ? nil : index
                            }
                        }
                    }
                }
                
                // Анимированные кнопки
                AnimatedButtons()
                
                // Эффект частиц
                ParticleEffect()
            }
            .padding()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8)) {
            animateCards = true
        }
        
        // Запускаем пульсацию свечения
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            showGlow = true
        }
    }
}

struct AnimatedTitle: View {
    @State private var showTitle = false
    @State private var titleOffset: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 8) {
            Text("🚀 Bybit Trader")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple, .orange]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .scaleEffect(showTitle ? 1.0 : 0.5)
                .offset(y: titleOffset)
                .opacity(showTitle ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showTitle)
            
            Text("Крутые анимации и графики")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .opacity(showTitle ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.8).delay(0.3), value: showTitle)
        }
        .onAppear {
            showTitle = true
            titleOffset = 0
        }
    }
}

struct AnimatedCard: View {
    let index: Int
    let isSelected: Bool
    let animateCards: Bool
    let onTap: () -> Void
    
    @State private var cardOffset: CGFloat = 1000
    @State private var cardRotation: Double = 0
    @State private var cardScale: CGFloat = 0.8
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Иконка с анимацией
                Image(systemName: cardIcons[index])
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: cardColors[index]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(cardRotation))
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSelected)
                
                // Заголовок
                Text(cardTitles[index])
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Описание
                Text(cardDescriptions[index])
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Индикатор
                Circle()
                    .fill(cardColors[index].first ?? .blue)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isSelected ? 1.5 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: cardColors[index]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
                    .shadow(
                        color: (cardColors[index].first ?? .blue).opacity(isSelected ? 0.5 : 0.2),
                        radius: isSelected ? 20 : 10,
                        x: 0,
                        y: isSelected ? 10 : 5
                    )
            )
            .scaleEffect(cardScale)
            .offset(x: cardOffset)
            .rotation3DEffect(
                .degrees(cardRotation),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(Double(index) * 0.1)) {
                cardOffset = 0
                cardScale = 1.0
            }
        }
        .onChange(of: animateCards) { _ in
            if animateCards {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    cardRotation = 5
                }
            }
        }
    }
    
    private var cardIcons: [String] {
        ["chart.line.uptrend.xyaxis", "dollarsign.circle", "list.bullet.rectangle", "gearshape", "doc.text"]
    }
    
    private var cardTitles: [String] {
        ["Торговля", "Баланс", "Позиции", "Настройки", "История"]
    }
    
    private var cardDescriptions: [String] {
        ["Размещайте ордера и следите за рынком", "Управляйте своим портфелем", "Отслеживайте открытые позиции", "Настройте приложение под себя", "Просматривайте историю операций"]
    }
    
    private var cardColors: [[Color]] {
        [
            [.blue, .purple],
            [.green, .teal],
            [.orange, .red],
            [.purple, .pink],
            [.indigo, .blue]
        ]
    }
}

struct AnimatedButtons: View {
    @State private var showButtons = false
    @State private var buttonScale: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Действия")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                AnimatedButton(
                    title: "Обновить",
                    icon: "arrow.clockwise",
                    color: .blue,
                    delay: 0.0
                )
                
                AnimatedButton(
                    title: "Настройки",
                    icon: "gearshape",
                    color: .purple,
                    delay: 0.1
                )
                
                AnimatedButton(
                    title: "Помощь",
                    icon: "questionmark.circle",
                    color: .orange,
                    delay: 0.2
                )
            }
        }
        .opacity(showButtons ? 1.0 : 0.0)
        .scaleEffect(buttonScale)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5)) {
                showButtons = true
                buttonScale = 1.0
            }
        }
    }
}

struct AnimatedButton: View {
    let title: String
    let icon: String
    let color: Color
    let delay: Double
    
    @State private var showButton = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 5)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .rotationEffect(.degrees(showButton ? 0 : 180))
            .opacity(showButton ? 1.0 : 0.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(delay)) {
                showButton = true
            }
        }
    }
}

struct ParticleEffect: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .frame(height: 100)
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        for _ in 0..<20 {
            let particle = Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...100)
                ),
                color: [.blue, .purple, .orange, .green, .red].randomElement() ?? .blue,
                size: CGFloat.random(in: 2...6)
            )
            particles.append(particle)
        }
    }
    
    private func animateParticles() {
        for index in particles.indices {
            withAnimation(.easeInOut(duration: Double.random(in: 2...4)).repeatForever(autoreverses: true)) {
                particles[index].position.y += 50
                particles[index].opacity = 0.3
                particles[index].scale = 0.5
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double = 1.0
    var scale: CGFloat = 1.0
}

#Preview {
    AnimatedCardsView()
}

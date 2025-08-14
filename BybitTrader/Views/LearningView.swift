import SwiftUI

struct LearningView: View {
    @State private var selectedCategory: LearningCategory = .basics
    @State private var showArticle = false
    @State private var selectedArticle: Article?
    @State private var progress: [String: Double] = [:]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Заголовок с прогрессом
                    LearningHeader(progress: overallProgress)
                    
                    // Категории обучения
                    CategorySelector(selectedCategory: $selectedCategory)
                    
                    // Курсы по выбранной категории
                    CoursesSection(category: selectedCategory, progress: $progress)
                    
                    // Статьи и новости
                    ArticlesSection(selectedArticle: $selectedArticle, showArticle: $showArticle)
                    
                    // Интерактивные тесты
                    QuizSection()
                }
                .padding()
            }
            .navigationTitle("Обучение")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showArticle) {
            if let article = selectedArticle {
                ArticleDetailView(article: article)
            }
        }
        .onAppear {
            loadProgress()
        }
    }
    
    private var overallProgress: Double {
        let total = progress.values.reduce(0, +)
        let count = Double(progress.count)
        return count > 0 ? total / count : 0
    }
    
    private func loadProgress() {
        // Загружаем прогресс из UserDefaults
        if let data = UserDefaults.standard.data(forKey: "learningProgress"),
           let savedProgress = try? JSONDecoder().decode([String: Double].self, from: data) {
            progress = savedProgress
        }
    }
}

struct LearningHeader: View {
    let progress: Double
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ваш прогресс")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Продолжайте обучение!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: animateProgress ? progress : 0)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.5), value: animateProgress)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            // Прогресс-бар
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            animateProgress = true
        }
    }
}

struct CategorySelector: View {
    @Binding var selectedCategory: LearningCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LearningCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryChip: View {
    let category: LearningCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CoursesSection: View {
    let category: LearningCategory
    @Binding var progress: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Курсы: \(category.displayName)")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                ForEach(category.courses) { course in
                    CourseCard(
                        course: course,
                        progress: progress[course.id] ?? 0
                    ) {
                        // Начинаем курс
                        startCourse(course)
                    }
                }
            }
        }
    }
    
    private func startCourse(_ course: Course) {
        // Логика начала курса
        print("Начинаем курс: \(course.title)")
    }
}

struct CourseCard: View {
    let course: Course
    let progress: Double
    let action: () -> Void
    
    @State private var showCard = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Иконка курса
                ZStack {
                    Circle()
                        .fill(course.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: course.icon)
                        .font(.title2)
                        .foregroundColor(course.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(course.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Прогресс курса
                    HStack {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: course.color))
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(course.color)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
            )
            .scaleEffect(showCard ? 1.0 : 0.95)
            .opacity(showCard ? 1.0 : 0.8)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                showCard = true
            }
        }
    }
}

struct ArticlesSection: View {
    @Binding var selectedArticle: Article?
    @Binding var showArticle: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Статьи и новости")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                ForEach(Article.sampleArticles) { article in
                    ArticleCard(article: article) {
                        selectedArticle = article
                        showArticle = true
                    }
                }
            }
        }
    }
}

struct ArticleCard: View {
    let article: Article
    let action: () -> Void
    
    @State private var showCard = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(article.category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(article.categoryColor)
                        )
                    
                    Spacer()
                    
                    Text(article.readTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(article.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(article.excerpt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    Text(article.author)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(article.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
            )
            .scaleEffect(showCard ? 1.0 : 0.95)
            .opacity(showCard ? 1.0 : 0.8)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                showCard = true
            }
        }
    }
}

struct QuizSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Проверьте знания")
                .font(.headline)
                .foregroundColor(.primary)
            
            Button(action: {
                // Запускаем тест
            }) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Пройти тест")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Проверьте свои знания криптотрейдинга")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Models
enum LearningCategory: String, CaseIterable {
    case basics = "basics"
    case trading = "trading"
    case analysis = "analysis"
    case risk = "risk"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .basics: return "Основы"
        case .trading: return "Торговля"
        case .analysis: return "Анализ"
        case .risk: return "Риски"
        case .advanced: return "Продвинутое"
        }
    }
    
    var icon: String {
        switch self {
        case .basics: return "book.fill"
        case .trading: return "chart.line.uptrend.xyaxis"
        case .analysis: return "magnifyingglass"
        case .risk: return "exclamationmark.triangle.fill"
        case .advanced: return "star.fill"
        }
    }
    
    var courses: [Course] {
        switch self {
        case .basics:
            return [
                Course(id: "crypto_basics", title: "Основы криптовалют", description: "Изучите основы блокчейна и криптовалют", icon: "bitcoinsign", color: .orange, duration: "2 часа"),
                Course(id: "wallet_security", title: "Безопасность кошельков", description: "Как защитить свои криптоактивы", icon: "lock.shield", color: .red, duration: "1.5 часа")
            ]
        case .trading:
            return [
                Course(id: "order_types", title: "Типы ордеров", description: "Рыночные, лимитные и стоп-ордера", icon: "list.bullet", color: .blue, duration: "2.5 часа"),
                Course(id: "risk_management", title: "Управление рисками", description: "Стратегии минимизации потерь", icon: "chart.bar", color: .green, duration: "3 часа")
            ]
        case .analysis:
            return [
                Course(id: "technical_analysis", title: "Технический анализ", description: "Графики, индикаторы и паттерны", icon: "chart.line.uptrend.xyaxis", color: .purple, duration: "4 часа"),
                Course(id: "fundamental_analysis", title: "Фундаментальный анализ", description: "Анализ проектов и новостей", icon: "newspaper", color: .indigo, duration: "3.5 часа")
            ]
        case .risk:
            return [
                Course(id: "position_sizing", title: "Размер позиции", description: "Как правильно рассчитывать объемы", icon: "calculator", color: .teal, duration: "2 часа"),
                Course(id: "stop_loss", title: "Стоп-лоссы", description: "Защита от больших потерь", icon: "hand.raised", color: .pink, duration: "1.5 часа")
            ]
        case .advanced:
            return [
                Course(id: "leverage_trading", title: "Торговля с плечом", description: "Кредитное плечо и его риски", icon: "arrow.up.right", color: .yellow, duration: "3 часа"),
                Course(id: "bot_trading", title: "Торговые боты", description: "Автоматизация торговли", icon: "robot", color: .mint, duration: "4.5 часа")
            ]
        }
    }
}

struct Course: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let duration: String
}

struct Article: Identifiable {
    let id: String
    let title: String
    let excerpt: String
    let author: String
    let date: String
    let category: String
    let categoryColor: Color
    let readTime: String
    let content: String
    
    static let sampleArticles = [
        Article(
            id: "1",
            title: "Как начать торговать криптовалютами: полное руководство для начинающих",
            excerpt: "Подробное руководство по началу торговли криптовалютами, включая выбор биржи, создание аккаунта и первые сделки.",
            author: "Эксперт Bybit",
            date: "Сегодня",
            category: "Основы",
            categoryColor: .blue,
            readTime: "5 мин",
            content: "Полный текст статьи..."
        ),
        Article(
            id: "2",
            title: "Технический анализ: основные индикаторы для успешной торговли",
            excerpt: "Изучите ключевые технические индикаторы, которые помогут вам принимать обоснованные торговые решения.",
            author: "Аналитик",
            date: "Вчера",
            category: "Анализ",
            categoryColor: .purple,
            readTime: "8 мин",
            content: "Полный текст статьи..."
        ),
        Article(
            id: "3",
            title: "Управление рисками в криптотрейдинге: 10 золотых правил",
            excerpt: "Важные принципы управления рисками, которые должен знать каждый трейдер для сохранения капитала.",
            author: "Риск-менеджер",
            date: "2 дня назад",
            category: "Риски",
            categoryColor: .red,
            readTime: "6 мин",
            content: "Полный текст статьи..."
        )
    ]
}

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Заголовок
                    Text(article.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Метаинформация
                    HStack {
                        Label(article.author, systemImage: "person.circle")
                        Spacer()
                        Label(article.readTime, systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Категория
                    Text(article.category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(article.categoryColor)
                        )
                    
                    // Содержание
                    Text(article.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                }
                .padding()
            }
            .navigationTitle("Статья")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LearningView()
}

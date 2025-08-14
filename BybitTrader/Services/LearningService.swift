import Foundation
import Combine

class LearningService: ObservableObject {
    static let shared = LearningService()
    
    // MARK: - Published Properties
    @Published var courses: [Course] = []
    @Published var articles: [Article] = []
    @Published var quizzes: [Quiz] = []
    @Published var userProgress: [String: LearningProgress] = [:]
    @Published var currentCourse: Course?
    @Published var currentLesson: Lesson?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let supabaseService = SupabaseService.shared
    private let loggingService = LoggingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadLearningContent()
        loadUserProgress()
    }
    
    // MARK: - Setup
    private func loadLearningContent() {
        courses = createDefaultCourses()
        articles = createDefaultArticles()
        quizzes = createDefaultQuizzes()
        
        loggingService.info("Learning content loaded", category: "learning", metadata: [
            "courses": courses.count,
            "articles": articles.count,
            "quizzes": quizzes.count
        ])
    }
    
    private func loadUserProgress() {
        // Load from UserDefaults or Supabase
        if let data = UserDefaults.standard.data(forKey: "learningProgress"),
           let progress = try? JSONDecoder().decode([String: LearningProgress].self, from: data) {
            userProgress = progress
        }
    }
    
    // MARK: - Public Methods
    func startCourse(_ course: Course) {
        currentCourse = course
        currentLesson = course.lessons.first
        
        // Initialize progress if not exists
        if userProgress[course.id.uuidString] == nil {
            userProgress[course.id.uuidString] = LearningProgress(
                courseId: course.id,
                completedLessons: [],
                currentLessonIndex: 0,
                quizScores: [],
                totalTimeSpent: 0,
                lastAccessed: Date()
            )
        }
        
        saveUserProgress()
        
        loggingService.info("Course started", category: "learning", metadata: [
            "courseId": course.id.uuidString,
            "courseName": course.title
        ])
    }
    
    func completeLesson(_ lesson: Lesson) {
        guard let courseId = currentCourse?.id.uuidString,
              var progress = userProgress[courseId] else { return }
        
        if !progress.completedLessons.contains(lesson.id) {
            progress.completedLessons.append(lesson.id)
            progress.currentLessonIndex = min(progress.currentLessonIndex + 1, currentCourse?.lessons.count ?? 0)
            progress.lastAccessed = Date()
            
            userProgress[courseId] = progress
            saveUserProgress()
            
            // Check if course is completed
            if isCourseCompleted(courseId: courseId) {
                handleCourseCompletion(courseId: courseId)
            }
            
            loggingService.info("Lesson completed", category: "learning", metadata: [
                "lessonId": lesson.id.uuidString,
                "lessonTitle": lesson.title,
                "courseId": courseId
            ])
        }
    }
    
    func submitQuiz(_ quiz: Quiz, answers: [String: String]) -> QuizResult {
        let score = calculateQuizScore(quiz: quiz, answers: answers)
        let isPassed = score >= quiz.passingScore
        
        // Save quiz result
        if let courseId = currentCourse?.id.uuidString,
           var progress = userProgress[courseId] {
            let quizResult = QuizResult(
                quizId: quiz.id,
                score: score,
                maxScore: quiz.questions.count,
                isPassed: isPassed,
                answers: answers,
                submittedAt: Date()
            )
            
            progress.quizScores.append(quizResult)
            userProgress[courseId] = progress
            saveUserProgress()
        }
        
        loggingService.info("Quiz submitted", category: "learning", metadata: [
            "quizId": quiz.id.uuidString,
            "score": score,
            "isPassed": isPassed
        ])
        
        return QuizResult(
            quizId: quiz.id,
            score: score,
            maxScore: quiz.questions.count,
            isPassed: isPassed,
            answers: answers,
            submittedAt: Date()
        )
    }
    
    func getRecommendedContent() -> [LearningContent] {
        var recommendations: [LearningContent] = []
        
        // Get user's current level
        let userLevel = getUserLevel()
        
        // Recommend courses based on level
        let recommendedCourses = courses.filter { course in
            course.difficulty == userLevel || course.difficulty == getNextLevel(userLevel)
        }.prefix(3)
        
        recommendations.append(contentsOf: recommendedCourses.map { LearningContent.course($0) })
        
        // Recommend articles
        let recommendedArticles = articles.filter { article in
            article.tags.contains(where: { tag in
                getCompletedCourseTags().contains(tag)
            })
        }.prefix(2)
        
        recommendations.append(contentsOf: recommendedArticles.map { LearningContent.article($0) })
        
        return Array(recommendations)
    }
    
    func searchContent(query: String) -> [LearningContent] {
        let lowercasedQuery = query.lowercased()
        
        var results: [LearningContent] = []
        
        // Search in courses
        let matchingCourses = courses.filter { course in
            course.title.lowercased().contains(lowercasedQuery) ||
            course.description.lowercased().contains(lowercasedQuery) ||
            course.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
        
        results.append(contentsOf: matchingCourses.map { LearningContent.course($0) })
        
        // Search in articles
        let matchingArticles = articles.filter { article in
            article.title.lowercased().contains(lowercasedQuery) ||
            article.content.lowercased().contains(lowercasedQuery) ||
            article.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
        
        results.append(contentsOf: matchingArticles.map { LearningContent.article($0) })
        
        return results
    }
    
    func getLearningStatistics() -> LearningStatistics {
        let totalCourses = courses.count
        let completedCourses = userProgress.values.filter { progress in
            isCourseCompleted(courseId: progress.courseId.uuidString)
        }.count
        
        let totalLessons = courses.reduce(0) { $0 + $1.lessons.count }
        let completedLessons = userProgress.values.reduce(0) { $0 + $0.completedLessons.count }
        
        let totalQuizzes = quizzes.count
        let passedQuizzes = userProgress.values.reduce(0) { $0 + $0.quizScores.filter { $0.isPassed }.count }
        
        let totalTimeSpent = userProgress.values.reduce(0) { $0 + $0.totalTimeSpent }
        let averageScore = calculateAverageQuizScore()
        
        let currentStreak = calculateCurrentStreak()
        let longestStreak = calculateLongestStreak()
        
        return LearningStatistics(
            totalCourses: totalCourses,
            completedCourses: completedCourses,
            totalLessons: totalLessons,
            completedLessons: completedLessons,
            totalQuizzes: totalQuizzes,
            passedQuizzes: passedQuizzes,
            totalTimeSpent: totalTimeSpent,
            averageScore: averageScore,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            completionRate: totalCourses > 0 ? Double(completedCourses) / Double(totalCourses) * 100 : 0
        )
    }
    
    func generateLearningReport() -> LearningReport {
        let statistics = getLearningStatistics()
        let recentActivity = getRecentActivity()
        let recommendations = getRecommendations()
        
        return LearningReport(
            statistics: statistics,
            recentActivity: recentActivity,
            recommendations: recommendations,
            generatedAt: Date()
        )
    }
    
    func exportProgress() -> String {
        var csv = "Course,Lesson,Status,Completed Date,Time Spent,Quiz Score\n"
        
        for (courseId, progress) in userProgress {
            if let course = courses.first(where: { $0.id.uuidString == courseId }) {
                for lessonId in progress.completedLessons {
                    if let lesson = course.lessons.first(where: { $0.id == lessonId }) {
                        csv += "\(course.title),\(lesson.title),Completed,\(Date().formatted()),\(progress.totalTimeSpent),N/A\n"
                    }
                }
            }
        }
        
        return csv
    }
    
    // MARK: - Private Methods
    private func createDefaultCourses() -> [Course] {
        return [
            Course(
                title: "Основы криптотрейдинга",
                description: "Изучите основы торговли криптовалютами, включая анализ рынка, управление рисками и психологию трейдинга.",
                difficulty: .beginner,
                estimatedDuration: 120,
                lessons: createBasicTradingLessons(),
                tags: ["криптовалюты", "трейдинг", "основы"],
                prerequisites: [],
                certificate: true
            ),
            Course(
                title: "Технический анализ",
                description: "Углубленный курс по техническому анализу: графики, индикаторы, паттерны и стратегии.",
                difficulty: .intermediate,
                estimatedDuration: 180,
                lessons: createTechnicalAnalysisLessons(),
                tags: ["технический анализ", "графики", "индикаторы"],
                prerequisites: ["криптовалюты", "трейдинг"],
                certificate: true
            ),
            Course(
                title: "Управление рисками",
                description: "Научитесь правильно управлять рисками в трейдинге: позиционирование, стоп-лоссы и диверсификация.",
                difficulty: .intermediate,
                estimatedDuration: 90,
                lessons: createRiskManagementLessons(),
                tags: ["риски", "управление", "позиционирование"],
                prerequisites: ["криптовалюты", "трейдинг"],
                certificate: true
            ),
            Course(
                title: "Продвинутые стратегии",
                description: "Продвинутые торговые стратегии: арбитраж, скальпинг, свинг-трейдинг и алгоритмическая торговля.",
                difficulty: .advanced,
                estimatedDuration: 240,
                lessons: createAdvancedStrategyLessons(),
                tags: ["стратегии", "арбитраж", "алгоритмы"],
                prerequisites: ["технический анализ", "управление рисками"],
                certificate: true
            ),
            Course(
                title: "Психология трейдинга",
                description: "Понимание психологических аспектов трейдинга: эмоции, дисциплина и менталитет успешного трейдера.",
                difficulty: .intermediate,
                estimatedDuration: 60,
                lessons: createPsychologyLessons(),
                tags: ["психология", "эмоции", "дисциплина"],
                prerequisites: ["основы"],
                certificate: false
            )
        ]
    }
    
    private func createDefaultArticles() -> [Article] {
        return [
            Article(
                title: "Как читать свечные графики",
                content: "Свечные графики - один из самых популярных способов анализа рынка...",
                author: "Трейдинг Эксперт",
                publishDate: Date(),
                readTime: 8,
                tags: ["графики", "свечи", "анализ"],
                difficulty: .beginner,
                isPremium: false
            ),
            Article(
                title: "Топ-10 ошибок начинающих трейдеров",
                content: "Каждый трейдер совершает ошибки, особенно в начале пути...",
                author: "Трейдинг Эксперт",
                publishDate: Date().addingTimeInterval(-86400),
                readTime: 12,
                tags: ["ошибки", "начинающие", "советы"],
                difficulty: .beginner,
                isPremium: false
            ),
            Article(
                title: "Секреты успешного портфеля",
                content: "Диверсификация - ключ к успешному инвестированию...",
                author: "Инвестиционный Аналитик",
                publishDate: Date().addingTimeInterval(-172800),
                readTime: 15,
                tags: ["портфель", "диверсификация", "инвестиции"],
                difficulty: .intermediate,
                isPremium: true
            )
        ]
    }
    
    private func createDefaultQuizzes() -> [Quiz] {
        return [
            Quiz(
                title: "Основы криптотрейдинга",
                description: "Проверьте свои знания основ криптотрейдинга",
                questions: createBasicTradingQuestions(),
                passingScore: 7,
                timeLimit: 600,
                difficulty: .beginner
            ),
            Quiz(
                title: "Технический анализ",
                description: "Тест по техническому анализу",
                questions: createTechnicalAnalysisQuestions(),
                passingScore: 8,
                timeLimit: 900,
                difficulty: .intermediate
            )
        ]
    }
    
    private func createBasicTradingLessons() -> [Lesson] {
        return [
            Lesson(
                title: "Что такое криптовалюты",
                content: "Криптовалюты - это цифровые или виртуальные валюты...",
                duration: 15,
                type: .video,
                resources: ["video_url", "pdf_guide"],
                quiz: nil
            ),
            Lesson(
                title: "Основы рынка",
                content: "Понимание спроса и предложения на рынке...",
                duration: 20,
                type: .interactive,
                resources: ["interactive_chart", "market_simulator"],
                quiz: nil
            ),
            Lesson(
                title: "Первые шаги в трейдинге",
                content: "Как открыть первую позицию...",
                duration: 25,
                type: .practical,
                resources: ["demo_account", "trading_guide"],
                quiz: createBasicTradingQuestions()
            )
        ]
    }
    
    private func createTechnicalAnalysisLessons() -> [Lesson] {
        return [
            Lesson(
                title: "Типы графиков",
                content: "Линейные, свечные и баровые графики...",
                duration: 20,
                type: .video,
                resources: ["chart_examples", "video_tutorial"],
                quiz: nil
            ),
            Lesson(
                title: "Технические индикаторы",
                content: "RSI, MACD, Moving Averages...",
                duration: 30,
                type: .interactive,
                resources: ["indicator_calculator", "chart_analysis"],
                quiz: nil
            ),
            Lesson(
                title: "Паттерны разворота",
                content: "Голова и плечи, двойное дно...",
                duration: 35,
                type: .practical,
                resources: ["pattern_recognition", "case_studies"],
                quiz: createTechnicalAnalysisQuestions()
            )
        ]
    }
    
    private func createRiskManagementLessons() -> [Lesson] {
        return [
            Lesson(
                title: "Размер позиции",
                content: "Как правильно рассчитывать размер позиции...",
                duration: 25,
                type: .video,
                resources: ["position_calculator", "risk_assessment"],
                quiz: nil
            ),
            Lesson(
                title: "Стоп-лоссы и тейк-профиты",
                content: "Установка уровней выхода из позиции...",
                duration: 20,
                type: .interactive,
                resources: ["order_types", "risk_reward"],
                quiz: nil
            )
        ]
    }
    
    private func createAdvancedStrategyLessons() -> [Lesson] {
        return [
            Lesson(
                title: "Арбитраж",
                content: "Торговля на разнице цен между биржами...",
                duration: 40,
                type: .video,
                resources: ["arbitrage_calculator", "exchange_comparison"],
                quiz: nil
            ),
            Lesson(
                title: "Скальпинг",
                content: "Краткосрочная торговля на малых движениях...",
                duration: 35,
                type: .practical,
                resources: ["scalping_tools", "real_time_data"],
                quiz: nil
            )
        ]
    }
    
    private func createPsychologyLessons() -> [Lesson] {
        return [
            Lesson(
                title: "Управление эмоциями",
                content: "Как контролировать страх и жадность...",
                duration: 20,
                type: .video,
                resources: ["emotion_tracker", "meditation_guide"],
                quiz: nil
            ),
            Lesson(
                title: "Торговая дисциплина",
                content: "Следование торговому плану...",
                duration: 15,
                type: .interactive,
                resources: ["planning_tools", "discipline_checklist"],
                quiz: nil
            )
        ]
    }
    
    private func createBasicTradingQuestions() -> [Question] {
        return [
            Question(
                text: "Что такое криптовалюта?",
                options: [
                    "Цифровая валюта",
                    "Физическая монета",
                    "Банкнота",
                    "Чек"
                ],
                correctAnswer: 0,
                explanation: "Криптовалюта - это цифровая или виртуальная валюта, использующая криптографию для безопасности."
            ),
            Question(
                text: "Что означает HODL?",
                options: [
                    "Hold On for Dear Life",
                    "Hold",
                    "High Order Dynamic Logic",
                    "None of the above"
                ],
                correctAnswer: 0,
                explanation: "HODL - это мем в криптосообществе, означающий 'Hold On for Dear Life'."
            )
        ]
    }
    
    private func createTechnicalAnalysisQuestions() -> [Question] {
        return [
            Question(
                text: "Что показывает RSI?",
                options: [
                    "Тренд",
                    "Моментум",
                    "Объем",
                    "Волатильность"
                ],
                correctAnswer: 1,
                explanation: "RSI (Relative Strength Index) показывает моментум цены."
            )
        ]
    }
    
    private func calculateQuizScore(quiz: Quiz, answers: [String: String]) -> Int {
        var correctAnswers = 0
        
        for question in quiz.questions {
            if let userAnswer = answers[question.id.uuidString],
               let answerIndex = Int(userAnswer),
               answerIndex == question.correctAnswer {
                correctAnswers += 1
            }
        }
        
        return correctAnswers
    }
    
    private func isCourseCompleted(courseId: String) -> Bool {
        guard let progress = userProgress[courseId],
              let course = courses.first(where: { $0.id.uuidString == courseId }) else {
            return false
        }
        
        return progress.completedLessons.count >= course.lessons.count
    }
    
    private func handleCourseCompletion(courseId: String) {
        loggingService.info("Course completed", category: "learning", metadata: [
            "courseId": courseId
        ])
        
        // Award certificate if applicable
        if let course = courses.first(where: { $0.id.uuidString == courseId }),
           course.certificate {
            // Handle certificate awarding
        }
    }
    
    private func saveUserProgress() {
        if let data = try? JSONEncoder().encode(userProgress) {
            UserDefaults.standard.set(data, forKey: "learningProgress")
        }
    }
    
    private func getUserLevel() -> DifficultyLevel {
        let completedCourses = userProgress.values.filter { progress in
            isCourseCompleted(courseId: progress.courseId.uuidString)
        }.count
        
        if completedCourses >= 3 { return .advanced }
        if completedCourses >= 1 { return .intermediate }
        return .beginner
    }
    
    private func getNextLevel(_ currentLevel: DifficultyLevel) -> DifficultyLevel {
        switch currentLevel {
        case .beginner: return .intermediate
        case .intermediate: return .advanced
        case .advanced: return .advanced
        }
    }
    
    private func getCompletedCourseTags() -> [String] {
        var tags: Set<String> = []
        
        for (courseId, _) in userProgress {
            if isCourseCompleted(courseId: courseId),
               let course = courses.first(where: { $0.id.uuidString == courseId }) {
                tags.formUnion(course.tags)
            }
        }
        
        return Array(tags)
    }
    
    private func calculateAverageQuizScore() -> Double {
        let allScores = userProgress.values.flatMap { $0.quizScores }
        guard !allScores.isEmpty else { return 0 }
        
        let totalScore = allScores.reduce(0) { $0 + $0.score }
        return Double(totalScore) / Double(allScores.count)
    }
    
    private func calculateCurrentStreak() -> Int {
        // Simplified streak calculation
        return 0
    }
    
    private func calculateLongestStreak() -> Int {
        // Simplified longest streak calculation
        return 0
    }
    
    private func getRecentActivity() -> [LearningActivity] {
        var activities: [LearningActivity] = []
        
        for (courseId, progress) in userProgress {
            if let course = courses.first(where: { $0.id.uuidString == courseId }) {
                for lessonId in progress.completedLessons {
                    if let lesson = course.lessons.first(where: { $0.id == lessonId }) {
                        activities.append(LearningActivity(
                            type: .lessonCompleted,
                            title: lesson.title,
                            courseName: course.title,
                            timestamp: Date(),
                            details: "Урок завершен"
                        ))
                    }
                }
            }
        }
        
        return activities.sorted { $0.timestamp > $1.timestamp }.prefix(10).map { $0 }
    }
    
    private func getRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let userLevel = getUserLevel()
        let completedTags = getCompletedCourseTags()
        
        if userLevel == .beginner {
            recommendations.append("Продолжайте изучение основ криптотрейдинга")
            recommendations.append("Попробуйте пройти курс по техническому анализу")
        } else if userLevel == .intermediate {
            recommendations.append("Изучите управление рисками")
            recommendations.append("Практикуйтесь на демо-счете")
        } else {
            recommendations.append("Изучите продвинутые стратегии")
            recommendations.append("Поделитесь знаниями с другими трейдерами")
        }
        
        return recommendations
    }
}

// MARK: - Models
struct Course: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let difficulty: DifficultyLevel
    let estimatedDuration: Int // minutes
    let lessons: [Lesson]
    let tags: [String]
    let prerequisites: [String]
    let certificate: Bool
}

struct Lesson: Identifiable, Codable {
    let id = UUID()
    let title: String
    let content: String
    let duration: Int // minutes
    let type: LessonType
    let resources: [String]
    let quiz: [Question]?
}

struct Article: Identifiable, Codable {
    let id = UUID()
    let title: String
    let content: String
    let author: String
    let publishDate: Date
    let readTime: Int // minutes
    let tags: [String]
    let difficulty: DifficultyLevel
    let isPremium: Bool
}

struct Quiz: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let questions: [Question]
    let passingScore: Int
    let timeLimit: Int // seconds
    let difficulty: DifficultyLevel
}

struct Question: Identifiable, Codable {
    let id = UUID()
    let text: String
    let options: [String]
    let correctAnswer: Int
    let explanation: String
}

struct LearningProgress: Codable {
    let courseId: UUID
    var completedLessons: [UUID]
    var currentLessonIndex: Int
    var quizScores: [QuizResult]
    var totalTimeSpent: Int // minutes
    var lastAccessed: Date
}

struct QuizResult: Codable {
    let quizId: UUID
    let score: Int
    let maxScore: Int
    let isPassed: Bool
    let answers: [String: String]
    let submittedAt: Date
}

struct LearningStatistics {
    let totalCourses: Int
    let completedCourses: Int
    let totalLessons: Int
    let completedLessons: Int
    let totalQuizzes: Int
    let passedQuizzes: Int
    let totalTimeSpent: Int
    let averageScore: Double
    let currentStreak: Int
    let longestStreak: Int
    let completionRate: Double
}

struct LearningReport {
    let statistics: LearningStatistics
    let recentActivity: [LearningActivity]
    let recommendations: [String]
    let generatedAt: Date
}

struct LearningActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let courseName: String
    let timestamp: Date
    let details: String
}

enum LearningContent {
    case course(Course)
    case article(Article)
    case quiz(Quiz)
}

enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Начинающий"
        case .intermediate: return "Средний"
        case .advanced: return "Продвинутый"
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "#28a745"
        case .intermediate: return "#ffc107"
        case .advanced: return "#dc3545"
        }
    }
}

enum LessonType: String, CaseIterable, Codable {
    case video = "video"
    case interactive = "interactive"
    case practical = "practical"
    case reading = "reading"
    
    var displayName: String {
        switch self {
        case .video: return "Видео"
        case .interactive: return "Интерактивный"
        case .practical: return "Практический"
        case .reading: return "Чтение"
        }
    }
    
    var icon: String {
        switch self {
        case .video: return "play.circle"
        case .interactive: return "hand.tap"
        case .practical: return "wrench.and.screwdriver"
        case .reading: return "book"
        }
    }
}

enum ActivityType: String {
    case lessonCompleted = "lessonCompleted"
    case quizPassed = "quizPassed"
    case courseStarted = "courseStarted"
    case courseCompleted = "courseCompleted"
}

# Bybit Trader iOS - Продвинутое торговое приложение

## 📱 Описание

Bybit Trader iOS - это профессиональное торговое приложение для iPhone, предоставляющее полный доступ к бирже Bybit с расширенными возможностями аналитики, обучения и управления рисками.

## ✨ Основные возможности

### 🚀 Торговля в реальном времени
- **Live котировки** - обновление цен каждую секунду
- **Позиции** - мониторинг открытых позиций
- **Баланс** - отслеживание средств в реальном времени
- **Размещение ордеров** - Market и Limit ордера
- **Отмена ордеров** - мгновенная отмена активных ордеров

### 📊 Расширенная аналитика
- **Технические индикаторы** - RSI, MACD, Bollinger Bands
- **Графики** - свечные, линейные, баровые
- **Анализ портфеля** - распределение активов
- **Отчеты** - дневные, недельные, месячные
- **Экспорт данных** - CSV, Excel, JSON

### 🎓 Обучающая система
- **Курсы по трейдингу** - от новичка до профессионала
- **Статьи** - актуальная информация о рынке
- **Тесты** - проверка знаний
- **Прогресс** - отслеживание обучения

### 🤖 AI Помощник
- **Торговые советы** - рекомендации по сделкам
- **Анализ рынка** - интерпретация данных
- **Обучение** - ответы на вопросы
- **Стратегии** - разработка торговых планов

### 🔐 Безопасность
- **Apple Sign In** - безопасная авторизация
- **Биометрия** - Face ID / Touch ID
- **Шифрование** - защита API ключей
- **Аудит** - логирование всех действий

### 💰 Подписка
- **Пробный период** - 30 дней бесплатно
- **Месячная подписка** - 299₽/месяц
- **Локализация** - цены для разных стран
- **Преимущества** - расширенные функции

## 🛠 Технические требования

### Системные требования
- **iOS** 15.0+
- **iPhone** X и новее
- **Xcode** 14.0+
- **Swift** 5.7+

### Зависимости
```swift
// Основные фреймворки
import SwiftUI
import Combine
import Charts
import CoreData

// Внешние библиотеки
import Supabase
import AuthenticationServices
import StoreKit
```

## 📋 Установка и настройка

### 1. Клонирование репозитория
```bash
git clone https://github.com/yourusername/bybit-trader-ios.git
cd bybit-trader-ios
```

### 2. Установка зависимостей
```bash
# CocoaPods
pod install

# Или Swift Package Manager
# Добавить в Xcode: File -> Add Package Dependencies
```

### 3. Настройка API ключей
1. Откройте `BybitTrader.xcworkspace` в Xcode
2. Перейдите в настройки приложения
3. Добавьте свои API ключи Bybit
4. Выберите режим (Testnet/Production)

### 4. Настройка Supabase
1. Создайте проект на [supabase.com](https://supabase.com)
2. Скопируйте URL и ключи
3. Обновите `Config.swift`

## 🔑 Настройка Bybit API

### Получение API ключей
1. Зайдите на [bybit.com](https://bybit.com)
2. Перейдите в API Management
3. Создайте новый API ключ
4. Установите разрешения:
   - **Read** - чтение баланса, позиций
   - **Trade** - размещение ордеров
   - **Wallet** - управление кошельком

### Безопасность API ключей
- ✅ Храните в Keychain
- ✅ Используйте HTTPS
- ✅ Ограничьте IP адреса
- ❌ Не делитесь ключами
- ❌ Не коммитьте в Git

## 🏗 Сборка проекта

### Сборка для симулятора
```bash
# Debug
xcodebuild -workspace BybitTrader.xcworkspace \
           -scheme BybitTrader \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           build

# Release
xcodebuild -workspace BybitTrader.xcworkspace \
           -scheme BybitTrader \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           -configuration Release \
           build
```

### Сборка для устройства
```bash
# Archive
xcodebuild -workspace BybitTrader.xcworkspace \
           -scheme BybitTrader \
           -destination 'generic/platform=iOS' \
           -configuration Release \
           archive \
           -archivePath build/BybitTrader.xcarchive

# Export IPA
xcodebuild -exportArchive \
           -archivePath build/BybitTrader.xcarchive \
           -exportPath build/ \
           -exportOptionsPlist exportOptions.plist
```

### Сборка через Bitrise
1. Подключите репозиторий к [bitrise.io](https://bitrise.io)
2. Настройте переменные окружения
3. Запустите сборку

## 📱 Структура проекта

```
BybitTrader/
├── Models/                 # Модели данных
├── Views/                  # Пользовательский интерфейс
├── Services/               # Бизнес-логика
│   ├── APIKeyManagementService.swift    # Управление API ключами
│   ├── EnhancedBybitService.swift       # Работа с Bybit API
│   ├── AdvancedAnimationService.swift   # Анимации и эффекты
│   ├── EnhancedErrorHandlingService.swift # Обработка ошибок
│   ├── LoggingService.swift             # Логирование
│   ├── SupabaseService.swift            # База данных
│   ├── SubscriptionService.swift        # Подписки
│   └── ...                             # Другие сервисы
├── Resources/              # Ресурсы приложения
└── Supporting Files/       # Конфигурационные файлы
```

## 🔧 Конфигурация

### Config.swift
```swift
struct Config {
    // Bybit API
    static let bybitTestnetURL = "https://api-testnet.bybit.com"
    static let bybitProductionURL = "https://api.bybit.com"
    
    // Supabase
    static let supabaseURL = "YOUR_SUPABASE_URL"
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
    
    // AI Chat
    static let aiChatAPIKey = "YOUR_AI_CHAT_API_KEY"
}
```

### Info.plist
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>bybit.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>
```

## 🚀 Развертывание

### App Store
1. Создайте App Store Connect запись
2. Загрузите IPA через Xcode
3. Настройте метаданные
4. Отправьте на проверку

### TestFlight
1. Загрузите build в App Store Connect
2. Добавьте тестеров
3. Отправьте приглашения
4. Мониторьте отзывы

### Ad-Hoc
1. Создайте Ad-Hoc профиль
2. Соберите IPA с `exportOptionsAdHoc.plist`
3. Распространите через TestFlight или другие сервисы

## 📊 Мониторинг и аналитика

### Логирование
- **Уровни**: Debug, Info, Warning, Error
- **Категории**: API, Trading, User, Performance
- **Экспорт**: CSV, JSON, Plain Text
- **Ротация**: Автоматическая очистка старых логов

### Метрики
- **Производительность** - время ответа API
- **Ошибки** - частота и типы ошибок
- **Использование** - популярные функции
- **Стабильность** - краши и зависания

## 🔒 Безопасность

### Защита данных
- **Шифрование** - AES-256 для чувствительных данных
- **Keychain** - безопасное хранение API ключей
- **HTTPS** - все сетевые запросы
- **Валидация** - проверка входных данных

### Аудит
- **Логирование** - все действия пользователя
- **Мониторинг** - подозрительная активность
- **Уведомления** - критические события
- **Отчеты** - регулярные проверки безопасности

## 🧪 Тестирование

### Unit Tests
```bash
xcodebuild test -workspace BybitTrader.xcworkspace \
               -scheme BybitTrader \
               -destination 'platform=iOS Simulator,name=iPhone 15'
```

### UI Tests
```bash
xcodebuild test -workspace BybitTrader.xcworkspace \
               -scheme BybitTraderUITests \
               -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Тестирование API
- **Testnet** - безопасное тестирование
- **Mock данные** - для разработки
- **Интеграционные тесты** - проверка API
- **Нагрузочное тестирование** - производительность

## 📚 Документация API

### Bybit V5 API
- **Base URL**: `https://api.bybit.com` (Production)
- **Base URL**: `https://api-testnet.bybit.com` (Testnet)
- **Версия**: V5
- **Аутентификация**: HMAC SHA256

### Основные эндпоинты
```swift
// Баланс кошелька
GET /v5/account/wallet-balance

// Позиции
GET /v5/position/list

// Размещение ордера
POST /v5/order/create

// Отмена ордера
POST /v5/order/cancel

// Рыночные данные
GET /v5/market/tickers?category=spot

// Графики
GET /v5/market/kline?category=spot&symbol=BTCUSDT&interval=1&limit=200
```

### Аутентификация
```swift
// Заголовки для аутентифицированных запросов
X-BAPI-API-KEY: your_api_key
X-BAPI-SIGNATURE: generated_signature
X-BAPI-SIGNATURE-TYPE: 2
X-BAPI-TIMESTAMP: timestamp_in_milliseconds
```

### Генерация подписи
```swift
func generateSignature(timestamp: Int64, apiSecret: String) -> String {
    let queryString = "api_key=\(apiKey)&timestamp=\(timestamp)"
    let signature = HMAC.SHA256.sign(
        data: queryString.data(using: .utf8)!,
        key: apiSecret.data(using: .utf8)!
    )
    return signature.map { String(format: "%02hhx", $0) }.joined()
}
```

## 🎨 UI/UX особенности

### Дизайн
- **Material Design** - современный интерфейс
- **Темы** - светлая и темная
- **Адаптивность** - поддержка всех iPhone
- **Анимации** - плавные переходы

### Анимации
- **Частицы** - эффекты для событий
- **Графики** - плавные обновления
- **Переходы** - между экранами
- **Haptic Feedback** - тактильные отклики

### Доступность
- **VoiceOver** - поддержка для незрячих
- **Dynamic Type** - масштабируемые шрифты
- **High Contrast** - улучшенная видимость
- **Reduce Motion** - для чувствительных к движению

## 🔄 Обновления и поддержка

### Версионирование
- **Semantic Versioning** - MAJOR.MINOR.PATCH
- **Changelog** - история изменений
- **Migration Guide** - инструкции по обновлению
- **Backward Compatibility** - поддержка старых версий

### Поддержка
- **Документация** - подробные инструкции
- **FAQ** - часто задаваемые вопросы
- **Community** - форум пользователей
- **Support** - техническая поддержка

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл `LICENSE` для подробностей.

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие проекта! Пожалуйста, ознакомьтесь с нашим руководством по вкладу:

1. Fork репозитория
2. Создайте feature branch
3. Внесите изменения
4. Добавьте тесты
5. Создайте Pull Request

## 📞 Контакты

- **Email**: support@bybittrader.com
- **Telegram**: @bybittrader_support
- **Discord**: Bybit Trader Community
- **Website**: https://bybittrader.com

## 🙏 Благодарности

- **Bybit** - за предоставление API
- **Supabase** - за backend инфраструктуру
- **SwiftUI Community** - за вдохновение
- **Наши пользователи** - за обратную связь

---

**Внимание**: Торговля криптовалютами связана с высокими рисками. Используйте приложение на свой страх и риск. Авторы не несут ответственности за возможные финансовые потери.

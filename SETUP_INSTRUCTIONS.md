# 🚀 Инструкции по настройке Bybit Trader iOS

## 📋 Содержание

1. [Предварительные требования](#предварительные-требования)
2. [Настройка API ключей](#настройка-api-ключей)
3. [Настройка Supabase](#настройка-supabase)
4. [Настройка AI Chat](#настройка-ai-chat)
5. [Настройка Apple Sign In](#настройка-apple-sign-in)
6. [Настройка StoreKit](#настройка-storekit)
7. [Загрузка на GitHub](#загрузка-на-github)
8. [Сборка проекта](#сборка-проекта)
9. [Устранение неполадок](#устранение-неполадок)

---

## 🔧 Предварительные требования

### Системные требования
- **macOS**: 12.0 или новее
- **Xcode**: 14.0 или новее
- **iOS**: 15.0 или новее
- **Swift**: 5.7 или новее

### Установленные инструменты
- [Xcode](https://developer.apple.com/xcode/) - IDE для iOS разработки
- [Git](https://git-scm.com/) - система контроля версий
- [CocoaPods](https://cocoapods.org/) - менеджер зависимостей (опционально)

### Apple Developer Account
- Активный Apple Developer Account ($99/год)
- Доступ к App Store Connect
- Сертификаты разработки и распространения

---

## 🔑 Настройка API ключей

### 1. Bybit API

#### Получение API ключей
1. Зарегистрируйтесь на [Bybit](https://www.bybit.com/)
2. Перейдите в **API Management**
3. Создайте новый API ключ:
   - **Label**: BybitTrader iOS
   - **Permissions**: 
     - ✅ Read
     - ✅ Trade
     - ✅ Transfer
   - **IP Restriction**: Оставьте пустым для разработки
4. Скопируйте **API Key** и **Secret Key**

#### Настройка в проекте
1. Откройте `BybitTrader/Config.swift`
2. Замените значения:
```swift
// Замените на ваши реальные ключи
static let apiKey = "ВАШ_РЕАЛЬНЫЙ_API_KEY"
static let apiSecret = "ВАШ_РЕАЛЬНЫЙ_SECRET_KEY"

// Для тестирования используйте testnet
static let testnetApiKey = "ВАШ_TESTNET_API_KEY"
static let testnetApiSecret = "ВАШ_TESTNET_SECRET_KEY"
```

#### Testnet для разработки
1. Перейдите на [Bybit Testnet](https://testnet.bybit.com/)
2. Создайте тестовый аккаунт
3. Получите testnet API ключи
4. Используйте testnet для разработки и тестирования

### 2. Supabase

#### Создание проекта
1. Перейдите на [Supabase](https://supabase.com/)
2. Создайте новый проект
3. Выберите регион (рекомендуется ближайший к вам)
4. Дождитесь завершения инициализации

#### Настройка базы данных
1. В проекте Supabase перейдите в **SQL Editor**
2. Выполните SQL скрипт из `supabase_schema.sql`
3. Проверьте создание таблиц в **Table Editor**

#### Получение ключей
1. Перейдите в **Settings** → **API**
2. Скопируйте:
   - **Project URL**
   - **anon public** ключ
   - **service_role** ключ (храните в секрете!)

#### Настройка в проекте
В `Config.swift` уже настроены ваши ключи:
```swift
static let url = "https://koagmtxeomjrymgwnvub.supabase.co"
static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
static let serviceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 3. AI Chat API

#### Получение API ключа
1. Зарегистрируйтесь на [Artemox](https://artemox.com/)
2. Перейдите в **API Keys**
3. Создайте новый API ключ
4. Скопируйте ключ

#### Настройка в проекте
В `Config.swift` замените:
```swift
static let apiKey = "ВАШ_РЕАЛЬНЫЙ_AI_CHAT_API_KEY"
```

---

## 🗄️ Настройка Supabase

### 1. Создание таблиц

#### Автоматическое создание
1. Откройте **SQL Editor** в Supabase
2. Скопируйте содержимое `supabase_schema.sql`
3. Выполните скрипт

#### Ручное создание основных таблиц
```sql
-- Пользователи
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Профили пользователей
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    subscription_status TEXT DEFAULT 'none',
    subscription_start_date TIMESTAMP WITH TIME ZONE,
    subscription_end_date TIMESTAMP WITH TIME ZONE,
    trial_end_date TIMESTAMP WITH TIME ZONE,
    monthly_price DECIMAL(10,2) DEFAULT 299.00,
    country_code TEXT DEFAULT 'RU',
    currency TEXT DEFAULT 'RUB',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Сделки
CREATE TABLE trades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    side TEXT NOT NULL,
    quantity DECIMAL(20,8) NOT NULL,
    price DECIMAL(20,8) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    tags TEXT[],
    notes TEXT,
    fee DECIMAL(20,8) DEFAULT 0,
    order_type TEXT,
    status TEXT DEFAULT 'pending',
    realized_pnl DECIMAL(20,8),
    unrealized_pnl DECIMAL(20,8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. Настройка RLS (Row Level Security)

#### Включение RLS
```sql
-- Включить RLS для всех таблиц
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE trades ENABLE ROW LEVEL SECURITY;
```

#### Создание политик
```sql
-- Пользователи могут видеть только свои данные
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Пользователи могут видеть только свои сделки
CREATE POLICY "Users can view own trades" ON trades
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own trades" ON trades
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### 3. Настройка аутентификации

#### Включение провайдеров
1. Перейдите в **Authentication** → **Providers**
2. Включите:
   - ✅ Email
   - ✅ Apple (если планируете Apple Sign In)
   - ✅ Google (опционально)

#### Настройка Apple Sign In
1. Включите **Apple** провайдер
2. Добавьте **Service ID** из Apple Developer Console
3. Настройте **Redirect URLs**

---

## 🍎 Настройка Apple Sign In

### 1. Apple Developer Console

#### Создание App ID
1. Перейдите в [Apple Developer Console](https://developer.apple.com/)
2. **Certificates, Identifiers & Profiles**
3. **Identifiers** → **App IDs**
4. Создайте новый App ID:
   - **Description**: Bybit Trader
   - **Bundle ID**: com.yourcompany.BybitTrader
   - **Capabilities**: ✅ Sign In with Apple

#### Создание Service ID
1. **Identifiers** → **Services IDs**
2. Создайте новый Service ID:
   - **Description**: Bybit Trader Web
   - **Identifier**: com.yourcompany.BybitTrader.web
   - **Capabilities**: ✅ Sign In with Apple

#### Настройка Sign In with Apple
1. Выберите созданный Service ID
2. **Sign In with Apple** → **Configure**
3. **Primary App ID**: выберите ваш App ID
4. **Domains and Subdomains**: добавьте ваш домен
5. **Return URLs**: добавьте URL для возврата

### 2. Настройка в Xcode

#### Добавление capability
1. Откройте проект в Xcode
2. Выберите target **BybitTrader**
3. **Signing & Capabilities**
4. **+ Capability** → **Sign In with Apple**

#### Настройка Info.plist
Добавьте в `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.BybitTrader</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.yourcompany.BybitTrader</string>
        </array>
    </dict>
</array>
```

---

## 💰 Настройка StoreKit

### 1. App Store Connect

#### Создание приложения
1. Перейдите в [App Store Connect](https://appstoreconnect.apple.com/)
2. **My Apps** → **+** → **New App**
3. Заполните информацию:
   - **Platforms**: iOS
   - **Name**: Bybit Trader
   - **Bundle ID**: com.yourcompany.BybitTrader
   - **SKU**: BybitTrader2024

#### Создание подписок
1. **Features** → **In-App Purchases**
2. **+** → **Create New**
3. Создайте подписку:
   - **Type**: Auto-Renewable Subscription
   - **Reference Name**: Monthly Subscription
   - **Product ID**: com.bybittrader.monthly
   - **Subscription Group**: BybitTrader Subscriptions

#### Настройка цен
1. Выберите подписку
2. **Pricing** → **Add Territory**
3. Настройте цены для разных стран:
   - **Russia**: 299 ₽
   - **United States**: $3.99
   - **European Union**: €3.49

### 2. Настройка в проекте

#### Обновление Config.swift
```swift
static let monthlyProductId = "com.bybittrader.monthly"
static let yearlyProductId = "com.bybittrader.yearly"
```

#### Тестирование в симуляторе
1. **Xcode** → **Product** → **Scheme** → **Edit Scheme**
2. **Run** → **Options**
3. **StoreKit Configuration**: выберите файл конфигурации

---

## 📤 Загрузка на GitHub

### 1. Создание репозитория

#### На GitHub
1. Перейдите на [github.com](https://github.com)
2. **New repository**
3. **Repository name**: BybitTrader-iOS
4. **Description**: Professional iOS trading app for Bybit
5. **Visibility**: Public или Private
6. **НЕ ставьте галочки** на README, .gitignore, license
7. **Create repository**

### 2. Инициализация локального репозитория

#### Автоматически (рекомендуется)
1. Запустите `quick_start_commands.bat`
2. Выберите опцию 1: "Инициализировать Git репозиторий"

#### Вручную
```bash
# Перейти в папку проекта
cd "C:\Users\Admin\OneDrive\Desktop\Новая папка (4)"

# Инициализировать Git
git init

# Добавить все файлы
git add .

# Первый коммит
git commit -m "Initial commit: Bybit Trader iOS app with complete features"

# Переименовать ветку
git branch -M main

# Добавить удаленный репозиторий
git remote add origin https://github.com/YOUR_USERNAME/BybitTrader-iOS.git

# Отправить код
git push -u origin main
```

### 3. Обновление .gitignore

#### Автоматически
1. Запустите `quick_start_commands.bat`
2. Выберите опцию 4: "Создать .gitignore"

#### Вручную
```bash
# Добавить .gitignore
git add .gitignore

# Закоммитить
git commit -m "Add .gitignore for iOS project"

# Отправить изменения
git push origin main
```

---

## 🏗️ Сборка проекта

### 1. Настройка в Xcode

#### Подписание
1. Выберите target **BybitTrader**
2. **Signing & Capabilities**
3. **Team**: выберите ваш Apple Developer Team
4. **Bundle Identifier**: com.yourcompany.BybitTrader

#### Provisioning Profile
1. **Provisioning Profile**: выберите профиль для разработки
2. Или оставьте **Automatically manage signing**

### 2. Сборка для симулятора

#### Быстрая сборка
```bash
# Сборка для iPhone 15 симулятора
xcodebuild -project BybitTrader.xcodeproj \
           -scheme BybitTrader \
           -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
           build
```

#### В Xcode
1. Выберите симулятор iPhone 15
2. **Product** → **Build** (⌘B)
3. **Product** → **Run** (⌘R)

### 3. Сборка для устройства

#### Подготовка
1. Подключите iPhone
2. Доверьтесь компьютеру на устройстве
3. Выберите устройство в Xcode

#### Сборка
1. **Product** → **Build** (⌘B)
2. **Product** → **Run** (⌘R)

### 4. Сборка IPA файла

#### Archive
1. **Product** → **Archive**
2. Дождитесь завершения архивирования
3. **Distribute App**

#### Export
1. **App Store Connect** (для публикации)
2. **Ad Hoc** (для тестирования)
3. **Development** (для разработки)

---

## 🔧 Устранение неполадок

### 1. Частые ошибки

#### Ошибки подписания
```
Code signing is required for product type 'Application' in SDK 'iOS'
```
**Решение**: Настройте Team и Bundle Identifier в Signing & Capabilities

#### Ошибки зависимостей
```
No such module 'Supabase'
```
**Решение**: Установите зависимости через Swift Package Manager

#### Ошибки API
```
Invalid API key
```
**Решение**: Проверьте API ключи в Config.swift

### 2. Отладка

#### Логирование
1. Откройте **Console** в Xcode
2. Фильтруйте по вашему приложению
3. Проверьте логи из `LoggingService`

#### Сетевые запросы
1. **Debug** → **View Debugging** → **Network**
2. Проверьте HTTP запросы к API

#### База данных
1. Проверьте подключение к Supabase
2. Проверьте RLS политики
3. Проверьте структуру таблиц

### 3. Производительность

#### Оптимизация сборки
1. **Product** → **Clean Build Folder** (⇧⌘K)
2. Отключите ненужные capabilities
3. Используйте Release конфигурацию

#### Оптимизация приложения
1. Проверьте использование памяти
2. Оптимизируйте сетевые запросы
3. Используйте кэширование

---

## 📚 Дополнительные ресурсы

### Документация
- [Bybit API V5](https://bybit-exchange.github.io/docs/v5/intro)
- [Supabase Swift](https://supabase.com/docs/reference/swift)
- [Apple Sign In](https://developer.apple.com/sign-in-with-apple/)
- [StoreKit 2](https://developer.apple.com/documentation/storekit)

### Сообщество
- [iOS Dev Community](https://iosdev.space/)
- [Swift Forums](https://forums.swift.org/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/ios)

### Поддержка
- Создайте Issue в GitHub репозитории
- Обратитесь в Telegram группу
- Напишите на email поддержки

---

## 🎯 Следующие шаги

1. ✅ Настройте все API ключи
2. ✅ Создайте репозиторий на GitHub
3. ✅ Загрузите код
4. ✅ Протестируйте в симуляторе
5. ✅ Протестируйте на устройстве
6. ✅ Настройте CI/CD (опционально)
7. ✅ Подготовьте к публикации в App Store

---

**Удачи в разработке! 🚀**

Если у вас возникли вопросы, не стесняйтесь обращаться за помощью.

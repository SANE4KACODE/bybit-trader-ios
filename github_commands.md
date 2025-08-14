# Команды для загрузки проекта на GitHub

## 1. Инициализация Git репозитория

```bash
# Перейти в папку проекта
cd "C:\Users\Admin\OneDrive\Desktop\Новая папка (4)"

# Инициализировать Git репозиторий
git init

# Добавить все файлы в staging area
git add .

# Создать первый коммит
git commit -m "Initial commit: Bybit Trader iOS app with complete features"
```

## 2. Создание репозитория на GitHub

1. Перейдите на [github.com](https://github.com)
2. Нажмите "New repository"
3. Введите название: `BybitTrader-iOS`
4. Добавьте описание: `Professional iOS trading app for Bybit with real-time data, AI chat, and advanced analytics`
5. Выберите "Public" или "Private"
6. НЕ ставьте галочки на "Add a README file", "Add .gitignore", "Choose a license"
7. Нажмите "Create repository"

## 3. Подключение к удаленному репозиторию

```bash
# Добавить удаленный репозиторий (замените YOUR_USERNAME на ваше имя пользователя)
git remote add origin https://github.com/YOUR_USERNAME/BybitTrader-iOS.git

# Проверить подключенные репозитории
git remote -v

# Переименовать основную ветку в main (современный стандарт)
git branch -M main

# Отправить код на GitHub
git push -u origin main
```

## 4. Создание .gitignore файла

```bash
# Создать .gitignore файл
echo "# Xcode
.DS_Store
*/build/*
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata
*.xccheckout
*.moved-aside
DerivedData
.idea/
*.hmap
*.ipa
*.xcuserstate
project.xcworkspace

# CocoaPods
Pods/
Podfile.lock

# Carthage
Carthage/Build

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots
fastlane/test_output

# Code Injection
iOSInjectionProject/

# Environment variables
.env
.env.local

# Logs
*.log

# Temporary files
*.tmp
*.temp

# Build artifacts
build/
DerivedData/
*.ipa
*.dSYM.zip
*.dSYM

# Xcode
*.xcworkspace
!default.xcworkspace
*.xcuserstate
*.xcuserdata
*.xcscmblueprint
*.xccheckout
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# Swift Package Manager
.build/
Packages/
Package.pins
Package.resolved
*.xcodeproj

# App packaging
*.ipa
*.dSYM.zip
*.dSYM

# Playgrounds
timeline.xctimeline
playground.xcworkspace

# Swift Package Manager
.build/
Packages/
Package.pins
Package.resolved
*.xcodeproj

# CocoaPods
Pods/
Podfile.lock

# Carthage
Carthage/Build

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots
fastlane/test_output

# Code Injection
iOSInjectionProject/

# Environment variables
.env
.env.local

# Logs
*.log

# Temporary files
*.tmp
*.temp

# Build artifacts
build/
DerivedData/
*.ipa
*.dSYM.zip
*.dSYM" > .gitignore
```

## 5. Обновление .gitignore и повторный коммит

```bash
# Добавить .gitignore файл
git add .gitignore

# Создать коммит с .gitignore
git commit -m "Add .gitignore for iOS project"

# Отправить изменения
git push origin main
```

## 6. Создание README.md на GitHub

После создания репозитория, обновите README.md на GitHub с описанием проекта:

```markdown
# Bybit Trader iOS

Профессиональное iOS приложение для торговли на Bybit с функциями:

## 🚀 Основные возможности

- 📊 Торговля в реальном времени
- 🤖 Встроенный AI чат
- 📈 Расширенная аналитика
- 🔔 Уведомления и ценовые алерты
- 📚 Обучающая система
- 💰 Система подписок
- 🔐 Безопасность и Apple Sign In

## 🛠 Технологии

- Swift & SwiftUI
- Bybit API V5
- Supabase
- Core Data
- StoreKit
- Charts Framework

## 📱 Требования

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## 🔧 Установка

1. Клонируйте репозиторий
2. Откройте `BybitTrader.xcodeproj` в Xcode
3. Настройте API ключи в `Config.swift`
4. Соберите и запустите проект

## 📄 Лицензия

MIT License
```

## 7. Дополнительные команды для работы с репозиторием

```bash
# Проверить статус
git status

# Посмотреть историю коммитов
git log --oneline

# Создать новую ветку для разработки
git checkout -b feature/new-feature

# Переключиться между ветками
git checkout main
git checkout feature/new-feature

# Объединить изменения
git merge feature/new-feature

# Удалить ветку
git branch -d feature/new-feature

# Получить последние изменения
git pull origin main

# Посмотреть изменения в файле
git diff filename.swift
```

## 8. Настройка GitHub Actions (опционально)

Создайте папку `.github/workflows/` и добавьте файл `ios.yml` для автоматической сборки:

```yaml
name: iOS Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Select Xcode
      run: sudo xcode-select -switch /Applications/Xcode.app
      
    - name: Build
      run: |
        xcodebuild -project BybitTrader.xcodeproj -scheme BybitTrader -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build
```

## 9. Полезные команды для разработки

```bash
# Создать тег для версии
git tag -a v1.0.0 -m "Version 1.0.0"
git push origin v1.0.0

# Отменить последний коммит (если не отправлен)
git reset --soft HEAD~1

# Отменить изменения в файле
git checkout -- filename.swift

# Посмотреть размер репозитория
git count-objects -vH

# Очистить историю (осторожно!)
git filter-branch --tree-filter 'rm -rf filename' HEAD
```

## 10. Команды для командной работы

```bash
# Создать pull request (через GitHub веб-интерфейс)
# 1. Создайте ветку для ваших изменений
git checkout -b feature/your-feature

# 2. Внесите изменения и закоммитьте
git add .
git commit -m "Add new feature"

# 3. Отправьте ветку
git push origin feature/your-feature

# 4. Создайте Pull Request на GitHub
```

## ⚠️ Важные замечания

1. **НЕ коммитьте** API ключи и секреты
2. **НЕ коммитьте** файлы сборки (.ipa, .dSYM)
3. **НЕ коммитьте** пользовательские данные
4. Всегда проверяйте `.gitignore` перед коммитом
5. Используйте понятные сообщения коммитов
6. Регулярно делайте `git pull` для получения обновлений

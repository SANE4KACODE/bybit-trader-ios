# 🚀 Инструкция по сборке IPA файла для Bybit Trader

## 📋 Требования

### Системные требования:
- **macOS** (обязательно для сборки iOS приложений)
- **Xcode** версии 15.0 или выше
- **Apple Developer Account** (для подписи и распространения)

### Альтернативные варианты (без macOS):
- **GitHub Actions** (бесплатно)
- **GitLab CI/CD** (бесплатно)
- **Bitrise** (бесплатный план)
- **AppCenter** (бесплатно)

---

## 🍎 Вариант 1: Сборка на macOS (Рекомендуется)

### Шаг 1: Установка Xcode
1. Откройте **App Store** на Mac
2. Найдите **Xcode** и установите
3. Запустите Xcode и примите лицензионное соглашение

### Шаг 2: Настройка проекта
1. Откройте файл `BybitTrader.xcodeproj` в Xcode
2. Выберите **BybitTrader** в навигаторе проекта
3. Перейдите в **Signing & Capabilities**
4. Выберите ваш **Team** (Apple Developer Account)
5. Измените **Bundle Identifier** на уникальный (например: `com.yourname.bybittrader`)

### Шаг 3: Сборка для устройства
1. Подключите iPhone к Mac
2. Выберите ваше устройство в списке устройств
3. Нажмите **Product → Build** (⌘+B)
4. После успешной сборки нажмите **Product → Run** (⌘+R)

### Шаг 4: Создание IPA
1. Выберите **Product → Archive**
2. В **Organizer** выберите созданный архив
3. Нажмите **Distribute App**
4. Выберите **Development** или **Ad Hoc**
5. Выберите **Automatically manage signing**
6. Нажмите **Export** и сохраните IPA файл

---

## ☁️ Вариант 2: GitHub Actions (Бесплатно)

### Шаг 1: Создание GitHub репозитория
1. Создайте новый репозиторий на GitHub
2. Загрузите все файлы проекта
3. Создайте папку `.github/workflows`

### Шаг 2: Создание workflow файла
Создайте файл `.github/workflows/build.yml`:

```yaml
name: Build iOS App

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -switch /Applications/Xcode_15.0.app
      
    - name: Build and Archive
      run: |
        xcodebuild -project BybitTrader.xcodeproj \
                   -scheme BybitTrader \
                   -configuration Release \
                   -destination generic/platform=iOS \
                   -archivePath BybitTrader.xcarchive \
                   archive
                   
    - name: Create IPA
      run: |
        xcodebuild -exportArchive \
                   -archivePath BybitTrader.xcarchive \
                   -exportPath ./build \
                   -exportOptionsPlist exportOptions.plist
                   
    - name: Upload IPA
      uses: actions/upload-artifact@v3
      with:
        name: BybitTrader.ipa
        path: ./build/BybitTrader.ipa
```

### Шаг 3: Создание exportOptions.plist
Создайте файл `exportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

### Шаг 4: Запуск сборки
1. Загрузите все файлы в GitHub
2. Перейдите в **Actions** вкладку
3. Дождитесь завершения сборки
4. Скачайте IPA файл из артефактов

---

## 🔧 Вариант 3: GitLab CI/CD (Бесплатно)

### Шаг 1: Создание .gitlab-ci.yml
Создайте файл `.gitlab-ci.yml`:

```yaml
stages:
  - build

build_ios:
  stage: build
  image: registry.gitlab.com/gitlab-org/incubation-engineering/mobile-devops/gitlab-ios
  before_script:
    - gem install cocoapods
    - pod install --repo-update
  script:
    - xcodebuild -project BybitTrader.xcodeproj \
                  -scheme BybitTrader \
                  -configuration Release \
                  -destination generic/platform=iOS \
                  -archivePath BybitTrader.xcarchive \
                  archive
    - xcodebuild -exportArchive \
                  -archivePath BybitTrader.xcarchive \
                  -exportPath ./build \
                  -exportOptionsPlist exportOptions.plist
  artifacts:
    paths:
      - build/BybitTrader.ipa
    expire_in: 1 week
  only:
    - main
```

---

## 📱 Вариант 4: Bitrise (Бесплатно)

### Шаг 1: Регистрация
1. Зайдите на [bitrise.io](https://bitrise.io)
2. Создайте аккаунт и подключите GitHub/GitLab

### Шаг 2: Создание приложения
1. Нажмите **Add new app**
2. Выберите ваш репозиторий
3. Выберите **iOS** как тип приложения

### Шаг 3: Настройка workflow
Используйте готовый iOS workflow или создайте свой:

```yaml
workflows:
  primary:
    steps:
    - activate-ssh-key@4:
        run_if: '{{getenv "SSH_RSA_PRIVATE_KEY" | ne ""}}'
    - git-clone@0: {}
    - cache-pull@2: {}
    - script@1:
        title: Do anything with Script step
    - xcode-archive@4:
        inputs:
        - project_path: "$BITRISE_PROJECT_PATH"
        - scheme: "$BITRISE_SCHEME"
        - export_method: "development"
        - configuration: "Release"
    - deploy-to-bitrise-io@2: {}
    - cache-push@2: {}
```

---

## 🚀 Вариант 5: AppCenter (Бесплатно)

### Шаг 1: Регистрация
1. Зайдите на [appcenter.ms](https://appcenter.ms)
2. Создайте аккаунт Microsoft

### Шаг 2: Создание приложения
1. Нажмите **Add new app**
2. Выберите **iOS** и подключите репозиторий

### Шаг 3: Настройка сборки
1. Перейдите в **Build** раздел
2. Настройте ветку и конфигурацию
3. Нажмите **Build** для запуска сборки

---

## 🔐 Настройка подписи

### Для всех вариантов:
1. **Получите Apple Developer Account** ($99/год)
2. **Создайте App ID** в Developer Portal
3. **Создайте Provisioning Profile**
4. **Создайте Distribution Certificate**

### Автоматическое управление подписью:
```xml
<!-- В exportOptions.plist -->
<key>signingStyle</key>
<string>automatic</string>
<key>teamID</key>
<string>YOUR_TEAM_ID</string>
```

---

## 📦 Установка IPA на устройство

### Способ 1: iTunes/Finder
1. Подключите iPhone к компьютеру
2. Откройте **Finder** (macOS Catalina+) или **iTunes**
3. Перетащите IPA файл в раздел **Apps**

### Способ 2: AltStore (Без компьютера)
1. Установите **AltStore** на iPhone
2. Загрузите IPA файл через браузер
3. Откройте в AltStore и установите

### Способ 3: TestFlight
1. Загрузите приложение в App Store Connect
2. Добавьте тестеров
3. Они получат приглашение по email

---

## ⚠️ Важные замечания

### Безопасность:
- **Никогда не загружайте API ключи** в публичные репозитории
- Используйте **Environment Variables** для секретов
- Добавьте `.env` в `.gitignore`

### Ограничения:
- **TestFlight** требует одобрения Apple (1-7 дней)
- **Ad Hoc** работает только с зарегистрированными устройствами
- **Development** профиль работает 7 дней

### Альтернативы:
- **React Native** - можно собирать на Windows/Linux
- **Flutter** - кроссплатформенная разработка
- **Xamarin** - .NET для мобильных приложений

---

## 🆘 Решение проблем

### Ошибка подписи:
```bash
# Проверьте сертификаты
security find-identity -v -p codesigning

# Очистите кэш
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Ошибка сборки:
```bash
# Очистите проект
xcodebuild clean -project BybitTrader.xcodeproj

# Обновите зависимости
pod update
```

### Проблемы с устройствами:
1. Убедитесь, что устройство добавлено в Provisioning Profile
2. Проверьте, что Bundle ID совпадает
3. Перезапустите Xcode и устройство

---

## 📚 Полезные ссылки

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [GitHub Actions для iOS](https://docs.github.com/en/actions/guides/building-and-testing-swift)
- [Bitrise iOS Guide](https://devcenter.bitrise.io/en/getting-started/getting-started-with-ios-apps.html)
- [AppCenter Build](https://docs.microsoft.com/en-us/appcenter/build/ios/)

---

## 🎯 Заключение

**Рекомендуемый способ**: Используйте **GitHub Actions** для бесплатной автоматической сборки IPA файлов. Это позволит вам:

✅ Собирать приложения без macOS  
✅ Автоматизировать процесс сборки  
✅ Получать уведомления об ошибках  
✅ Хранить историю сборок  
✅ Работать в команде  

Для профессиональной разработки рекомендуется использовать **macOS + Xcode** для полного контроля над процессом сборки и отладки.

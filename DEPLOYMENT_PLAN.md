# План развертывания BybitTrader на GitHub и Bitrise.io

## 🚀 Быстрый старт

### 1. Запустите автоматический скрипт
```powershell
.\setup_github.ps1
```

### 2. Следуйте инструкциям на экране
- Введите имя пользователя GitHub
- Подтвердите выполнение команд

## 📋 Пошаговый план действий

### Этап 1: Настройка GitHub (15-20 минут)

#### Шаг 1.1: Создание репозитория
1. Перейдите на [github.com](https://github.com)
2. Войдите в свой аккаунт
3. Нажмите "+" → "New repository"
4. Заполните форму:
   - **Repository name:** `BybitTrader`
   - **Description:** `iOS trading app for Bybit exchange with AI features`
   - **Visibility:** Public или Private
   - ❌ НЕ ставьте галочки на README, .gitignore, license
5. Нажмите "Create repository"

#### Шаг 1.2: Подключение локального репозитория
Выполните команды в терминале:
```bash
git remote add origin https://github.com/YOUR_USERNAME/BybitTrader.git
git branch -M main
git push -u origin main
```

#### Шаг 1.3: Создание ветки develop
```bash
git checkout -b develop
git push -u origin develop
```

#### Шаг 1.4: Настройка защиты веток (опционально)
1. Перейдите в Settings → Branches
2. Нажмите "Add rule" для ветки `main`
3. Включите:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging

### Этап 2: Настройка Bitrise.io (30-45 минут)

#### Шаг 2.1: Создание аккаунта
1. Перейдите на [bitrise.io](https://bitrise.io)
2. Нажмите "Sign up for free"
3. Выберите "Sign up with GitHub"
4. Авторизуйтесь через GitHub
5. Подтвердите доступ к репозиториям

#### Шаг 2.2: Добавление приложения
1. Нажмите "Add new app"
2. Выберите тип репозитория (Private/Public)
3. Выберите GitHub как Git hosting service
4. Выберите репозиторий `BybitTrader`
5. Нажмите "Next"

#### Шаг 2.3: Настройка доступа к репозиторию
1. **Setup repository access:**
   - Выберите "SSH key" (рекомендуется)
   - Нажмите "Next"

2. **Select branch:**
   - Выберите ветку `main`
   - Нажмите "Next"

3. **Project scan:**
   - Bitrise автоматически определит iOS проект
   - Нажмите "Next"

4. **Project configuration:**
   - **Project path:** `BybitTrader.xcodeproj`
   - **Scheme name:** `BybitTrader`
   - **Export method:** `app-store`
   - Нажмите "Next"

5. **Webhook setup:**
   - Оставьте включенным webhook
   - Нажмите "Next"

#### Шаг 2.4: Настройка Workflow
1. Выберите "Primary" workflow
2. Нажмите "Next"
3. Нажмите "Finish"

### Этап 3: Настройка переменных окружения (20-30 минут)

#### Шаг 3.1: Подготовка данных
1. **Apple Developer Account:**
   - APPLE_ID: ваш Apple ID email
   - APPLE_APP_PASSWORD: app-specific password
   - TEAM_ID: Team ID из Developer Portal
   - BUNDLE_IDENTIFIER: Bundle ID приложения

2. **SSH ключи:**
   - Создайте SSH ключ: `ssh-keygen -t rsa -b 4096 -C "your.email@example.com"`
   - Добавьте публичный ключ в GitHub
   - Скопируйте приватный ключ

#### Шаг 3.2: Добавление переменных в Bitrise
1. Перейдите в настройки приложения
2. Выберите "Environment variables"
3. Добавьте все переменные из `bitrise_env_vars.md`
4. Отметьте секретные данные как "Is sensitive"

### Этап 4: Настройка Code Signing (15-20 минут)

#### Шаг 4.1: Загрузка файлов
1. Перейдите в "Code signing & files"
2. Загрузите:
   - **Provisioning Profile:** `.mobileprovision` файл
   - **Code Signing Identity:** `.p12` файл
   - **Keychain password:** пароль от ключа

#### Шаг 4.2: Проверка настроек
1. Убедитесь, что все файлы загружены
2. Проверьте, что переменные окружения доступны

### Этап 5: Первая сборка и тестирование (10-15 минут)

#### Шаг 5.1: Запуск сборки
1. Нажмите "Start/Schedule a build"
2. Выберите ветку `main`
3. Нажмите "Start build"

#### Шаг 5.2: Мониторинг
1. Следите за прогрессом сборки
2. Проверьте логи на наличие ошибок
3. Убедитесь, что все шаги выполнены успешно

## 🔧 Дополнительные настройки

### GitHub Actions (опционально)
Создайте файл `.github/workflows/ci.yml` для дополнительной автоматизации.

### Slack уведомления
1. Создайте Slack App
2. Настройте webhook
3. Добавьте `SLACK_WEBHOOK_URL` в переменные Bitrise

### Мониторинг и метрики
1. Настройте уведомления в Bitrise
2. Добавьте email уведомления
3. Настройте метрики сборки

## 📚 Полезные ресурсы

- [GitHub Setup Guide](GITHUB_SETUP.md) - подробная настройка GitHub
- [Bitrise Setup Guide](BITRISE_SETUP.md) - подробная настройка Bitrise
- [Environment Variables](bitrise_env_vars.md) - переменные окружения
- [Bitrise Configuration](.bitrise.yml) - конфигурация CI/CD

## ⚠️ Частые проблемы и решения

### Проблема: Ошибка SSH ключа
**Решение:** Проверьте, что SSH ключ добавлен в GitHub и правильно настроен в Bitrise.

### Проблема: Ошибка Code Signing
**Решение:** Убедитесь, что все файлы подписи загружены и переменные окружения настроены.

### Проблема: Ошибка сборки Xcode
**Решение:** Проверьте версию Xcode в `.bitrise.yml` и убедитесь, что проект компилируется локально.

## 🎯 Следующие шаги

После успешной настройки:

1. **Настройте автоматические триггеры** в Bitrise
2. **Создайте ветки для разработки** (feature/, hotfix/)
3. **Настройте Pull Request workflow**
4. **Добавьте тестирование** в CI/CD pipeline
5. **Настройте мониторинг** и уведомления

## 📞 Поддержка

- **GitHub Issues:** создавайте issues в репозитории
- **Bitrise Support:** используйте встроенную поддержку Bitrise
- **Документация:** обратитесь к созданным файлам инструкций

---

**Время выполнения:** 1.5-2 часа  
**Сложность:** Средняя  
**Требования:** GitHub аккаунт, Apple Developer аккаунт, SSH ключи

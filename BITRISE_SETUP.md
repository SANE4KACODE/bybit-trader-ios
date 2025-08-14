# Настройка Bitrise.io для BybitTrader

## Шаг 1: Подготовка к интеграции с Bitrise

Убедитесь, что ваш проект уже загружен на GitHub и содержит файл `bitrise.yml`.

## Шаг 2: Создание аккаунта на Bitrise.io

1. Перейдите на [bitrise.io](https://bitrise.io)
2. Нажмите "Sign up for free"
3. Выберите "Sign up with GitHub"
4. Авторизуйтесь через GitHub
5. Подтвердите доступ к репозиториям

## Шаг 3: Добавление нового приложения

1. Нажмите "Add new app"
2. Выберите "Private" или "Public" (в зависимости от настроек GitHub репозитория)
3. Выберите GitHub как Git hosting service
4. Выберите репозиторий `BybitTrader`
5. Нажмите "Next"

## Шаг 4: Настройка проекта

1. **Setup repository access:**
   - Выберите "SSH key" (рекомендуется) или "HTTPS"
   - Нажмите "Next"

2. **Select branch:**
   - Выберите ветку `main` как основную
   - Нажмите "Next"

3. **Project scan:**
   - Bitrise автоматически определит тип проекта как iOS
   - Проверьте настройки и нажмите "Next"

4. **Project configuration:**
   - **Project (or Workspace) path:** `BybitTrader.xcodeproj` или `BybitTrader.xcworkspace`
   - **Scheme name:** `BybitTrader`
   - **Export method:** `app-store` (для App Store) или `ad-hoc` (для тестирования)
   - Нажмите "Next"

5. **Webhook setup:**
   - Оставьте включенным "Register a webhook for this app"
   - Нажмите "Next"

## Шаг 5: Настройка Workflow

1. **Primary workflow:**
   - Выберите "Primary" workflow
   - Нажмите "Next"

2. **Workflow configuration:**
   - Bitrise автоматически создаст базовый workflow
   - Нажмите "Finish"

## Шаг 6: Настройка переменных окружения

1. Перейдите в настройки приложения
2. Выберите "Code signing & files"
3. Добавьте необходимые файлы:
   - **Provisioning Profile:** загрузите `.mobileprovision` файл
   - **Code Signing Identity:** загрузите `.p12` файл
   - **Keychain password:** добавьте пароль от ключа

4. Перейдите в "Environment variables"
5. Добавьте переменные:
   ```
   APPLE_ID=your.apple.id@example.com
   APPLE_APP_PASSWORD=your-app-specific-password
   TEAM_ID=your-team-id
   BUNDLE_IDENTIFIER=com.yourcompany.bybittrader
   ```

## Шаг 7: Настройка Workflow Editor

1. Перейдите в "Workflows"
2. Выберите "Primary" workflow
3. Настройте следующие шаги:

### Основные шаги для iOS приложения:

1. **Activate SSH Key** - для доступа к репозиторию
2. **Git Clone Repository** - клонирование кода
3. **Cache Pull** - загрузка кэша
4. **Install Xcode** - установка Xcode
5. **Install CocoaPods** - установка зависимостей
6. **Xcode Archive** - архивирование приложения
7. **Xcode Build** - сборка приложения
8. **Deploy to Bitrise.io** - загрузка артефактов
9. **Deploy to iTunes Connect** - загрузка в App Store (опционально)

## Шаг 8: Настройка автоматических триггеров

1. Перейдите в "Triggers"
2. Настройте триггеры:
   - **Push:** автоматическая сборка при push в ветку `main`
   - **Pull Request:** сборка при создании PR
   - **Tag:** сборка при создании тега

## Шаг 9: Первая сборка

1. Нажмите "Start/Schedule a build"
2. Выберите ветку `main`
3. Нажмите "Start build"

## Шаг 10: Мониторинг и уведомления

1. Настройте уведомления в "Settings" → "Notifications"
2. Добавьте email, Slack или другие каналы
3. Настройте условия уведомлений (успех/неудача)

## Полезные советы

### Оптимизация сборки:
- Используйте кэширование для CocoaPods и Xcode
- Настройте параллельные сборки для разных веток
- Используйте conditional steps для оптимизации

### Безопасность:
- Никогда не коммитьте секретные ключи в код
- Используйте переменные окружения для конфиденциальных данных
- Регулярно обновляйте provisioning profiles

### Мониторинг:
- Настройте метрики сборки
- Отслеживайте время сборки
- Анализируйте логи для оптимизации

## Пример настройки workflow

Создайте файл `.bitrise.yml` в корне проекта для более детальной настройки:

```yaml
format_version: "11"
default_step_lib_source: https://github.com/bitrise-io/bitrise-steplib.git

app:
  envs:
  - APPLE_ID: $APPLE_ID
  - APPLE_APP_PASSWORD: $APPLE_APP_PASSWORD
  - TEAM_ID: $TEAM_ID
  - BUNDLE_IDENTIFIER: $BUNDLE_IDENTIFIER

workflows:
  primary:
    steps:
    - activate-ssh-key@4:
        run_if: '{{getenv "SSH_RSA_PRIVATE_KEY" | ne ""}}'
    - git-clone@0: {}
    - cache-pull@2: {}
    - install-xcode@0:
        inputs:
        - xcode_version: "15.0"
    - install-cocoapods@1: {}
    - xcode-archive@4:
        inputs:
        - project_path: "BybitTrader.xcodeproj"
        - scheme: "BybitTrader"
        - export_method: "app-store"
        - configuration: "Release"
    - deploy-to-bitrise-io@2: {}
    - deploy-to-itunesconnect-application-loader@1:
        inputs:
        - app_id: $APPLE_ID
        - password: $APPLE_APP_PASSWORD
        - team_id: $TEAM_ID
        - ipa_path: "$BITRISE_APK_PATH"
        run_if: '{{getenv "DEPLOY_TO_ITUNES" | eq "true"}}'
```

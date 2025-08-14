# Переменные окружения для Bitrise

## Обязательные переменные

### Apple Developer Account
```
APPLE_ID=your.apple.id@example.com
APPLE_APP_PASSWORD=your-app-specific-password
TEAM_ID=your-team-id
BUNDLE_IDENTIFIER=com.yourcompany.bybittrader
```

### SSH ключи для доступа к GitHub
```
SSH_RSA_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
ваш_приватный_ключ_ssh
-----END OPENSSH PRIVATE KEY-----
```

## Опциональные переменные

### Slack уведомления
```
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

### Деплой в App Store
```
DEPLOY_TO_ITUNES=true
```

### Настройки проекта
```
XCODE_VERSION=15.0
PROJECT_PATH=BybitTrader.xcodeproj
SCHEME_NAME=BybitTrader
EXPORT_METHOD=app-store
CONFIGURATION=Release
```

## Как получить значения

### 1. APPLE_ID
- Ваш Apple ID email адрес
- Пример: `developer@company.com`

### 2. APPLE_APP_PASSWORD
- App-specific password для вашего Apple ID
- Создайте в [appleid.apple.com](https://appleid.apple.com)
- Включите двухфакторную аутентификацию
- Создайте пароль для "App Store Connect"

### 3. TEAM_ID
- Team ID из Apple Developer Portal
- Найти в [developer.apple.com](https://developer.apple.com)
- Перейдите в "Membership" → "Team ID"

### 4. BUNDLE_IDENTIFIER
- Bundle ID вашего приложения
- Формат: `com.company.appname`
- Пример: `com.bybittrader.ios`

### 5. SSH_RSA_PRIVATE_KEY
- Приватный SSH ключ для доступа к GitHub
- Создайте новый ключ:
```bash
ssh-keygen -t rsa -b 4096 -C "your.email@example.com"
```
- Добавьте публичный ключ в GitHub Settings → SSH and GPG keys
- Скопируйте содержимое приватного ключа (включая BEGIN и END строки)

### 6. SLACK_WEBHOOK_URL
- Webhook URL для Slack уведомлений
- Создайте в Slack App settings
- Добавьте в канал #bybittrader

## Где добавить переменные в Bitrise

1. Перейдите в настройки приложения
2. Выберите "Environment variables"
3. Добавьте каждую переменную:
   - **Key:** имя переменной (например, APPLE_ID)
   - **Value:** значение переменной
   - **Is sensitive:** отметьте для секретных данных (пароли, ключи)

## Проверка переменных

После добавления переменных:

1. Запустите тестовую сборку
2. Проверьте логи на наличие ошибок
3. Убедитесь, что все переменные доступны в workflow

## Безопасность

- Никогда не коммитьте секретные данные в код
- Используйте переменные окружения для всех секретов
- Регулярно обновляйте пароли и ключи
- Ограничьте доступ к переменным только необходимыми пользователями

# Команды для загрузки проекта на GitHub

## 🚀 Подготовка к загрузке

### 1. Инициализация Git репозитория
```bash
# Перейдите в папку проекта
cd "C:\Users\Admin\OneDrive\Desktop\Новая папка (4)"

# Инициализируйте Git репозиторий
git init

# Проверьте статус
git status
```

### 2. Настройка Git конфигурации
```bash
# Установите ваше имя пользователя
git config user.name "ВашеИмяПользователя"

# Установите ваш email
git config user.email "ваш.email@example.com"

# Проверьте настройки
git config --list
```

### 3. Создание .gitignore файла
```bash
# Создайте .gitignore файл (если его нет)
# Файл уже создан в проекте
```

## 📁 Добавление файлов в репозиторий

### 4. Добавление всех файлов
```bash
# Добавьте все файлы в staging area
git add .

# Проверьте статус
git status
```

### 5. Первый коммит
```bash
# Создайте первый коммит
git commit -m "Initial commit: Bybit Trader iOS app

- Complete iOS trading application
- Bybit API integration
- Real-time data and charts
- Advanced animations and UI
- Subscription system
- AI chat integration
- Comprehensive error handling
- Local and cloud database
- Security features
- Learning system"
```

## 🔗 Подключение к GitHub

### 6. Создание репозитория на GitHub
1. Перейдите на [github.com](https://github.com)
2. Нажмите "New repository"
3. Введите название: `bybit-trader-ios`
4. Описание: `Professional iOS trading app for Bybit exchange`
5. Выберите "Public" или "Private"
6. НЕ ставьте галочки на README, .gitignore, license
7. Нажмите "Create repository"

### 7. Подключение удаленного репозитория
```bash
# Добавьте удаленный репозиторий
git remote add origin https://github.com/ВАШЕ_ИМЯ_ПОЛЬЗОВАТЕЛЯ/bybit-trader-ios.git

# Проверьте подключение
git remote -v
```

### 8. Переименование основной ветки (если нужно)
```bash
# Переименуйте ветку в main (современный стандарт)
git branch -M main

# Или оставьте master
# git branch -M master
```

## 📤 Загрузка на GitHub

### 9. Push в удаленный репозиторий
```bash
# Загрузите код на GitHub
git push -u origin main

# Если используете master ветку
# git push -u origin master
```

### 10. Проверка загрузки
```bash
# Проверьте статус
git status

# Проверьте логи
git log --oneline
```

## 🔄 Дальнейшая работа

### 11. Обновление кода
```bash
# После внесения изменений
git add .
git commit -m "Описание изменений"
git push
```

### 12. Создание веток для новых функций
```bash
# Создайте новую ветку
git checkout -b feature/new-feature

# Внесите изменения
git add .
git commit -m "Add new feature"

# Загрузите ветку
git push -u origin feature/new-feature
```

### 13. Слияние изменений
```bash
# Переключитесь на основную ветку
git checkout main

# Получите последние изменения
git pull origin main

# Слейте feature ветку
git merge feature/new-feature

# Загрузите изменения
git push origin main
```

## 🛠 Дополнительные команды

### 14. Просмотр истории
```bash
# Краткая история коммитов
git log --oneline

# Подробная история
git log --graph --oneline --all

# История конкретного файла
git log --follow -- filename
```

### 15. Отмена изменений
```bash
# Отмена последнего коммита
git reset --soft HEAD~1

# Отмена изменений в файле
git checkout -- filename

# Отмена всех изменений
git reset --hard HEAD
```

### 16. Работа с ветками
```bash
# Список всех веток
git branch -a

# Создание новой ветки
git branch branch-name

# Переключение между ветками
git checkout branch-name

# Удаление ветки
git branch -d branch-name
```

## 📋 Полный скрипт загрузки

### PowerShell скрипт (github_upload.ps1)
```powershell
# Скрипт для автоматической загрузки на GitHub
Write-Host "🚀 Начинаем загрузку проекта на GitHub..." -ForegroundColor Green

# Переходим в папку проекта
Set-Location "C:\Users\Admin\OneDrive\Desktop\Новая папка (4)"

# Инициализируем Git
if (-not (Test-Path ".git")) {
    Write-Host "📁 Инициализируем Git репозиторий..." -ForegroundColor Yellow
    git init
}

# Добавляем все файлы
Write-Host "📁 Добавляем файлы в репозиторий..." -ForegroundColor Yellow
git add .

# Проверяем статус
Write-Host "📊 Статус репозитория:" -ForegroundColor Cyan
git status

# Создаем первый коммит
Write-Host "💾 Создаем первый коммит..." -ForegroundColor Yellow
git commit -m "Initial commit: Bybit Trader iOS app

- Complete iOS trading application
- Bybit API integration
- Real-time data and charts
- Advanced animations and UI
- Subscription system
- AI chat integration
- Comprehensive error handling
- Local and cloud database
- Security features
- Learning system"

# Добавляем удаленный репозиторий
Write-Host "🔗 Добавляем удаленный репозиторий..." -ForegroundColor Yellow
git remote add origin https://github.com/ВАШЕ_ИМЯ_ПОЛЬЗОВАТЕЛЯ/bybit-trader-ios.git

# Переименовываем ветку в main
Write-Host "🌿 Переименовываем ветку в main..." -ForegroundColor Yellow
git branch -M main

# Загружаем на GitHub
Write-Host "📤 Загружаем код на GitHub..." -ForegroundColor Yellow
git push -u origin main

Write-Host "✅ Проект успешно загружен на GitHub!" -ForegroundColor Green
Write-Host "🔗 Ссылка: https://github.com/ВАШЕ_ИМЯ_ПОЛЬЗОВАТЕЛЯ/bybit-trader-ios" -ForegroundColor Cyan
```

### Batch скрипт (github_upload.bat)
```batch
@echo off
echo 🚀 Начинаем загрузку проекта на GitHub...

REM Переходим в папку проекта
cd /d "C:\Users\Admin\OneDrive\Desktop\Новая папка (4)"

REM Инициализируем Git
if not exist ".git" (
    echo 📁 Инициализируем Git репозиторий...
    git init
)

REM Добавляем все файлы
echo 📁 Добавляем файлы в репозиторий...
git add .

REM Проверяем статус
echo 📊 Статус репозитория:
git status

REM Создаем первый коммит
echo 💾 Создаем первый коммит...
git commit -m "Initial commit: Bybit Trader iOS app"

REM Добавляем удаленный репозиторий
echo 🔗 Добавляем удаленный репозиторий...
git remote add origin https://github.com/ВАШЕ_ИМЯ_ПОЛЬЗОВАТЕЛЯ/bybit-trader-ios.git

REM Переименовываем ветку в main
echo 🌿 Переименовываем ветку в main...
git branch -M main

REM Загружаем на GitHub
echo 📤 Загружаем код на GitHub...
git push -u origin main

echo ✅ Проект успешно загружен на GitHub!
echo 🔗 Ссылка: https://github.com/ВАШЕ_ИМЯ_ПОЛЬЗОВАТЕЛЯ/bybit-trader-ios
pause
```

## ⚠️ Важные замечания

### Безопасность
- **НЕ загружайте** API ключи в репозиторий
- **НЕ загружайте** файлы с паролями
- **НЕ загружайте** личные данные пользователей
- **Проверьте** .gitignore файл перед загрузкой

### Проверка перед загрузкой
```bash
# Проверьте, какие файлы будут загружены
git status

# Проверьте содержимое .gitignore
cat .gitignore

# Проверьте, что конфиденциальные файлы не попадут в репозиторий
git check-ignore Config.swift
git check-ignore *.plist
```

### После загрузки
1. Проверьте репозиторий на GitHub
2. Убедитесь, что все файлы загружены
3. Проверьте, что конфиденциальные данные не попали в репозиторий
4. Настройте защиту ветки main
5. Добавьте описание проекта
6. Настройте теги и релизы

## 🎯 Следующие шаги

После успешной загрузки на GitHub:

1. **Настройте GitHub Pages** для документации
2. **Создайте Issues** для планирования функций
3. **Настройте Actions** для автоматической сборки
4. **Добавьте Contributors** в проект
5. **Создайте Wiki** с подробной документацией
6. **Настройте Discussions** для обсуждений
7. **Добавьте Project** для управления задачами

## 📞 Поддержка

Если возникли проблемы:

1. Проверьте логи Git: `git log --oneline`
2. Проверьте статус: `git status`
3. Проверьте удаленные репозитории: `git remote -v`
4. Обратитесь к [GitHub Help](https://help.github.com)
5. Создайте Issue в репозитории

---

**Удачи с загрузкой проекта! 🚀**

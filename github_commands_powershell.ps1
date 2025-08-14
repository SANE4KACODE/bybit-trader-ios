# PowerShell скрипт для загрузки проекта Bybit Trader на GitHub
# Запустите этот скрипт от имени администратора

Write-Host "🚀 Начинаем загрузку проекта Bybit Trader на GitHub..." -ForegroundColor Green

# 1. Проверяем, установлен ли Git
Write-Host "📋 Проверяем установку Git..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "✅ Git установлен: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git не установлен. Установите Git с https://git-scm.com/" -ForegroundColor Red
    exit 1
}

# 2. Переходим в папку проекта
Write-Host "📁 Переходим в папку проекта..." -ForegroundColor Yellow
$projectPath = "C:\Users\Admin\OneDrive\Desktop\Новая папка (4)"
if (Test-Path $projectPath) {
    Set-Location $projectPath
    Write-Host "✅ Перешли в папку: $projectPath" -ForegroundColor Green
} else {
    Write-Host "❌ Папка проекта не найдена: $projectPath" -ForegroundColor Red
    exit 1
}

# 3. Проверяем, инициализирован ли уже Git
Write-Host "🔍 Проверяем статус Git репозитория..." -ForegroundColor Yellow
if (Test-Path ".git") {
    Write-Host "✅ Git репозиторий уже инициализирован" -ForegroundColor Green
} else {
    Write-Host "📝 Инициализируем Git репозиторий..." -ForegroundColor Yellow
    git init
    Write-Host "✅ Git репозиторий инициализирован" -ForegroundColor Green
}

# 4. Настраиваем Git пользователя (если не настроен)
Write-Host "👤 Настраиваем Git пользователя..." -ForegroundColor Yellow
$userName = git config --global user.name
$userEmail = git config --global user.email

if (-not $userName) {
    $userName = Read-Host "Введите ваше имя для Git"
    git config --global user.name $userName
}

if (-not $userEmail) {
    $userEmail = Read-Host "Введите ваш email для Git"
    git config --global user.email $userEmail
}

Write-Host "✅ Git пользователь настроен: $userName <$userEmail>" -ForegroundColor Green

# 5. Добавляем все файлы в staging area
Write-Host "📦 Добавляем файлы в staging area..." -ForegroundColor Yellow
git add .
Write-Host "✅ Файлы добавлены" -ForegroundColor Green

# 6. Создаем первый коммит
Write-Host "💾 Создаем первый коммит..." -ForegroundColor Yellow
git commit -m "Initial commit: Bybit Trader iOS app with complete features"
Write-Host "✅ Первый коммит создан" -ForegroundColor Green

# 7. Переименовываем основную ветку в main
Write-Host "🌿 Переименовываем ветку в main..." -ForegroundColor Yellow
git branch -M main
Write-Host "✅ Ветка переименована в main" -ForegroundColor Green

# 8. Запрашиваем URL репозитория
Write-Host "🔗 Настройка удаленного репозитория..." -ForegroundColor Yellow
Write-Host "Создайте репозиторий на GitHub:" -ForegroundColor Cyan
Write-Host "1. Перейдите на https://github.com" -ForegroundColor Cyan
Write-Host "2. Нажмите 'New repository'" -ForegroundColor Cyan
Write-Host "3. Название: BybitTrader-iOS" -ForegroundColor Cyan
Write-Host "4. Описание: Professional iOS trading app for Bybit" -ForegroundColor Cyan
Write-Host "5. Выберите Public или Private" -ForegroundColor Cyan
Write-Host "6. НЕ ставьте галочки на README, .gitignore, license" -ForegroundColor Cyan
Write-Host "7. Нажмите 'Create repository'" -ForegroundColor Cyan

$repoUrl = Read-Host "Введите URL вашего GitHub репозитория (например: https://github.com/username/BybitTrader-iOS.git)"

# 9. Добавляем удаленный репозиторий
Write-Host "🌐 Добавляем удаленный репозиторий..." -ForegroundColor Yellow
git remote add origin $repoUrl
Write-Host "✅ Удаленный репозиторий добавлен" -ForegroundColor Green

# 10. Проверяем подключенные репозитории
Write-Host "🔍 Проверяем подключенные репозитории..." -ForegroundColor Yellow
git remote -v

# 11. Отправляем код на GitHub
Write-Host "🚀 Отправляем код на GitHub..." -ForegroundColor Yellow
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Код успешно отправлен на GitHub!" -ForegroundColor Green
    Write-Host "🎉 Проект Bybit Trader загружен на GitHub!" -ForegroundColor Green
    Write-Host "🔗 Ваш репозиторий: $repoUrl" -ForegroundColor Cyan
} else {
    Write-Host "❌ Ошибка при отправке кода на GitHub" -ForegroundColor Red
    Write-Host "Проверьте URL репозитория и попробуйте снова" -ForegroundColor Yellow
}

# 12. Показываем статус
Write-Host "📊 Статус репозитория:" -ForegroundColor Yellow
git status

Write-Host "`n🎯 Следующие шаги:" -ForegroundColor Green
Write-Host "1. Перейдите в ваш репозиторий на GitHub" -ForegroundColor Cyan
Write-Host "2. Обновите README.md с описанием проекта" -ForegroundColor Cyan
Write-Host "3. Настройте GitHub Actions для автоматической сборки" -ForegroundColor Cyan
Write-Host "4. Добавьте теги для версий: git tag -a v1.0.0 -m 'Version 1.0.0'" -ForegroundColor Cyan

Write-Host "`n✅ Скрипт завершен!" -ForegroundColor Green

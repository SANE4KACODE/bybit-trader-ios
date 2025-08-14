# Скрипт для автоматической загрузки проекта Bybit Trader iOS на GitHub
# Автор: AI Assistant
# Дата: $(Get-Date -Format "yyyy-MM-dd")

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    
    [Parameter(Mandatory=$false)]
    [string]$RepositoryName = "bybit-trader-ios",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = "C:\Users\Admin\OneDrive\Desktop\Новая папка (4)"
)

# Цвета для вывода
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"
$Red = "Red"
$White = "White"

# Функция для красивого вывода
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = $White
    )
    Write-Host $Message -ForegroundColor $Color
}

# Функция для проверки ошибок
function Test-CommandSuccess {
    param(
        [string]$Command,
        [string]$ErrorMessage
    )
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Ошибка: $ErrorMessage" $Red
        Write-ColorOutput "Команда: $Command" $Red
        exit 1
    }
}

# Начало скрипта
Write-ColorOutput "🚀 Начинаем загрузку проекта Bybit Trader iOS на GitHub..." $Green
Write-ColorOutput "📁 Путь к проекту: $ProjectPath" $Cyan
Write-ColorOutput "👤 GitHub пользователь: $GitHubUsername" $Cyan
Write-ColorOutput "📦 Название репозитория: $RepositoryName" $Cyan
Write-ColorOutput ""

# Проверяем существование папки проекта
if (-not (Test-Path $ProjectPath)) {
    Write-ColorOutput "❌ Ошибка: Папка проекта не найдена!" $Red
    Write-ColorOutput "Путь: $ProjectPath" $Red
    exit 1
}

# Переходим в папку проекта
Write-ColorOutput "📁 Переходим в папку проекта..." $Yellow
Set-Location $ProjectPath
Write-ColorOutput "✅ Текущая папка: $(Get-Location)" $Green

# Проверяем, является ли это Git репозиторием
$isGitRepo = Test-Path ".git"
if ($isGitRepo) {
    Write-ColorOutput "📁 Git репозиторий уже инициализирован" $Cyan
} else {
    Write-ColorOutput "📁 Инициализируем Git репозиторий..." $Yellow
    git init
    Test-CommandSuccess "git init" "Не удалось инициализировать Git репозиторий"
    Write-ColorOutput "✅ Git репозиторий инициализирован" $Green
}

# Проверяем Git конфигурацию
Write-ColorOutput "⚙️ Проверяем Git конфигурацию..." $Yellow
$userName = git config user.name
$userEmail = git config user.email

if (-not $userName -or -not $userEmail) {
    Write-ColorOutput "⚠️ Git конфигурация не настроена" $Yellow
    Write-ColorOutput "Пожалуйста, настройте Git перед продолжением:" $Yellow
    Write-ColorOutput "git config user.name 'Ваше Имя'" $Cyan
    Write-ColorOutput "git config user.email 'ваш.email@example.com'" $Cyan
    Write-ColorOutput ""
    Write-ColorOutput "Нажмите Enter после настройки..." $Yellow
    Read-Host
} else {
    Write-ColorOutput "✅ Git конфигурация настроена:" $Green
    Write-ColorOutput "   Имя: $userName" $Cyan
    Write-ColorOutput "   Email: $userEmail" $Cyan
}

# Проверяем .gitignore
Write-ColorOutput "🔒 Проверяем .gitignore файл..." $Yellow
if (Test-Path ".gitignore") {
    Write-ColorOutput "✅ .gitignore файл найден" $Green
    $gitignoreContent = Get-Content ".gitignore" | Select-Object -First 10
    Write-ColorOutput "📋 Содержимое .gitignore (первые 10 строк):" $Cyan
    $gitignoreContent | ForEach-Object { Write-ColorOutput "   $_" $Cyan }
} else {
    Write-ColorOutput "⚠️ .gitignore файл не найден!" $Yellow
    Write-ColorOutput "Рекомендуется создать .gitignore перед загрузкой" $Yellow
}

# Проверяем статус репозитория
Write-ColorOutput "📊 Проверяем статус репозитория..." $Yellow
git status
Write-ColorOutput ""

# Добавляем все файлы
Write-ColorOutput "📁 Добавляем все файлы в репозиторий..." $Yellow
git add .
Test-CommandSuccess "git add ." "Не удалось добавить файлы в репозиторий"
Write-ColorOutput "✅ Файлы добавлены" $Green

# Проверяем статус после добавления
Write-ColorOutput "📊 Статус после добавления файлов:" $Yellow
git status
Write-ColorOutput ""

# Создаем первый коммит
Write-ColorOutput "💾 Создаем первый коммит..." $Yellow
$commitMessage = @"
Initial commit: Bybit Trader iOS app

- Complete iOS trading application for Bybit exchange
- Real-time market data and charts
- Advanced animations and particle effects
- Subscription system with trial period
- AI chat integration for trading advice
- Comprehensive error handling and logging
- Local Core Data and cloud Supabase database
- Security features with biometric authentication
- Learning system with courses and articles
- Apple Sign In integration
- Price alerts and notifications
- Trade diary with Excel export
- Portfolio analytics and risk management
- Multi-language support (Russian/English)
- Modern SwiftUI interface with dark/light themes

Built with Swift 5.7+, iOS 15.0+, Xcode 14.0+
"@

git commit -m $commitMessage
Test-CommandSuccess "git commit" "Не удалось создать коммит"
Write-ColorOutput "✅ Коммит создан" $Green

# Проверяем логи
Write-ColorOutput "📋 История коммитов:" $Yellow
git log --oneline -5
Write-ColorOutput ""

# Добавляем удаленный репозиторий
$remoteUrl = "https://github.com/$GitHubUsername/$RepositoryName.git"
Write-ColorOutput "🔗 Добавляем удаленный репозиторий..." $Yellow
Write-ColorOutput "URL: $remoteUrl" $Cyan

# Проверяем, не добавлен ли уже remote
$existingRemote = git remote get-url origin 2>$null
if ($existingRemote) {
    Write-ColorOutput "⚠️ Удаленный репозиторий уже добавлен:" $Yellow
    Write-ColorOutput "   $existingRemote" $Cyan
    
    if ($existingRemote -ne $remoteUrl) {
        Write-ColorOutput "🔄 Обновляем URL удаленного репозитория..." $Yellow
        git remote set-url origin $remoteUrl
        Test-CommandSuccess "git remote set-url" "Не удалось обновить URL удаленного репозитория"
    }
} else {
    git remote add origin $remoteUrl
    Test-CommandSuccess "git remote add origin" "Не удалось добавить удаленный репозиторий"
}

Write-ColorOutput "✅ Удаленный репозиторий настроен" $Green

# Проверяем подключение
Write-ColorOutput "🔗 Проверяем подключение к удаленному репозиторию..." $Yellow
git remote -v
Write-ColorOutput ""

# Переименовываем ветку в main
Write-ColorOutput "🌿 Переименовываем ветку в main..." $Yellow
git branch -M main
Test-CommandSuccess "git branch -M main" "Не удалось переименовать ветку"
Write-ColorOutput "✅ Ветка переименована в main" $Green

# Проверяем текущую ветку
Write-ColorOutput "🌿 Текущая ветка:" $Yellow
git branch
Write-ColorOutput ""

# Загружаем на GitHub
Write-ColorOutput "📤 Загружаем код на GitHub..." $Yellow
Write-ColorOutput "⚠️ Убедитесь, что репозиторий создан на GitHub!" $Yellow
Write-ColorOutput "Ссылка: https://github.com/$GitHubUsername/$RepositoryName" $Cyan
Write-ColorOutput ""
Write-ColorOutput "Нажмите Enter для продолжения..." $Yellow
Read-Host

git push -u origin main
Test-CommandSuccess "git push" "Не удалось загрузить код на GitHub"

# Проверяем финальный статус
Write-ColorOutput "📊 Финальный статус репозитория:" $Yellow
git status
Write-ColorOutput ""

# Проверяем удаленные ветки
Write-ColorOutput "🌿 Удаленные ветки:" $Yellow
git branch -r
Write-ColorOutput ""

# Успешное завершение
Write-ColorOutput "🎉 Проект успешно загружен на GitHub!" $Green
Write-ColorOutput ""
Write-ColorOutput "🔗 Ссылка на репозиторий:" $Cyan
Write-ColorOutput "   https://github.com/$GitHubUsername/$RepositoryName" $Cyan
Write-ColorOutput ""
Write-ColorOutput "📋 Следующие шаги:" $Yellow
Write-ColorOutput "   1. Проверьте репозиторий на GitHub" $White
Write-ColorOutput "   2. Добавьте описание проекта" $White
Write-ColorOutput "   3. Настройте теги и релизы" $White
Write-ColorOutput "   4. Добавьте Contributors" $White
Write-ColorOutput "   5. Создайте Issues для планирования" $White
Write-ColorOutput "   6. Настройте GitHub Actions" $White
Write-ColorOutput ""
Write-ColorOutput "✅ Загрузка завершена успешно!" $Green

# Сохраняем информацию о репозитории
$repoInfo = @{
    GitHubUsername = $GitHubUsername
    RepositoryName = $RepositoryName
    RepositoryUrl = "https://github.com/$GitHubUsername/$RepositoryName"
    UploadDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ProjectPath = $ProjectPath
}

$repoInfoPath = Join-Path $ProjectPath "github_repository_info.json"
$repoInfo | ConvertTo-Json | Out-File -FilePath $repoInfoPath -Encoding UTF8
Write-ColorOutput "💾 Информация о репозитории сохранена в: $repoInfoPath" $Cyan

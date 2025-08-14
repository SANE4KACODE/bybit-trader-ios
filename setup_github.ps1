# Скрипт для настройки GitHub репозитория BybitTrader
# Автор: lubolyad
# Дата: $(Get-Date -Format "yyyy-MM-dd")

Write-Host "=== Настройка GitHub репозитория для BybitTrader ===" -ForegroundColor Green
Write-Host ""

# Проверка Git статуса
Write-Host "Проверка Git статуса..." -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "Обнаружены несохраненные изменения:" -ForegroundColor Red
    Write-Host $gitStatus
    Write-Host ""
    
    $addAll = Read-Host "Добавить все изменения в коммит? (y/n)"
    if ($addAll -eq "y" -or $addAll -eq "Y") {
        git add .
        Write-Host "Все изменения добавлены" -ForegroundColor Green
    }
}

# Проверка последнего коммита
$lastCommit = git log --oneline -1
if ($lastCommit) {
    Write-Host "Последний коммит: $lastCommit" -ForegroundColor Cyan
} else {
    Write-Host "Создание первого коммита..." -ForegroundColor Yellow
    git add .
    git commit -m "Initial commit: BybitTrader iOS app with complete project structure"
    Write-Host "Первый коммит создан" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Инструкции по настройке GitHub ===" -ForegroundColor Green
Write-Host ""

Write-Host "1. Создайте репозиторий на GitHub:" -ForegroundColor White
Write-Host "   - Перейдите на https://github.com" -ForegroundColor Gray
Write-Host "   - Нажмите '+' → 'New repository'" -ForegroundColor Gray
Write-Host "   - Имя: BybitTrader" -ForegroundColor Gray
Write-Host "   - Описание: iOS trading app for Bybit exchange with AI features" -ForegroundColor Gray
Write-Host "   - НЕ ставьте галочки на README, .gitignore, license" -ForegroundColor Gray
Write-Host ""

Write-Host "2. После создания репозитория, выполните следующие команды:" -ForegroundColor White
Write-Host ""

# Получение имени пользователя GitHub
$githubUsername = Read-Host "Введите ваше имя пользователя GitHub"
if ($githubUsername) {
    Write-Host "Команды для выполнения:" -ForegroundColor Cyan
    Write-Host "git remote add origin https://github.com/$githubUsername/BybitTrader.git" -ForegroundColor Yellow
    Write-Host "git branch -M main" -ForegroundColor Yellow
    Write-Host "git push -u origin main" -ForegroundColor Yellow
    Write-Host ""
    
    $executeCommands = Read-Host "Выполнить эти команды автоматически? (y/n)"
    if ($executeCommands -eq "y" -or $executeCommands -eq "Y") {
        Write-Host "Добавление удаленного репозитория..." -ForegroundColor Yellow
        git remote add origin "https://github.com/$githubUsername/BybitTrader.git"
        
        Write-Host "Переименование ветки в main..." -ForegroundColor Yellow
        git branch -M main
        
        Write-Host "Отправка кода на GitHub..." -ForegroundColor Yellow
        git push -u origin main
        
        Write-Host "Код успешно отправлен на GitHub!" -ForegroundColor Green
    }
} else {
    Write-Host "Команды для выполнения (замените YOUR_USERNAME на ваше имя пользователя):" -ForegroundColor Cyan
    Write-Host "git remote add origin https://github.com/YOUR_USERNAME/BybitTrader.git" -ForegroundColor Yellow
    Write-Host "git branch -M main" -ForegroundColor Yellow
    Write-Host "git push -u origin main" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Следующие шаги ===" -ForegroundColor Green
Write-Host "1. Проверьте репозиторий на GitHub" -ForegroundColor White
Write-Host "2. Настройте защиту веток (опционально)" -ForegroundColor White
Write-Host "3. Создайте ветку develop: git checkout -b develop && git push -u origin develop" -ForegroundColor White
Write-Host "4. Перейдите к настройке Bitrise.io" -ForegroundColor White
Write-Host ""

Write-Host "Подробные инструкции сохранены в файлах:" -ForegroundColor Cyan
Write-Host "- GITHUB_SETUP.md - настройка GitHub" -ForegroundColor Gray
Write-Host "- BITRISE_SETUP.md - настройка Bitrise.io" -ForegroundColor Gray
Write-Host ""

Write-Host "Нажмите любую клавишу для завершения..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

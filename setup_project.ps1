# PowerShell скрипт для полной настройки проекта Bybit Trader
# Запустите от имени администратора

param(
    [string]$GitHubUsername = "",
    [string]$GitHubEmail = "",
    [switch]$SkipGitSetup = $false,
    [switch]$SkipConfigSetup = $false
)

# Цвета для вывода
$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-Header {
    param([string]$Message)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor $Colors.Header
    Write-Host "  $Message" -ForegroundColor $Colors.Header
    Write-Host "=" * 60 -ForegroundColor $Colors.Header
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor $Colors.Success
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor $Colors.Warning
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor $Colors.Error
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor $Colors.Info
}

# Проверка прав администратора
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Error "Этот скрипт требует прав администратора. Запустите PowerShell от имени администратора."
    exit 1
}

Write-Header "🚀 Настройка проекта Bybit Trader iOS"

# 1. Проверка системных требований
Write-Header "🔍 Проверка системных требований"

# Проверка Git
try {
    $gitVersion = git --version
    Write-Success "Git установлен: $gitVersion"
} catch {
    Write-Error "Git не установлен. Установите Git с https://git-scm.com/"
    Write-Info "После установки Git перезапустите скрипт."
    exit 1
}

# Проверка Xcode (если на macOS)
if ($IsMacOS) {
    try {
        $xcodeVersion = xcodebuild -version
        Write-Success "Xcode установлен: $xcodeVersion"
    } catch {
        Write-Warning "Xcode не найден. Установите Xcode с App Store."
    }
} else {
    Write-Info "Операционная система: Windows. Xcode требуется только на macOS."
}

# 2. Переход в папку проекта
Write-Header "📁 Настройка рабочей директории"

$projectPath = "C:\Users\Admin\OneDrive\Desktop\Новая папка (4)"
if (Test-Path $projectPath) {
    Set-Location $projectPath
    Write-Success "Перешли в папку проекта: $projectPath"
} else {
    Write-Error "Папка проекта не найдена: $projectPath"
    exit 1
}

# 3. Настройка Git (если не пропущено)
if (-not $SkipGitSetup) {
    Write-Header "👤 Настройка Git"
    
    # Настройка пользователя Git
    if (-not $GitHubUsername) {
        $GitHubUsername = Read-Host "Введите ваше имя пользователя GitHub"
    }
    
    if (-not $GitHubEmail) {
        $GitHubEmail = Read-Host "Введите ваш email для Git"
    }
    
    git config --global user.name $GitHubUsername
    git config --global user.email $GitHubEmail
    Write-Success "Git пользователь настроен: $GitHubUsername <$GitHubEmail>"
    
    # Инициализация Git репозитория
    if (-not (Test-Path ".git")) {
        Write-Info "Инициализация Git репозитория..."
        git init
        Write-Success "Git репозиторий инициализирован"
    } else {
        Write-Info "Git репозиторий уже инициализирован"
    }
    
    # Добавление файлов
    Write-Info "Добавление файлов в Git..."
    git add .
    
    # Первый коммит
    Write-Info "Создание первого коммита..."
    git commit -m "Initial commit: Bybit Trader iOS app with complete features"
    Write-Success "Первый коммит создан"
    
    # Переименование ветки
    git branch -M main
    Write-Success "Основная ветка переименована в main"
    
    # Настройка удаленного репозитория
    Write-Header "🌐 Настройка GitHub репозитория"
    Write-Info "Создайте репозиторий на GitHub:"
    Write-Info "1. Перейдите на https://github.com"
    Write-Info "2. Нажмите 'New repository'"
    Write-Info "3. Название: BybitTrader-iOS"
    Write-Info "4. Описание: Professional iOS trading app for Bybit"
    Write-Info "5. Выберите Public или Private"
    Write-Info "6. НЕ ставьте галочки на README, .gitignore, license"
    Write-Info "7. Нажмите 'Create repository'"
    
    $repoUrl = Read-Host "Введите URL вашего GitHub репозитория"
    
    if ($repoUrl) {
        git remote add origin $repoUrl
        Write-Success "Удаленный репозиторий добавлен"
        
        # Отправка кода
        Write-Info "Отправка кода на GitHub..."
        git push -u origin main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Код успешно отправлен на GitHub!"
        } else {
            Write-Warning "Ошибка при отправке кода. Проверьте URL репозитория."
        }
    }
}

# 4. Настройка конфигурации (если не пропущено)
if (-not $SkipConfigSetup) {
    Write-Header "⚙️  Настройка конфигурации"
    
    Write-Info "Проверка конфигурации..."
    $configErrors = @()
    
    # Проверка Bybit API ключей
    $configFile = "BybitTrader\Config.swift"
    if (Test-Path $configFile) {
        $configContent = Get-Content $configFile -Raw
        
        if ($configContent -match 'YOUR_BYBIT_API_KEY') {
            $configErrors += "Bybit API Key не настроен"
        }
        
        if ($configContent -match 'YOUR_BYBIT_API_SECRET') {
            $configErrors += "Bybit API Secret не настроен"
        }
        
        if ($configContent -match 'YOUR_BYBIT_TESTNET_API_KEY') {
            $configErrors += "Bybit Testnet API Key не настроен"
        }
        
        if ($configContent -match 'YOUR_BYBIT_TESTNET_API_SECRET') {
            $configErrors += "Bybit Testnet API Secret не настроен"
        }
        
        if ($configContent -match 'sk-UJSfLa_vaSuXl4zi5rVbxw') {
            $configErrors += "AI Chat API Key не настроен"
        }
        
        if ($configErrors.Count -gt 0) {
            Write-Warning "Найдены проблемы в конфигурации:"
            foreach ($error in $configErrors) {
                Write-Warning "  - $error"
            }
            
            Write-Info "`nДля настройки API ключей:"
            Write-Info "1. Откройте BybitTrader\Config.swift"
            Write-Info "2. Замените placeholder значения на реальные ключи"
            Write-Info "3. Сохраните файл"
        } else {
            Write-Success "Конфигурация проверена - все API ключи настроены"
        }
    } else {
        Write-Error "Файл конфигурации не найден: $configFile"
    }
}

# 5. Создание .gitignore
Write-Header "📝 Настройка .gitignore"

if (-not (Test-Path ".gitignore")) {
    Write-Info "Создание .gitignore файла..."
    
    $gitignoreContent = @"
# Xcode
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

# User-specific files
*.xcuserstate
*.xcuserdata
*.xcscmblueprint
*.xccheckout
*.moved-aside
*.pbxuser
!default.pbuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

# API Keys and Secrets (IMPORTANT!)
Config.swift
*APIKey*
*Secret*
*Token*
*Password*

# Database files
*.sqlite
*.sqlite3
*.db

# Crash logs
*.crash

# Performance data
*.trace

# Coverage data
*.gcda
*.gcno

# Profiling data
*.prof

# Backup files
*.bak
*.backup

# OS generated files
Thumbs.db
ehthumbs.db
Desktop.ini

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# Package manager files
yarn.lock
package-lock.json
composer.lock

# Test results
test-results/
coverage/

# Documentation build
docs/_build/

# Jupyter Notebook
.ipynb_checkpoints

# pyenv
.python-version

# pipenv
Pipfile.lock

# PEP 582
__pypackages__/

# Celery
celerybeat-schedule
celerybeat.pid

# SageMath parsed files
*.sage.py

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Pyre type checker
.pyre/

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Icon must end with two \r
Icon

# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

# Windows
Thumbs.db
ehthumbs.db
Desktop.ini
$RECYCLE.BIN/
*.cab
*.msi
*.msix
*.msm
*.msp
*.lnk

# Linux
*~
.fuse_hidden*
.directory
.Trash-*
.nfs*

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*
.pnpm-debug.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# nyc test coverage
.nyc_output

# Grunt intermediate storage
.grunt

# Bower dependency directory
bower_components

# node-waf configuration
.lock-wscript

# Compiled binary addons
build/Release

# Dependency directories
node_modules/
jspm_packages/

# TypeScript cache
*.tsbuildinfo

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Optional stylelint cache
.stylelintcache

# Microbundle cache
.rpt2_cache/
.rts2_cache_cjs/
.rts2_cache_es/
.rts2_cache_umd/

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variable files
.env
.env.development.local
.env.test.local
.env.production.local
.env.local

# parcel-bundler cache
.cache
.parcel-cache

# Next.js build output
.next
out

# Nuxt.js build / generate output
.nuxt
dist

# Gatsby files
.cache/
public

# Storybook build outputs
.out
.storybook-out
storybook-static

# Temporary folders
tmp/
temp/

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# Local Netlify folder
.netlify

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port

# Stores VSCode versions used for testing VSCode extensions
.vscode-test

# yarn v2
.yarn/cache
.yarn/unplugged
.yarn/build-state.yml
.yarn/install-state.gz
.pnp.*
"@
    
    $gitignoreContent | Out-File -FilePath ".gitignore" -Encoding UTF8
    Write-Success ".gitignore файл создан"
    
    # Добавление .gitignore в Git
    if (-not $SkipGitSetup) {
        git add .gitignore
        git commit -m "Add .gitignore for iOS project"
        Write-Success ".gitignore добавлен в Git"
        
        # Отправка изменений
        if (git remote get-url origin) {
            git push origin main
            Write-Success "Изменения отправлены на GitHub"
        }
    }
} else {
    Write-Info ".gitignore файл уже существует"
}

# 6. Проверка структуры проекта
Write-Header "📊 Проверка структуры проекта"

$requiredFiles = @(
    "BybitTrader.xcodeproj",
    "BybitTrader\BybitTraderApp.swift",
    "BybitTrader\ContentView.swift",
    "BybitTrader\Config.swift",
    "BybitTrader\Services\",
    "BybitTrader\Models\",
    "BybitTrader\Views\",
    "README.md",
    "bitrise.yml",
    "exportOptions.plist",
    "exportOptionsAdHoc.plist"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Success "✓ $file"
    } else {
        Write-Warning "✗ $file (отсутствует)"
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Warning "`nОтсутствуют некоторые файлы проекта. Проверьте структуру проекта."
}

# 7. Финальная настройка
Write-Header "🎯 Финальная настройка"

Write-Info "Проект Bybit Trader iOS настроен!"
Write-Info ""

Write-Info "Следующие шаги:"
Write-Info "1. Настройте API ключи в BybitTrader\Config.swift"
Write-Info "2. Откройте BybitTrader.xcodeproj в Xcode"
Write-Info "3. Настройте Team и Bundle Identifier"
Write-Info "4. Соберите и запустите проект"
Write-Info ""

Write-Info "Полезные файлы:"
Write-Info "- SETUP_INSTRUCTIONS.md - подробные инструкции по настройке"
Write-Info "- github_commands.md - команды для работы с GitHub"
Write-Info "- quick_start_commands.bat - быстрый старт для Windows"
Write-Info ""

Write-Info "Для получения помощи:"
Write-Info "- Создайте Issue в GitHub репозитории"
Write-Info "- Обратитесь в документацию проекта"
Write-Info ""

Write-Success "🎉 Настройка завершена! Удачи в разработке!"

# Показать статус Git
if (-not $SkipGitSetup) {
    Write-Header "📊 Статус Git репозитория"
    git status
    Write-Info ""
    git remote -v
}

Write-Header "🏁 Завершение"
Write-Info "Нажмите любую клавишу для выхода..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

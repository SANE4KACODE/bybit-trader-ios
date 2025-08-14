@echo off
chcp 65001 >nul
echo ========================================
echo    Bybit Trader - Быстрый старт
echo ========================================
echo.

:menu
echo Выберите действие:
echo 1. Инициализировать Git репозиторий
echo 2. Загрузить проект на GitHub
echo 3. Проверить статус Git
echo 4. Создать .gitignore
echo 5. Показать команды для GitHub
echo 6. Выход
echo.
set /p choice="Введите номер (1-6): "

if "%choice%"=="1" goto init_git
if "%choice%"=="2" goto upload_github
if "%choice%"=="3" goto check_status
if "%choice%"=="4" goto create_gitignore
if "%choice%"=="5" goto show_commands
if "%choice%"=="6" goto exit
echo Неверный выбор. Попробуйте снова.
goto menu

:init_git
echo.
echo ========================================
echo Инициализация Git репозитория...
echo ========================================
echo.
git init
git add .
git commit -m "Initial commit: Bybit Trader iOS app with complete features"
echo.
echo Git репозиторий инициализирован!
echo.
pause
goto menu

:upload_github
echo.
echo ========================================
echo Загрузка проекта на GitHub...
echo ========================================
echo.
echo ВНИМАНИЕ: Сначала создайте репозиторий на GitHub!
echo.
set /p repo_url="Введите URL вашего GitHub репозитория: "
git remote add origin %repo_url%
git branch -M main
git push -u origin main
echo.
echo Проект загружен на GitHub!
echo.
pause
goto menu

:check_status
echo.
echo ========================================
echo Статус Git репозитория
echo ========================================
echo.
git status
echo.
git remote -v
echo.
pause
goto menu

:create_gitignore
echo.
echo ========================================
echo Создание .gitignore файла...
echo ========================================
echo.
if exist .gitignore (
    echo .gitignore уже существует!
) else (
    echo Создаю .gitignore файл...
    copy nul .gitignore >nul
    echo # Xcode >> .gitignore
    echo .DS_Store >> .gitignore
    echo */build/* >> .gitignore
    echo *.pbxuser >> .gitignore
    echo xcuserdata >> .gitignore
    echo *.xccheckout >> .gitignore
    echo DerivedData >> .gitignore
    echo *.ipa >> .gitignore
    echo *.xcuserstate >> .gitignore
    echo project.xcworkspace >> .gitignore
    echo # CocoaPods >> .gitignore
    echo Pods/ >> .gitignore
    echo Podfile.lock >> .gitignore
    echo # Build artifacts >> .gitignore
    echo build/ >> .gitignore
    echo *.dSYM.zip >> .gitignore
    echo *.dSYM >> .gitignore
    echo # Logs >> .gitignore
    echo *.log >> .gitignore
    echo # Environment variables >> .gitignore
    echo .env >> .gitignore
    echo .env.local >> .gitignore
    echo # API Keys >> .gitignore
    echo Config.swift >> .gitignore
    echo *APIKey* >> .gitignore
    echo *Secret* >> .gitignore
    echo.
    echo .gitignore файл создан!
)
echo.
pause
goto menu

:show_commands
echo.
echo ========================================
echo Команды для работы с GitHub
echo ========================================
echo.
echo 1. Создать репозиторий на GitHub:
echo    - Перейдите на https://github.com
echo    - Нажмите "New repository"
echo    - Название: BybitTrader-iOS
echo    - Описание: Professional iOS trading app for Bybit
echo    - Выберите Public или Private
echo    - НЕ ставьте галочки на README, .gitignore, license
echo    - Нажмите "Create repository"
echo.
echo 2. Инициализировать локальный репозиторий:
echo    git init
echo    git add .
echo    git commit -m "Initial commit: Bybit Trader iOS app"
echo.
echo 3. Подключить к GitHub:
echo    git remote add origin https://github.com/YOUR_USERNAME/BybitTrader-iOS.git
echo    git branch -M main
echo    git push -u origin main
echo.
echo 4. Проверить статус:
echo    git status
echo    git remote -v
echo.
echo 5. Обновить .gitignore и закоммитить:
echo    git add .gitignore
echo    git commit -m "Add .gitignore for iOS project"
echo    git push origin main
echo.
pause
goto menu

:exit
echo.
echo Спасибо за использование Bybit Trader!
echo Удачи в разработке! 🚀
echo.
pause
exit

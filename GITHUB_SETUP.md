# Настройка GitHub репозитория для BybitTrader

## Шаг 1: Создание репозитория на GitHub

1. Перейдите на [github.com](https://github.com) и войдите в свой аккаунт
2. Нажмите кнопку "+" в правом верхнем углу и выберите "New repository"
3. Заполните форму:
   - Repository name: `BybitTrader`
   - Description: `iOS trading app for Bybit exchange with AI features`
   - Visibility: Public или Private (по вашему выбору)
   - НЕ ставьте галочки на "Add a README file", "Add .gitignore", "Choose a license"
4. Нажмите "Create repository"

## Шаг 2: Подключение локального репозитория к GitHub

После создания репозитория на GitHub, выполните следующие команды в терминале:

```bash
# Добавить удаленный репозиторий (замените YOUR_USERNAME на ваше имя пользователя)
git remote add origin https://github.com/YOUR_USERNAME/BybitTrader.git

# Переименовать основную ветку в main (если нужно)
git branch -M main

# Отправить код на GitHub
git push -u origin main
```

## Шаг 3: Проверка подключения

```bash
# Проверить удаленные репозитории
git remote -v

# Проверить статус
git status
```

## Шаг 4: Настройка веток

```bash
# Создать ветку для разработки
git checkout -b develop

# Отправить ветку develop на GitHub
git push -u origin develop
```

## Шаг 5: Настройка защиты веток (опционально)

1. Перейдите в настройки репозитория на GitHub
2. Выберите "Branches" в левом меню
3. Нажмите "Add rule" для ветки `main`
4. Включите опции:
   - Require a pull request before merging
   - Require status checks to pass before merging
   - Require branches to be up to date before merging

## Шаг 6: Настройка GitHub Actions (опционально)

Создайте файл `.github/workflows/ci.yml` для автоматической сборки и тестирования.

## Полезные команды для работы с GitHub

```bash
# Отправить изменения
git add .
git commit -m "Описание изменений"
git push

# Получить изменения с GitHub
git pull origin main

# Создать новую ветку для фичи
git checkout -b feature/new-feature
git push -u origin feature/new-feature

# Создать Pull Request (через веб-интерфейс GitHub)
# 1. Перейдите на GitHub
# 2. Нажмите "Compare & pull request"
# 3. Заполните описание и создайте PR
```

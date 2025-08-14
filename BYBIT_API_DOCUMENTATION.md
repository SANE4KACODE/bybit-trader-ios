# 📚 Bybit API V5 - Полная документация

## 🔑 Аутентификация

Bybit API использует HMAC SHA256 подпись для обеспечения безопасности всех запросов.

### Заголовки аутентификации

Все приватные API запросы должны содержать следующие заголовки:

```
X-BAPI-API-KEY: ваш_публичный_ключ
X-BAPI-SIGNATURE: подпись_запроса
X-BAPI-TIMESTAMP: текущее_время_в_миллисекундах
X-BAPI-RECV-WINDOW: 5000
Content-Type: application/json
```

### Генерация подписи

```swift
// Формат строки для подписи:
// timestamp + api_key + recv_window + query_string

// Пример:
// 1703123456789 + "your_api_key" + "5000" + "symbol=BTCUSDT&side=Buy&orderType=Market&qty=0.001&category=linear"

// Алгоритм:
// 1. Создать строку: timestamp + api_key + recv_window + query_string
// 2. Использовать HMAC SHA256 с вашим secret_key
// 3. Преобразовать результат в hex строку
```

## 🌐 Базовые URL

- **Testnet**: `https://api-testnet.bybit.com`
- **Mainnet**: `https://api.bybit.com`

## 📊 Основные эндпоинты

### 1. Информация об аккаунте

#### Получение баланса кошелька
```
GET /v5/account/wallet-balance
```

**Параметры:**
- `accountType` (опционально): Тип аккаунта (UNIFIED, CONTRACT, SPOT)

**Ответ:**
```json
{
  "retCode": 0,
  "retMsg": "OK",
  "result": {
    "list": [
      {
        "accountType": "UNIFIED",
        "coin": [
          {
            "coin": "USDT",
            "walletBalance": "1000.00000000",
            "availableToWithdraw": "1000.00000000",
            "availableToSend": "1000.00000000"
          }
        ]
      }
    ]
  }
}
```

### 2. Позиции

#### Получение списка позиций
```
GET /v5/position/list
```

**Параметры:**
- `category` (обязательно): Тип контракта (linear, inverse, spot)
- `symbol` (опционально): Торговая пара
- `settleCoin` (опционально): Монета для расчета

**Ответ:**
```json
{
  "retCode": 0,
  "retMsg": "OK",
  "result": {
    "list": [
      {
        "symbol": "BTCUSDT",
        "side": "Buy",
        "size": "0.001",
        "entryPrice": "50000.00",
        "markPrice": "51000.00",
        "unrealizedPnl": "1.00",
        "leverage": "10",
        "margin": "5.00",
        "liquidationPrice": "45000.00"
      }
    ]
  }
}
```

### 3. Торговля

#### Размещение ордера
```
POST /v5/order/create
```

**Тело запроса:**
```json
{
  "category": "linear",
  "symbol": "BTCUSDT",
  "side": "Buy",
  "orderType": "Market",
  "qty": "0.001",
  "timeInForce": "GTC"
}
```

**Обязательные параметры:**
- `category`: Тип контракта
- `symbol`: Торговая пара
- `side`: Сторона (Buy/Sell)
- `orderType`: Тип ордера (Market/Limit/Stop/StopLimit)
- `qty`: Количество
- `timeInForce`: Время действия (GTC, IOC, FOK)

**Ответ:**
```json
{
  "retCode": 0,
  "retMsg": "OK",
  "result": {
    "orderId": "123456789",
    "orderLinkId": "custom_order_id"
  }
}
```

#### Отмена ордера
```
POST /v5/order/cancel
```

**Тело запроса:**
```json
{
  "category": "linear",
  "symbol": "BTCUSDT",
  "orderId": "123456789"
}
```

### 4. Рыночные данные

#### Получение K-line данных
```
GET /v5/market/kline
```

**Параметры:**
- `category` (обязательно): Тип контракта
- `symbol` (обязательно): Торговая пара
- `interval` (обязательно): Интервал времени
- `limit` (опционально): Количество свечей (максимум 1000)

**Интервалы времени:**
- `1`, `3`, `5`, `15`, `30` (минуты)
- `60`, `120`, `240`, `360`, `480`, `720` (часы)
- `D`, `W`, `M` (день, неделя, месяц)

**Ответ:**
```json
{
  "retCode": 0,
  "retMsg": "OK",
  "result": {
    "category": "linear",
    "symbol": "BTCUSDT",
    "list": [
      [
        "1703123456789",  // timestamp
        "50000.00",       // open
        "51000.00",       // high
        "49000.00",       // low
        "50500.00",       // close
        "100.5",          // volume
        "5000000.00"      // turnover
      ]
    ]
  }
}
```

#### Получение информации о тикерах
```
GET /v5/market/tickers
```

**Параметры:**
- `category` (обязательно): Тип контракта
- `symbol` (опционально): Торговая пара

**Ответ:**
```json
{
  "retCode": 0,
  "retMsg": "OK",
  "result": {
    "category": "linear",
    "list": [
      {
        "symbol": "BTCUSDT",
        "lastPrice": "50500.00",
        "prevPrice24h": "50000.00",
        "price24hPcnt": "1.00",
        "highPrice24h": "51000.00",
        "lowPrice24h": "49000.00",
        "turnover24h": "5000000.00",
        "volume24h": "100.5"
      }
    ]
  }
}
```

## ⚠️ Важные замечания

### 1. Ограничения запросов
- **Rate Limit**: 1200 запросов в минуту для приватных API
- **Rate Limit**: 6000 запросов в минуту для публичных API

### 2. Временные метки
- Все временные метки должны быть в миллисекундах
- Разница между временем сервера и вашим временем не должна превышать 5000 мс

### 3. Размеры ордеров
- Минимальный размер зависит от торговой пары
- Используйте `/v5/market/instruments-info` для получения точных значений

### 4. Обработка ошибок
```json
{
  "retCode": 10001,
  "retMsg": "Invalid parameter",
  "result": {}
}
```

**Основные коды ошибок:**
- `0`: Успешно
- `10001`: Неверный параметр
- `10002`: Неверная подпись
- `10003`: Время истекло
- `10004`: Неверный API ключ
- `10005`: Недостаточно средств
- `10006`: Неверный символ

## 🔧 Примеры использования

### Получение баланса
```swift
let endpoint = "/v5/account/wallet-balance"
let url = URL(string: baseURL + endpoint)!

var request = URLRequest(url: url)
request.httpMethod = "GET"
request.allHTTPHeaderFields = createHeaders(method: "GET")

let (data, response) = try await URLSession.shared.data(for: request)
let balanceResponse = try JSONDecoder().decode(WalletBalanceResponse.self, from: data)
```

### Размещение рыночного ордера
```swift
let endpoint = "/v5/order/create"
let url = URL(string: baseURL + endpoint)!

let orderData: [String: Any] = [
    "category": "linear",
    "symbol": "BTCUSDT",
    "side": "Buy",
    "orderType": "Market",
    "qty": "0.001",
    "timeInForce": "GTC"
]

let jsonData = try JSONSerialization.data(withJSONObject: orderData)

var request = URLRequest(url: url)
request.httpMethod = "POST"
request.httpBody = jsonData
request.allHTTPHeaderFields = createHeaders(method: "POST")

let (data, response) = try await URLSession.shared.data(for: request)
let orderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
```

## 📱 Поддержка мобильных устройств

### Рекомендации для iOS
1. Используйте `URLSession` для HTTP запросов
2. Реализуйте правильную обработку ошибок
3. Добавьте retry логику для сетевых ошибок
4. Кэшируйте данные для улучшения производительности
5. Используйте background tasks для обновления данных

### Безопасность
1. Никогда не храните API ключи в коде
2. Используйте Keychain для хранения секретов
3. Реализуйте биометрическую аутентификацию
4. Шифруйте локальные данные
5. Регулярно обновляйте API ключи

## 🔗 Полезные ссылки

- [Официальная документация Bybit](https://bybit-exchange.github.io/docs/v5/intro)
- [API статус](https://status.bybit.com/)
- [Техническая поддержка](https://www.bybit.com/en/help-center)
- [GitHub репозиторий](https://github.com/bybit-exchange)

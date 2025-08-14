-- 🗄️ SQL схема для Bybit Trader - Supabase
-- Создайте эти таблицы в вашем Supabase проекте

-- 1. Пользователи и подписки
CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    subscription_status TEXT DEFAULT 'trial' CHECK (subscription_status IN ('trial', 'active', 'expired', 'cancelled')),
    subscription_start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    subscription_end_date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),
    trial_end_date TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),
    monthly_price DECIMAL(10,2) DEFAULT 299.00,
    country_code TEXT DEFAULT 'RU',
    currency TEXT DEFAULT 'RUB',
    full_name TEXT,
    avatar_url TEXT
);

-- 2. Торговые сделки
CREATE TABLE trades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    side TEXT NOT NULL CHECK (side IN ('buy', 'sell')),
    order_type TEXT NOT NULL CHECK (order_type IN ('market', 'limit', 'stop', 'stop_limit')),
    quantity DECIMAL(20,8) NOT NULL,
    price DECIMAL(20,8) NOT NULL,
    executed_price DECIMAL(20,8),
    total_amount DECIMAL(20,8),
    fee DECIMAL(20,8) DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'filled', 'cancelled', 'rejected')),
    order_id TEXT,
    bybit_order_id TEXT,
    notes TEXT,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    executed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Позиции
CREATE TABLE positions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    side TEXT NOT NULL CHECK (side IN ('long', 'short')),
    quantity DECIMAL(20,8) NOT NULL,
    entry_price DECIMAL(20,8) NOT NULL,
    current_price DECIMAL(20,8),
    unrealized_pnl DECIMAL(20,8),
    realized_pnl DECIMAL(20,8),
    leverage INTEGER DEFAULT 1,
    margin DECIMAL(20,8),
    liquidation_price DECIMAL(20,8),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    opened_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    closed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Балансы
CREATE TABLE balances (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    currency TEXT NOT NULL,
    available_balance DECIMAL(20,8) NOT NULL,
    total_balance DECIMAL(20,8) NOT NULL,
    frozen_balance DECIMAL(20,8) DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, currency)
);

-- 5. Настройки пользователей
CREATE TABLE user_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    api_key TEXT,
    api_secret TEXT,
    testnet BOOLEAN DEFAULT true,
    auto_refresh BOOLEAN DEFAULT true,
    refresh_interval INTEGER DEFAULT 30,
    notifications_enabled BOOLEAN DEFAULT true,
    dark_mode_enabled BOOLEAN DEFAULT false,
    biometric_auth_enabled BOOLEAN DEFAULT false,
    selected_symbols TEXT[] DEFAULT ARRAY['BTCUSDT', 'ETHUSDT'],
    risk_level TEXT DEFAULT 'medium' CHECK (risk_level IN ('low', 'medium', 'high')),
    max_position_size DECIMAL(20,8) DEFAULT 1000.00,
    stop_loss_percentage DECIMAL(5,2) DEFAULT 5.00,
    take_profit_percentage DECIMAL(5,2) DEFAULT 10.00,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Уведомления
CREATE TABLE notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('price_alert', 'trade_executed', 'position_closed', 'system')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Ценовые алерты
CREATE TABLE price_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    target_price DECIMAL(20,8) NOT NULL,
    condition TEXT NOT NULL CHECK (condition IN ('above', 'below')),
    is_active BOOLEAN DEFAULT true,
    triggered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Торговые отчеты
CREATE TABLE trading_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    report_type TEXT NOT NULL CHECK (report_type IN ('daily', 'weekly', 'monthly', 'custom')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_trades INTEGER DEFAULT 0,
    winning_trades INTEGER DEFAULT 0,
    losing_trades INTEGER DEFAULT 0,
    total_pnl DECIMAL(20,8) DEFAULT 0,
    win_rate DECIMAL(5,2) DEFAULT 0,
    average_win DECIMAL(20,8) DEFAULT 0,
    average_loss DECIMAL(20,8) DEFAULT 0,
    max_drawdown DECIMAL(20,8) DEFAULT 0,
    sharpe_ratio DECIMAL(10,4),
    report_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Логи API запросов
CREATE TABLE api_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    endpoint TEXT NOT NULL,
    method TEXT NOT NULL,
    request_data JSONB,
    response_data JSONB,
    status_code INTEGER,
    response_time INTEGER, -- в миллисекундах
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. Торговые стратегии
CREATE TABLE trading_strategies (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    strategy_type TEXT NOT NULL CHECK (strategy_type IN ('scalping', 'swing', 'position', 'arbitrage')),
    parameters JSONB,
    is_active BOOLEAN DEFAULT true,
    performance_metrics JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 🔍 Индексы для производительности
CREATE INDEX idx_trades_user_id ON trades(user_id);
CREATE INDEX idx_trades_symbol ON trades(symbol);
CREATE INDEX idx_trades_created_at ON trades(created_at);
CREATE INDEX idx_trades_status ON trades(status);

CREATE INDEX idx_positions_user_id ON positions(user_id);
CREATE INDEX idx_positions_symbol ON positions(symbol);
CREATE INDEX idx_positions_status ON positions(status);

CREATE INDEX idx_balances_user_id ON balances(user_id);
CREATE INDEX idx_balances_currency ON balances(currency);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

CREATE INDEX idx_price_alerts_user_id ON price_alerts(user_id);
CREATE INDEX idx_price_alerts_symbol ON price_alerts(symbol);
CREATE INDEX idx_price_alerts_is_active ON price_alerts(is_active);

CREATE INDEX idx_trading_reports_user_id ON trading_reports(user_id);
CREATE INDEX idx_trading_reports_date_range ON trading_reports(start_date, end_date);

CREATE INDEX idx_api_logs_user_id ON api_logs(user_id);
CREATE INDEX idx_api_logs_created_at ON api_logs(created_at);

-- 🔒 Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE trading_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE trading_strategies ENABLE ROW LEVEL SECURITY;

-- 📋 Политики RLS
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);

CREATE POLICY "Users can view own trades" ON trades
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own trades" ON trades
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own trades" ON trades
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own trades" ON trades
    FOR DELETE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can view own positions" ON positions
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own positions" ON positions
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own positions" ON positions
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can view own balances" ON balances
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own balances" ON balances
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own balances" ON balances
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can view own settings" ON user_settings
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own settings" ON user_settings
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own settings" ON user_settings
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own notifications" ON notifications
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can view own price alerts" ON price_alerts
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own price alerts" ON price_alerts
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own price alerts" ON price_alerts
    FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own price alerts" ON price_alerts
    FOR DELETE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can view own trading reports" ON trading_reports
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own trading reports" ON trading_reports
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can view own api logs" ON api_logs
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own api logs" ON api_logs
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can view own trading strategies" ON trading_strategies
    FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own trading strategies" ON trading_strategies
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own trading strategies" ON trading_strategies
    FOR UPDATE USING (auth.uid()::text = user_id::text);

-- ⚡ Триггеры и функции
-- Автоматическое обновление updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trades_updated_at BEFORE UPDATE ON trades
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_positions_updated_at BEFORE UPDATE ON positions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trading_strategies_updated_at BEFORE UPDATE ON trading_strategies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Функция проверки подписки
CREATE OR REPLACE FUNCTION check_subscription_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем, истекла ли пробная подписка
    IF NEW.subscription_status = 'trial' AND NEW.trial_end_date < NOW() THEN
        NEW.subscription_status = 'expired';
    END IF;
    
    -- Проверяем, истекла ли активная подписка
    IF NEW.subscription_status = 'active' AND NEW.subscription_end_date < NOW() THEN
        NEW.subscription_status = 'expired';
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER check_subscription_status_trigger BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION check_subscription_status();

-- Функция для расчета P&L позиции
CREATE OR REPLACE FUNCTION calculate_position_pnl()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_price IS NOT NULL THEN
        IF NEW.side = 'long' THEN
            NEW.unrealized_pnl = (NEW.current_price - NEW.entry_price) * NEW.quantity;
        ELSE
            NEW.unrealized_pnl = (NEW.entry_price - NEW.current_price) * NEW.quantity;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER calculate_position_pnl_trigger BEFORE UPDATE ON positions
    FOR EACH ROW EXECUTE FUNCTION calculate_position_pnl();

-- 📊 Представления для аналитики
CREATE VIEW user_trading_summary AS
SELECT 
    u.id,
    u.email,
    u.subscription_status,
    COUNT(t.id) as total_trades,
    COUNT(CASE WHEN t.status = 'filled' THEN 1 END) as filled_trades,
    SUM(CASE WHEN t.status = 'filled' THEN t.total_amount ELSE 0 END) as total_pnl,
    AVG(CASE WHEN t.status = 'filled' THEN t.total_amount ELSE NULL END) as avg_trade_pnl
FROM users u
LEFT JOIN trades t ON u.id = t.user_id
GROUP BY u.id, u.email, u.subscription_status;

CREATE VIEW active_positions_summary AS
SELECT 
    user_id,
    symbol,
    side,
    SUM(quantity) as total_quantity,
    AVG(entry_price) as avg_entry_price,
    SUM(unrealized_pnl) as total_unrealized_pnl
FROM positions
WHERE status = 'open'
GROUP BY user_id, symbol, side;

-- 🎯 Вставка тестовых данных (опционально)
INSERT INTO users (email, subscription_status, country_code, currency) VALUES
('demo@example.com', 'trial', 'RU', 'RUB'),
('test@example.com', 'active', 'US', 'USD');

-- 📝 Комментарии
COMMENT ON TABLE users IS 'Пользователи и их подписки';
COMMENT ON TABLE trades IS 'Торговые сделки пользователей';
COMMENT ON TABLE positions IS 'Открытые позиции пользователей';
COMMENT ON TABLE balances IS 'Балансы пользователей по валютам';
COMMENT ON TABLE user_settings IS 'Настройки пользователей';
COMMENT ON TABLE notifications IS 'Уведомления пользователей';
COMMENT ON TABLE price_alerts IS 'Ценовые алерты';
COMMENT ON TABLE trading_reports IS 'Торговые отчеты';
COMMENT ON TABLE api_logs IS 'Логи API запросов';
COMMENT ON TABLE trading_strategies IS 'Торговые стратегии пользователей';

-- ✅ Проверка создания таблиц
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

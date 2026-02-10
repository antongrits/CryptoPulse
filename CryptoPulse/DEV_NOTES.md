# DEV_NOTES

## План выполнения
1. Инфраструктура приложения
- AppEnvironment, AppConfig, DI, Splash, MainTab, Settings
Self-check: App стартует, Splash -> MainTab, при отсутствии ключа — экран ошибки.

2. Design System
- Colors, Typography, Spacing, базовые компоненты (Card, Shimmer, Banner, EmptyState)
Self-check: Компоненты собираются, превью работают, дизайн единый.

3. Network слой
- NetworkClient, CoinGeckoService, DTO, обработка ошибок
Self-check: Ошибки offline / 429 / decoding корректно конвертируются.

4. Realm и кеш
- RealmProvider, schemaVersion=6, объекты, TTL cache
Self-check: кеш работает, inMemory Realm для тестов доступен.

5. Экраны и ViewModel
- Market, Details, Favorites, Portfolio, Alerts, Converter, Search, Insights, Settings, More
- Compare, Profit Calculator, Notes, Global Market stats
- Heatmap screen (scale slider + pin)
 - Categories, Exchanges, Dominance screens
Self-check: все экраны грузятся, состояния (loading/error/empty) видимы.

6. Charts и iOS 15/16 совместимость
- iOS 16: Swift Charts + drag marker + axes/grid
- iOS 15: custom Path chart + axes/grid + drag marker
- Full-screen chart + range selector (1D/7D/1M/3M/1Y/ALL)
Self-check: график рендерится на iOS 15 симуляторе.

7. Тесты
- Unit tests: форматтеры, repository, viewmodel, alerts logic
- UI tests: Market->Details, Favorites flow
Self-check: тесты запускаются и проходят с mock data.

8. Документация
- README, AI_Assets_Prompts, .gitignore, Quality checklist
Self-check: README отражает архитектуру, API key, тесты, ограничения.

---

## Self-check Notes
- Network: endpoints покрыты DTO, ошибки маппятся в NetworkError.
- Realm: schemaVersion=6, alerts repeat/cooldown/metric, chart cache расширен.
- Market: pagination + dedup реализованы, offline banner при отсутствии сети.
- Market: добавлены swipe-разделы All/Gainers/Losers/Trending.
- Details: данные и график загружаются отдельно, есть fallback состояния, range selector.
- Alerts: локальные уведомления, cooldown + repeat mode, проверка при запуске/refresh/входе.
- Converter: история конвертаций + copy result.
- Widgets: Home Screen виджет с топ-монетами, авто-обновление по системному расписанию.
- Heatmap: pinned card + scale slider + фильтр по категориям.
- Market: переключатель Cards/Compact.
- Alerts: добавлен режим % изменения (24h).
 - More tools: Categories (stats + category markets), Exchanges (ranking + volumes), Dominance (BTC/ETH/Other).
- Insights: добавлены global stats, top movers.
- Tests: unit + UI тесты добавлены, mock JSON в bundle.

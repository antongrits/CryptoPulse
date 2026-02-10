# CryptoPulse

Production-grade SwiftUI crypto tracker for iOS 15+, built with MVVM, Swift Concurrency, Realm caching/storage, advanced chart interactions, alerts, portfolio analytics, widgets, and localization (EN/RU/BE).

## Table of Contents
- [Overview](#overview)
- [Feature Set](#feature-set)
- [Screen Map](#screen-map)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Data Providers and API Policy](#data-providers-and-api-policy)
- [Caching and Offline Strategy](#caching-and-offline-strategy)
- [Charts (iOS 15 and iOS 16+)](#charts-ios-15-and-ios-16)
- [Localization](#localization)
- [Widgets](#widgets)
- [Notifications and Alerts](#notifications-and-alerts)
- [Configuration](#configuration)
- [Build and Run](#build-and-run)
- [Test Status and Scope](#test-status-and-scope)
- [Quality Checklist](#quality-checklist)
- [Screenshots](#screenshots)
- [Roadmap](#roadmap)

## Overview
CryptoPulse is designed as a complete, production-ready mobile product, not an MVP.

Core goals:
- Fast market overview with robust offline behavior.
- Deep coin details with interactive charting.
- Actionable tools: favorites, portfolio tracking, alerts, converter, notes, heatmap, analytics.
- iOS 15 compatibility without visual degradation.
- Clean architecture with testable business logic.

## Feature Set
### Market
- Live market list with pagination.
- Cards and compact list modes.
- Search, sorting, segmented sections (All/Gainers/Losers/Trending).
- Pull-to-refresh.
- Skeleton loading states.
- Offline banner with cached fallback.

### Coin Details
- Header with coin identity and current change.
- Price chart with range selection and touch interaction.
- Interactive fullscreen chart with:
- Pinch zoom.
- Pan with inertial motion.
- Crosshair and floating price-axis label.
- Auto Y-scale and Lock Y-scale modes.
- Stats: market cap, volume, high/low, supply, updated timestamp.
- Actions: favorite, add holding, create notification, notes.

### Favorites
- Persistent favorites via Realm.
- Empty state + quick action to Market.
- Navigation to coin details.

### Portfolio
- Holdings CRUD (amount + optional average buy price).
- Total value and P/L metrics.
- Allocation donut with interactive legend.
- Export/share snapshot.

### Alerts
- Price-based and change-based notifications.
- Direction above/below.
- Repeat/cooldown controls.
- Local notifications integration.

### Converter
- Coin <-> USD conversion.
- Quick amount chips.
- Conversion history.
- Copy result action.

### Search
- Dedicated screen.
- Recent queries persisted in Realm.

### Insights and More Tools
- Market pulse / global market blocks.
- Heatmap with scaling and pinning.
- Categories / exchanges / dominance.
- Compare coins and profit calculator.
- Notes library with grouped history.

## Screen Map
Primary tabs:
- Market
- Favorites
- Portfolio
- Notifications
- More

Inside More:
- Converter
- Search
- Insights
- Heatmap
- Categories
- Exchanges
- Dominance
- Notes
- Settings/About

Technical flow:
- LaunchScreen (static) -> Animated Splash -> Main App

## Architecture
- Pattern: `MVVM + DI`.
- Concurrency: `async/await`.
- Storage: `Realm` (persistent + cache + test in-memory realm).

Layers:
- `Domain`: pure models + repository protocols.
- `Data/Network`: endpoint builder, DTOs, network client, service adapters.
- `Data/Local`: Realm objects + mappers + migration.
- `Data/Repositories`: business orchestration, cache policies, fallback logic.
- `Features`: screen-specific view models and views.
- `DesignSystem`: color/spacing/typography tokens and reusable components.
- `Shared`: formatters, navigation wrappers, image cache, helpers.

## Project Structure
```text
CryptoPulse/
  CryptoPulse/                 # Main app target
    App/
    DesignSystem/
    Domain/
    Data/
    Features/
    Shared/
    Resources/
    en.lproj/
    ru.lproj/
    be.lproj/
  CryptoPulseTests/            # Unit tests
  CryptoPulseUITests/          # UI tests
  CryptoPulseWidgets/          # Widget extension
  CryptoPulse.xcodeproj
  Secrets.xcconfig             # Local secrets (ignored)
```

## Data Providers and API Policy
Current setup is demo-plan friendly.

Primary:
- CoinGecko Demo API (`x-cg-demo-api-key`).

Fallback strategy:
- Non-critical analytics endpoints can fallback to alternative providers when unavailable on demo limits.
- UI gracefully shows unavailable state if data is not provided by plan.

Important:
- No feature depends on CoinGecko Pro-only authentication.
- Errors `429` and unsupported-plan responses are handled explicitly in UX.

## Caching and Offline Strategy
Realm cache TTL defaults:
- Markets: 2 minutes.
- Coin details: 5 minutes.
- Chart data: 10 minutes.

Behavior:
- Read cache first for fast render.
- Refresh in background.
- Keep cached data on network errors.
- Show non-blocking offline banner.

## Charts (iOS 15 and iOS 16+)
- iOS 16+: Swift Charts implementation.
- iOS 15: custom line chart (Path/GeometryReader), matching interaction behavior.

Supported interactions:
- Range switching (`1D`, `7D`, `1M`, `3M`, `1Y`, `ALL` when available).
- Drag/crosshair selection.
- Floating tooltip and axis label.
- Fullscreen analysis mode.
- Pan + zoom in fullscreen with inertial scrolling.
- Auto vs Lock Y-scale.

## Localization
Supported languages:
- English
- Russian
- Belarusian

Localization includes:
- Tab labels and navigation titles.
- Error and empty-state messages.
- Chart and analytics labels.
- Settings and tool labels.

## Widgets
Widget extension provides:
- Home screen market snapshots.
- Theme-aware rendering.
- Modern background API on supported iOS versions.

## Notifications and Alerts
- Local notifications are requested with user consent.
- Alert evaluator supports direction and cooldown.
- Trigger checks run on app launch and relevant refresh events.

## Configuration
### API Key (No Hardcoding)
`Info.plist` contains:
- `COINGECKO_API_KEY = $(COINGECKO_API_KEY)`

Runtime access:
- `AppConfig.coinGeckoApiKey` reads from `Bundle.main.object(forInfoDictionaryKey:)`.
- Missing/empty key shows configuration error screen and logs reason.

### Required local file
Create `Secrets.xcconfig` in repo root (already in `.gitignore`), for example:
```xcconfig
COINGECKO_API_KEY = CG-XXXXXXXXXXXX
```

## Build and Run
### Xcode
1. Open `CryptoPulse.xcodeproj`.
2. Select `CryptoPulse` scheme.
3. Ensure signing/team settings are valid for your device.
4. Build and run.

### CLI build (no tests)
```bash
xcodebuild -project CryptoPulse.xcodeproj -scheme CryptoPulse -destination 'generic/platform=iOS Simulator' build
```

### Build tests without running
```bash
xcodebuild -project CryptoPulse.xcodeproj -scheme CryptoPulse -destination 'generic/platform=iOS Simulator' build-for-testing
```

## Test Status and Scope
Unit tests cover:
- Number/price/percent formatters.
- Market repository sort/merge/pagination behavior.
- Market view model states.
- Favorites repository persistence.
- Portfolio calculations.
- Alerts evaluation logic.
- Network client behavior.

UI tests cover critical flows:
- Launch -> Market -> open Details.
- Add favorite -> open Favorites -> verify item.

## Quality Checklist
- No API key hardcoded in Swift source.
- No force-unwrap in critical runtime paths.
- Offline mode with cached fallback.
- iOS 15 compatibility paths for navigation/charts.
- Dynamic type-friendly layouts in major screens.
- Theme-aware text/background contrast.

## Screenshots
This section is ready for GitHub screenshots. Add your image files under:
- `docs/screenshots/`

Recommended naming:
- `01-splash.png`
- `02-market-cards.png`
- `03-market-compact.png`
- `04-details-chart.png`
- `05-details-fullscreen-chart.png`
- `06-favorites.png`
- `07-portfolio.png`
- `08-add-holding.png`
- `09-alerts-list.png`
- `10-alert-form.png`
- `11-converter.png`
- `12-search.png`
- `13-insights.png`
- `14-heatmap.png`
- `15-categories.png`
- `16-exchanges.png`
- `17-dominance.png`
- `18-notes.png`
- `19-settings.png`
- `20-widgets.png`

### 1) Animated Splash
Caption: Animated in-app splash shown after static LaunchScreen.

```md
![Animated Splash](docs/screenshots/01-splash.png)
```

### 2) Market (Cards)
Caption: Market cards mode with sorting, sections, and pull-to-refresh.

```md
![Market Cards](docs/screenshots/02-market-cards.png)
```

### 3) Market (Compact)
Caption: Compact market mode for dense scanning.

```md
![Market Compact](docs/screenshots/03-market-compact.png)
```

### 4) Coin Details
Caption: Coin header, chart, metrics, and primary actions.

```md
![Coin Details](docs/screenshots/04-details-chart.png)
```

### 5) Fullscreen Chart
Caption: Fullscreen terminal-like chart with pan/zoom and Y-scale modes.

```md
![Fullscreen Chart](docs/screenshots/05-details-fullscreen-chart.png)
```

### 6) Favorites
Caption: Saved favorites with navigation to details.

```md
![Favorites](docs/screenshots/06-favorites.png)
```

### 7) Portfolio
Caption: Portfolio summary, P/L, allocation donut, and holdings list.

```md
![Portfolio](docs/screenshots/07-portfolio.png)
```

### 8) Add/Edit Holding
Caption: Holding form with decimal amount and avg buy price.

```md
![Add Holding](docs/screenshots/08-add-holding.png)
```

### 9) Notifications List
Caption: Active notifications with state controls.

```md
![Notifications List](docs/screenshots/09-alerts-list.png)
```

### 10) Notification Form
Caption: Create/edit notification with direction and cooldown.

```md
![Notification Form](docs/screenshots/10-alert-form.png)
```

### 11) Converter
Caption: Coin-USD converter with quick amounts and history.

```md
![Converter](docs/screenshots/11-converter.png)
```

### 12) Search
Caption: Dedicated search screen with recent queries.

```md
![Search](docs/screenshots/12-search.png)
```

### 13) Insights
Caption: Market pulse and global analytics overview.

```md
![Insights](docs/screenshots/13-insights.png)
```

### 14) Heatmap
Caption: Market heatmap with scale and pin interactions.

```md
![Heatmap](docs/screenshots/14-heatmap.png)
```

### 15) Categories
Caption: Categories list and category-level market stats.

```md
![Categories](docs/screenshots/15-categories.png)
```

### 16) Exchanges
Caption: Exchange ranking and market information.

```md
![Exchanges](docs/screenshots/16-exchanges.png)
```

### 17) Dominance
Caption: Interactive dominance donut and global market section.

```md
![Dominance](docs/screenshots/17-dominance.png)
```

### 18) Notes
Caption: Notes library with grouped history and empty state.

```md
![Notes](docs/screenshots/18-notes.png)
```

### 19) Settings
Caption: Theme, language, haptics, and app information.

```md
![Settings](docs/screenshots/19-settings.png)
```

### 20) Widgets
Caption: Home screen widget variants.

```md
![Widgets](docs/screenshots/20-widgets.png)
```

## Roadmap
- More advanced background refresh scheduling.
- Extended analytics overlays for chart mode.
- Additional portfolio risk metrics.
- More widget layouts and intent-based deep links.

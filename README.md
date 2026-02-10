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
- Range switching (`1D`, `7D`, `1M`, `3M`, `1Y`).
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

### 1) Animated Splash
Caption: Animated in-app splash shown after static LaunchScreen.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/14e19a9a-938c-451a-ba23-c3d4ccd5ae1c" />


### 2) Market (Cards)
Caption: Market cards mode with sorting, sections, and pull-to-refresh.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/4e5c86d3-0dd2-4500-9db1-cac59b7e52a2" />


### 3) Market (Compact)
Caption: Compact market mode for dense scanning.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/5338860d-37d1-4bc3-8bbb-54417f80d5e9" />


### 4) Coin Details
Caption: Coin header, chart, metrics, and primary actions.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/2fe1cc6a-2fe5-430e-8193-ce888597171e" />
<img width="166" alt="image" src="https://github.com/user-attachments/assets/d5fb02f0-323b-4010-9f61-217808a351fe" />



### 5) Fullscreen Chart
Caption: Fullscreen terminal-like chart with pan/zoom and Y-scale modes.

<img width="166" height="2622" alt="image" src="https://github.com/user-attachments/assets/9e5b85b6-17b6-425c-bbee-4e789da209f3" />
<img width="166" alt="image" src="https://github.com/user-attachments/assets/f1e9c11f-f461-462c-9fd5-7b541cf78558" />



### 6) Favorites
Caption: Saved favorites with navigation to details.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/a41cd79a-c6bb-4ed8-9e11-debd7743352b" />
<img width="166" alt="image" src="https://github.com/user-attachments/assets/7a028df6-04ab-4c8d-a46e-9b618bc94619" />



### 7) Portfolio
Caption: Portfolio summary, P/L, allocation donut, and holdings list.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/bbc55495-99da-4a23-b4e3-040b00a2a934" />
<img width="166" alt="image" src="https://github.com/user-attachments/assets/c6aa3aca-927a-4afc-a742-8586195df39f" />



### 8) Add/Edit Holding
Caption: Holding form with decimal amount and avg buy price.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/deae6b18-687e-460d-927a-824e05faeeb4" />


### 9) Notifications List
Caption: Active notifications with state controls.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/9dd4bcb5-f1d7-421b-a077-b64ad4060281" />
<img width="166" alt="image" src="https://github.com/user-attachments/assets/889b9729-d72c-4a5c-a12f-88a974ee72ca" />


### 10) Notification Form
Caption: Create/edit notification with direction and cooldown.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/f5283445-bdde-4de0-ab98-3c6ad30fbe71" />


### 11) Converter
Caption: Coin-USD converter with quick amounts and history.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/f9cbfc70-bacc-41ae-86d6-f93d822dac74" />
<img width="166" alt="image" src="https://github.com/user-attachments/assets/f06ec8d4-d431-4a9e-9905-a8e407d8dd71" />



### 12) Search
Caption: Dedicated search screen with recent queries.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/4ccaa36d-6d34-455c-a78a-d1ba62c9c108" />
<img width="166" alt="image" src="https://github.com/user-attachments/assets/922755d0-116b-4380-999d-33746caaf20c" />



### 13) Insights
Caption: Market pulse and global analytics overview.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/b5da9683-21fe-4bea-a42b-32d9ea4bc67d" />


### 14) Heatmap
Caption: Market heatmap with scale and pin interactions.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/05ac0d44-b00f-450f-aa8f-22756e8b5090" />


### 15) Categories
Caption: Categories list and category-level market stats.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/df8cca4b-f2fa-4bcf-8e27-8fd67087b8f9" />
<img width="166" alt="image" src="https://github.com/user-attachments/assets/b7dada68-cc1f-43a9-b0b0-f7f993760242" />



### 16) Exchanges
Caption: Exchange ranking and market information.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/0defb8db-0e04-41e0-94ab-bb3fb688556b" />


### 17) Dominance
Caption: Interactive dominance donut and global market section.

<img width="166" height="2622" alt="image" src="https://github.com/user-attachments/assets/a886cfe8-6832-43eb-896f-5dece2313e9f" />


### 18) Notes
Caption: Notes library with grouped history and empty state.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/cbc7cb5f-ae67-4b38-a79e-1f1fecd15ac4" />
<img width="166" alt="image" src="https://github.com/user-attachments/assets/08128bd7-9a61-4da2-a0ad-3f7fb05b5f14" />
<img width="166" alt="image" src="https://github.com/user-attachments/assets/dbf2dda1-9e61-486f-9254-b97562ff9651" />




### 19) Settings
Caption: Theme, language, haptics, and app information.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/d3280e4b-cb17-4e07-afa8-68f7fdd42405" />


### 20) Widgets
Caption: Home screen widget variants.

<img width="166" alt="image" src="https://github.com/user-attachments/assets/f93b392e-dc05-4eb3-981c-4392c7156311" />
<img width="166" alt="image" src="https://github.com/user-attachments/assets/8aecb196-6e94-43d4-a4d3-54c9163ecc11" />


## Demo video

▶️ [CryptoPulse — app walkthrough (YouTube)](https://youtu.be/EvhGd2cv4x0)

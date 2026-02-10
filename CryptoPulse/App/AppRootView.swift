import SwiftUI

struct AppRootView: View {
    @State private var showSplash = true
    private let container: AppDIContainer

    init(container: AppDIContainer = AppDIContainer()) {
        self.container = container
    }

    var body: some View {
        let isMock = ProcessInfo.processInfo.arguments.contains("-use-mock-data") || ProcessInfo.processInfo.arguments.contains("-ui-testing")
        ZStack {
            if !AppConfig.isConfigurationValid && !isMock {
                ConfigurationErrorView()
                    .transition(.opacity)
            } else if showSplash {
                AnimatedSplashView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            } else {
                MainTabView(container: container)
                    .transition(.opacity)
            }
        }
        .background(AppBackgroundView())
        .animation(.easeInOut(duration: 0.4), value: showSplash)
    }
}

struct ConfigurationErrorView: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 42))
                .foregroundColor(.orange)
            Text(NSLocalizedString("Configuration Error", comment: ""))
                .font(AppTypography.title)
            Text(NSLocalizedString("Missing COINGECKO_API_KEY.\nPlease set it via Secrets.xcconfig and Info.plist build setting.", comment: ""))
                .font(AppTypography.body)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal)
        }
        .padding(AppSpacing.lg)
    }
}

struct AnimatedSplashView: View {
    let onFinished: () -> Void
    @State private var animate = false

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            GeometryReader { geo in
                let base = min(geo.size.width, geo.size.height) * 0.35

                VStack(spacing: AppSpacing.lg) {
                    ZStack {
                        Circle()
                            .stroke(AppColors.accent.opacity(0.2), lineWidth: 8)
                            .frame(width: base, height: base)
                            .scaleEffect(animate ? 1.2 : 0.8)
                            .opacity(animate ? 0.2 : 0.6)

                        Circle()
                            .fill(AppColors.accent.opacity(0.15))
                            .frame(width: base * 0.65, height: base * 0.65)
                            .scaleEffect(animate ? 1.1 : 0.9)

                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: base * 0.25, weight: .bold))
                            .foregroundColor(AppColors.accent)
                            .scaleEffect(animate ? 1.05 : 0.95)
                    }

                    Text("CryptoPulse")
                        .font(AppTypography.largeTitle)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                animate = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                onFinished()
            }
        }
    }
}

struct MainTabView: View {
    let container: AppDIContainer
    @State private var selection: AppTab = .market

    var body: some View {
        TabView(selection: $selection) {
            MarketView(
                viewModel: MarketViewModel(repository: container.marketRepository, alertsChecker: container.alertsChecker),
                coinRepository: container.coinRepository,
                favoritesRepository: container.favoritesRepository,
                portfolioRepository: container.portfolioRepository,
                alertsRepository: container.alertsRepository,
                notesRepository: container.notesRepository
            )
            .tabItem { Label(NSLocalizedString("Market", comment: ""), systemImage: "chart.line.uptrend.xyaxis") }
            .tag(AppTab.market)
            .accessibilityIdentifier("tab_market")

            FavoritesView(
                viewModel: FavoritesViewModel(
                    favoritesRepository: container.favoritesRepository,
                    marketRepository: container.marketRepository
                ),
                selection: $selection,
                coinRepository: container.coinRepository,
                favoritesRepository: container.favoritesRepository,
                portfolioRepository: container.portfolioRepository,
                alertsRepository: container.alertsRepository,
                notesRepository: container.notesRepository
            )
            .tabItem { Label(NSLocalizedString("Favorites", comment: ""), systemImage: "star.fill") }
            .tag(AppTab.favorites)
            .accessibilityIdentifier("tab_favorites")

            PortfolioView(
                viewModel: PortfolioViewModel(
                    portfolioRepository: container.portfolioRepository,
                    marketRepository: container.marketRepository
                ),
                marketRepository: container.marketRepository
            )
            .tabItem { Label(NSLocalizedString("Portfolio", comment: ""), systemImage: "briefcase.fill") }
            .tag(AppTab.portfolio)
            .accessibilityIdentifier("tab_portfolio")

            AlertsView(
                viewModel: AlertsViewModel(
                    alertsRepository: container.alertsRepository,
                    marketRepository: container.marketRepository
                ),
                marketRepository: container.marketRepository
            )
            .tabItem { Label(NSLocalizedString("Alerts", comment: ""), systemImage: "bell.badge.fill") }
            .tag(AppTab.alerts)
            .accessibilityIdentifier("tab_alerts")

            MoreView(
                marketRepository: container.marketRepository,
                coinRepository: container.coinRepository,
                favoritesRepository: container.favoritesRepository,
                portfolioRepository: container.portfolioRepository,
                alertsRepository: container.alertsRepository,
                notesRepository: container.notesRepository,
                searchRepository: container.searchRepository,
                conversionHistoryRepository: container.conversionHistoryRepository
            )
                .tabItem { Label(NSLocalizedString("More", comment: ""), systemImage: "ellipsis.circle") }
                .tag(AppTab.more)
                .accessibilityIdentifier("tab_more")
        }
        .background(TabBarSwipeDisabler())
        .onAppear {
            container.alertsChecker.checkAndNotify()
        }
    }
}

#Preview {
    AppRootView()
        .environmentObject(AppEnvironment())
}

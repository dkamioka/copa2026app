/// Configuration for the football-data.org v4 data source — the app's
/// FREE production feed (its free tier covers the current World Cup,
/// verified against the live service: all 104 fixtures, standings,
/// scorers).
///
/// Two live modes, injected at build time via `--dart-define`:
///
/// 1. **Proxy (production)** — requests go to our caching proxy
///    (see `proxy/worker.js`), which holds the token server-side under
///    the `/fd/*` route and collapses all users into a few cached
///    upstream calls (the free tier allows 10 req/min — plenty behind
///    the shared cache):
///
///      flutter build ipa --dart-define=FOOTBALLDATA_PROXY=copa2026.example.workers.dev
///
/// 2. **Direct token (development)** — talks straight to
///    api.football-data.org. Never ship a token inside the binary.
///
///      flutter run --dart-define=FOOTBALLDATA_TOKEN=your_token
///
/// Free-tier trade-offs (vs. the paid API-Football adapter, which
/// remains available): no goal/card timeline per match and no live
/// minute — those sections simply stay hidden in the match sheet.
abstract final class FootballDataConfig {
  static const String directHost = 'api.football-data.org';

  static const String token = String.fromEnvironment('FOOTBALLDATA_TOKEN');

  /// Hostname of the caching proxy (no scheme, HTTPS assumed).
  static const String proxyHost = String.fromEnvironment('FOOTBALLDATA_PROXY');

  static bool get useProxy => proxyHost.isNotEmpty;

  static String get host => useProxy ? proxyHost : directHost;

  /// Path prefix: the proxy multiplexes upstreams by prefix (`/fd/v4/…`),
  /// direct calls hit `/v4/…`.
  static String get basePath => useProxy ? '/fd/v4' : '/v4';

  /// World Cup competition code in football-data.org.
  static const String competition = 'WC';

  /// Whether this source is configured at all.
  static bool get enabled => token.isNotEmpty || proxyHost.isNotEmpty;
}

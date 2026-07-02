/// Configuration for the live API-Football data source.
///
/// Two live modes, both injected at build time via `--dart-define`
/// (nothing sensitive is ever stored in source control):
///
/// 1. **Proxy (production)** — requests go to our caching proxy
///    (see `proxy/worker.js`), which holds the API key server-side and
///    collapses all users into a few cached upstream calls:
///
///      flutter build ipa --dart-define=APIFOOTBALL_PROXY=copa2026.example.workers.dev
///
/// 2. **Direct key (development)** — talks straight to api-sports.io.
///    Never ship this: a key embedded in a public binary is shared by
///    every install and can't be revoked without an app update.
///
///      flutter run --dart-define=APIFOOTBALL_KEY=your_key_here
///
/// With neither define, [useMock] is true and the app runs entirely on
/// the offline illustrative dataset — a fresh clone runs with zero setup.
abstract final class ApiConfig {
  /// Direct api-sports.io host, used only in dev-with-key mode. (If you
  /// subscribe through RapidAPI instead, change this to
  /// `api-football-v1.p.rapidapi.com` and switch the auth header in
  /// [ApiFootballClient] to `x-rapidapi-key`.)
  static const String directHost = 'v3.football.api-sports.io';

  static const String apiKey = String.fromEnvironment('APIFOOTBALL_KEY');

  /// Hostname of the caching proxy (no scheme, HTTPS assumed).
  static const String proxyHost = String.fromEnvironment('APIFOOTBALL_PROXY');

  static bool get useProxy => proxyHost.isNotEmpty;

  /// Host every request goes to. Proxy wins when both are configured.
  static String get host => useProxy ? proxyHost : directHost;

  /// FIFA World Cup league id in API-Football.
  static const int worldCupLeagueId = 1;

  /// Season year to query. The 2026 World Cup is season "2026".
  static const int season = 2026;

  /// When true, the app uses [MockTournamentRepository] instead of the
  /// live API. Auto-derived: no proxy and no key ⇒ mock.
  static bool get useMock => apiKey.isEmpty && proxyHost.isEmpty;
}

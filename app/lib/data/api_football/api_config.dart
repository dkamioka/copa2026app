/// Configuration for the live API-Football data source.
///
/// The API key is injected at build/run time via `--dart-define` and is
/// never stored in source control:
///
///   flutter run --dart-define=APIFOOTBALL_KEY=your_key_here
///
/// If no key is provided, [useMock] is true and the app runs entirely on
/// the offline illustrative dataset — so a fresh clone still runs with
/// zero setup.
abstract final class ApiConfig {
  /// Direct api-sports.io host. (If you subscribe through RapidAPI
  /// instead, change this to `api-football-v1.p.rapidapi.com` and switch
  /// the auth header in [ApiFootballClient] to `x-rapidapi-key`.)
  static const String host = 'v3.football.api-sports.io';

  static const String apiKey = String.fromEnvironment('APIFOOTBALL_KEY');

  /// FIFA World Cup league id in API-Football.
  static const int worldCupLeagueId = 1;

  /// Season year to query. The 2026 World Cup is season "2026".
  static const int season = 2026;

  /// When true, the app uses [MockTournamentRepository] instead of the
  /// live API. Auto-derived: no key ⇒ mock.
  static bool get useMock => apiKey.isEmpty;
}

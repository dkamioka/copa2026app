# Data source — mock vs. live

The app reads all data through one interface, `TournamentRepository`
(`lib/data/tournament_repository.dart`), with three implementations, in
bootstrap priority order:

1. **`FootballDataRepository`** (`lib/data/football_data/`) — live data
   from [football-data.org](https://www.football-data.org/) v4. **The
   production source**: its FREE tier covers the current World Cup
   (verified against the live 2026 feed — all 104 fixtures, standings,
   scorers) at 10 req/min, which the caching proxy makes sufficient for
   any number of app users. Free-tier gaps, degraded gracefully in the
   UI: no goal/card timeline, no live minute, no venue, no injuries.
2. **`ApiFootballRepository`** (`lib/data/api_football/`) — live data
   from [API-Football](https://www.api-football.com/) v3. Optional
   premium source with richer per-match detail (events timeline, live
   minute, injuries); requires a paid plan for season 2026.
3. **`MockTournamentRepository`** — the offline illustrative dataset.
   Used automatically when no live source is configured, so a fresh
   clone runs with zero setup.

## Running with live data

**Production (proxy — the only mode that should ship):** deploy the
caching proxy in [`../proxy/`](../proxy/worker.js) — a Cloudflare Worker
that holds credentials as server-side secrets and collapses all users
into a few edge-cached upstream calls — then point the build at it. No
credential ships in the binary:

```bash
flutter build ipa --dart-define=FOOTBALLDATA_PROXY=copa2026.YOUR-SUBDOMAIN.workers.dev
```

**Development (direct token):** pass your football-data.org token via
`--dart-define`. Tokens are **never** stored in source — and must never
ship in a release build (embedded in a public binary a credential is
shared by every install and can't be revoked without an app update):

```bash
flutter run --dart-define=FOOTBALLDATA_TOKEN=YOUR_TOKEN
# or, for the API-Football source:
flutter run --dart-define=APIFOOTBALL_KEY=YOUR_KEY
```

In Xcode (if you run from there instead of the CLI), add the same
`--dart-define` under the Runner scheme's *Run → Arguments → Arguments
Passed On Launch*, or build via the CLI command above.

With no define at all the app uses the mock.

## Integration tests against real data

```bash
# football-data.org, live 2026 tournament (structural assertions):
flutter test test/football_data_integration_test.dart \
  --dart-define=FOOTBALLDATA_TOKEN=your_token

# API-Football, completed 2022 World Cup (free keys can't read 2026):
flutter test test/live_api_integration_test.dart \
  --dart-define=APIFOOTBALL_KEY=your_key \
  --dart-define=APIFOOTBALL_SEASON=2022
```

Run these before releases — the API-Football suite is what caught the
`page` parameter bug, and the football-data suite validates the actual
production feed (~4 requests per run).

## How it maps to the app

| Screen / feature | API-Football endpoint |
|---|---|
| Bracket (per round) | `/fixtures?league=1&season=2026` → grouped by `league.round` |
| Live banner | first fixture with a live status (`1H/2H/HT/ET/P/…`) |
| Classificação (groups) | `/standings?league=1&season=2026` |
| Artilheiros | `/players/topscorers?league=1&season=2026` |
| Match timeline | `/fixtures/events?fixture={id}` |
| Confrontos diretos (H2H) | `/fixtures/headtohead?h2h={homeId}-{awayId}` |
| Desfalques & novidades | `/injuries?fixture={id}` |
| Campanha nos grupos | derived from cached group-stage fixtures + standings |

- **Bulk data** (fixtures, standings, scorers) loads once at startup via
  `refresh()` — ~3 calls (+ pagination).
- **Per-match detail** (timeline, H2H, injuries) loads lazily the first
  time you open a match, then is cached for 2 minutes — ~3 calls per
  match, once.

This keeps request usage low enough to develop on the free tier
(100 req/day). During the tournament you'd want the $50/mo Starter plan.

## QA against real data (free-tier key)

Free API-Football plans **cannot read season 2026** (they're limited to
2022–2024 — a paid plan is mandatory for production). The full live
pipeline is still verifiable end-to-end against the completed 2022 World
Cup, whose data is stable and fully known:

```bash
flutter test test/live_api_integration_test.dart \
  --dart-define=APIFOOTBALL_KEY=your_key \
  --dart-define=APIFOOTBALL_SEASON=2022
```

The same `APIFOOTBALL_SEASON` define also works with `flutter run`, so
the whole app can be driven by real (historical) data on a free key.
This suite is what caught the `page` parameter bug below — keep running
it before releases (~6 requests of quota per run).

## Known limitations / notes

- **`page` query param**: several endpoints (`/fixtures` among them)
  reject an explicit `page` field with an error envelope. The client
  therefore never sends `page` on the first request and only paginates
  when `paging.total > 1` (verified against the live service).

- **Suspensions** aren't a first-class field in any football API — they're
  derived from the `/injuries` feed's `reason` (e.g. "Red Card",
  "Yellow Cards") plus injuries. Coverage is best-effort.
- **Penalty shootouts**: the API exposes only the shootout totals, not
  the kick-by-kick sequence, so the shootout view shows one "scored"
  marker per goal rather than the full make/miss order.
- **Team identity**: teams are matched to the app's PT-BR name + flag +
  kit colors by English name (`lib/data/api_football/team_lookup.dart`).
  The 32 teams from the design are covered; any others fall back to a
  neutral chip with the API's name — extend `_englishToCode` to add more.
- The live path could not be exercised in the build environment (its
  network policy blocks the API host); the JSON→model mappers are covered
  by offline unit tests in `test/api_football_mappers_test.dart`.
- If you subscribe via RapidAPI instead of api-sports.io directly, change
  `ApiConfig.host` and the auth header in `ApiFootballClient` (noted in
  those files).

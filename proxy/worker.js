/**
 * Cloudflare Worker: caching proxy in front of API-Football.
 *
 * Why this exists: the app ships WITHOUT any API key in the binary.
 * Every installed copy would otherwise share one hardcoded key — the
 * free tier (100 req/day) dies with ~30 installs, and a leaked key is
 * unrevokable without an app update. The worker holds the key as a
 * secret and collapses all users into a handful of upstream calls via
 * the edge cache (30s for live data — scores stay fresh — and every
 * user piggybacks on the same cached response).
 *
 * Deploy:
 *   cd proxy
 *   npx wrangler deploy
 *   npx wrangler secret put APIFOOTBALL_KEY
 *
 * Then build the app pointing at the worker (no key in the build!):
 *   flutter build ipa --dart-define=APIFOOTBALL_PROXY=copa2026.<account>.workers.dev
 */

const UPSTREAM = 'https://v3.football.api-sports.io';

// Only the endpoints the app actually uses — anything else is refused so
// the key can't be farmed for other data through our proxy.
const ALLOWED_PATHS = new Set([
  '/fixtures',
  '/standings',
  '/players/topscorers',
  '/fixtures/events',
  '/fixtures/headtohead',
  '/injuries',
]);

// Edge-cache TTL per path (seconds). Live-ish data stays short; slower-
// moving data can ride longer and save quota.
const TTL = {
  '/fixtures': 30,
  '/fixtures/events': 30,
  '/standings': 120,
  '/players/topscorers': 300,
  '/fixtures/headtohead': 3600,
  '/injuries': 300,
};

export default {
  async fetch(request, env, ctx) {
    if (request.method !== 'GET') {
      return new Response('Method not allowed', { status: 405 });
    }

    const url = new URL(request.url);
    if (!ALLOWED_PATHS.has(url.pathname)) {
      return new Response('Not found', { status: 404 });
    }

    // Normalize the query (sorted params) so equivalent requests share
    // one cache entry regardless of client-side param ordering.
    const params = [...url.searchParams.entries()].sort(([a], [b]) =>
      a < b ? -1 : a > b ? 1 : 0
    );
    const upstreamUrl = new URL(UPSTREAM + url.pathname);
    for (const [k, v] of params) upstreamUrl.searchParams.append(k, v);

    const cache = caches.default;
    const cacheKey = new Request(upstreamUrl.toString());
    const cached = await cache.match(cacheKey);
    if (cached) return cached;

    const upstreamRes = await fetch(upstreamUrl, {
      headers: { 'x-apisports-key': env.APIFOOTBALL_KEY },
    });

    const ttl = TTL[url.pathname] ?? 60;
    const res = new Response(upstreamRes.body, upstreamRes);
    res.headers.set('Cache-Control', `public, max-age=${ttl}`);
    // Never cache upstream failures — one bad answer would be replayed
    // to every user for the whole TTL.
    if (upstreamRes.ok) {
      ctx.waitUntil(cache.put(cacheKey, res.clone()));
    }
    return res;
  },
};

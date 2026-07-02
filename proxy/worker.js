/**
 * Cloudflare Worker: caching proxy in front of the app's data sources.
 *
 * Why this exists: the app ships WITHOUT any API credential in the
 * binary. Every installed copy would otherwise share one hardcoded
 * key/token — leaked and unrevokable without an app update, and the
 * free tiers' rate limits die with a handful of installs. The worker
 * holds credentials as secrets and collapses all users into a few
 * upstream calls via the edge cache.
 *
 * Upstreams, multiplexed by path prefix:
 *   /fd/v4/*  → api.football-data.org (X-Auth-Token: FOOTBALLDATA_TOKEN)
 *               The FREE production source — its free tier covers the
 *               2026 World Cup (10 req/min upstream; the cache keeps us
 *               far below that no matter how many app users).
 *   /*        → v3.football.api-sports.io (x-apisports-key:
 *               APIFOOTBALL_KEY) — optional paid source with richer
 *               per-match detail.
 *
 * Deploy:
 *   cd proxy
 *   npx wrangler deploy
 *   npx wrangler secret put FOOTBALLDATA_TOKEN
 *   npx wrangler secret put APIFOOTBALL_KEY      # only if used
 *
 * Then build the app pointing at the worker (no credential in the build):
 *   flutter build ipa --dart-define=FOOTBALLDATA_PROXY=copa2026.<account>.workers.dev
 */

// Only the endpoints the app actually uses — anything else is refused
// so the credentials can't be farmed for other data through our proxy.
const FD_ALLOWED = [
  /^\/fd\/v4\/competitions\/WC\/matches$/,
  /^\/fd\/v4\/competitions\/WC\/standings$/,
  /^\/fd\/v4\/competitions\/WC\/scorers$/,
  /^\/fd\/v4\/matches\/\d+\/head2head$/,
];

const AF_ALLOWED = new Set([
  '/fixtures',
  '/standings',
  '/players/topscorers',
  '/fixtures/events',
  '/fixtures/headtohead',
  '/injuries',
]);

// Edge-cache TTL (seconds). Live-ish data stays short; slower-moving
// data rides longer and saves upstream quota.
function ttlFor(pathname) {
  if (pathname.endsWith('/matches') || pathname === '/fixtures') return 30;
  if (pathname.endsWith('/standings') || pathname === '/standings') return 120;
  if (pathname.endsWith('/scorers') || pathname === '/players/topscorers') return 300;
  if (pathname.includes('head2head') || pathname === '/fixtures/headtohead') return 3600;
  if (pathname === '/fixtures/events') return 30;
  if (pathname === '/injuries') return 300;
  return 60;
}

function upstreamFor(url, env) {
  if (url.pathname.startsWith('/fd/')) {
    if (!FD_ALLOWED.some((re) => re.test(url.pathname))) return null;
    return {
      base: 'https://api.football-data.org' + url.pathname.slice(3),
      headers: { 'X-Auth-Token': env.FOOTBALLDATA_TOKEN },
    };
  }
  if (!AF_ALLOWED.has(url.pathname)) return null;
  return {
    base: 'https://v3.football.api-sports.io' + url.pathname,
    headers: { 'x-apisports-key': env.APIFOOTBALL_KEY },
  };
}

export default {
  async fetch(request, env, ctx) {
    if (request.method !== 'GET') {
      return new Response('Method not allowed', { status: 405 });
    }

    const url = new URL(request.url);
    const upstream = upstreamFor(url, env);
    if (!upstream) return new Response('Not found', { status: 404 });

    // Normalize the query (sorted params) so equivalent requests share
    // one cache entry regardless of client-side param ordering.
    const params = [...url.searchParams.entries()].sort(([a], [b]) =>
      a < b ? -1 : a > b ? 1 : 0
    );
    const upstreamUrl = new URL(upstream.base);
    for (const [k, v] of params) upstreamUrl.searchParams.append(k, v);

    const cache = caches.default;
    const cacheKey = new Request(upstreamUrl.toString());
    const cached = await cache.match(cacheKey);
    if (cached) return cached;

    const upstreamRes = await fetch(upstreamUrl, { headers: upstream.headers });

    const res = new Response(upstreamRes.body, upstreamRes);
    res.headers.set('Cache-Control', `public, max-age=${ttlFor(url.pathname)}`);
    // Never cache upstream failures — one bad answer would be replayed
    // to every user for the whole TTL.
    if (upstreamRes.ok) {
      ctx.waitUntil(cache.put(cacheKey, res.clone()));
    }
    return res;
  },
};

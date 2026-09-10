// The Cloudflare Workers shell. All the decisions live in `handler.mjs`;
// this only translates between `Request`/`Response` and that.
//
// Why Workers: the evaluation call can take most of the 30s the client
// allows, and Workers bills CPU time rather than wall time — waiting on
// OpenAI costs nothing. What this actually computes (parse, build, ground a
// handful of quotes) sits well inside the free tier's 10ms budget.
import { MAX_BODY_BYTES, corsHeaders, handleCoachRequest } from "./handler.mjs";

/// Separate buckets because the two calls do not cost the same: a rehearsal
/// sends three replies and exactly one evaluation, and the evaluation is the
/// expensive half. Limits and periods live in `wrangler.toml`.
const LIMITERS = {
  "/simulation/respond": "RESPOND_LIMITER",
  "/simulation/evaluate": "EVALUATE_LIMITER",
};

/**
 * Refuses a caller who is going too fast.
 *
 * Keyed on the client IP, with everything unattributable sharing one bucket
 * — a request with no `cf-connecting-ip` should not get its own allowance.
 *
 * Cloudflare counts per location and is explicit that this is eventually
 * consistent rather than an accounting system, so the real ceiling is higher
 * than the configured number. That is fine for what this is guarding
 * against, which is a script, not a rounding error.
 *
 * Missing bindings mean no limit rather than no service, so `wrangler dev`
 * without them still works.
 */
async function withinRateLimit(path, request, env) {
  const limiter = env[LIMITERS[path]];
  if (!limiter) return true;

  const { success } = await limiter.limit({
    key: request.headers.get("cf-connecting-ip") ?? "unattributed",
  });
  return success;
}

async function readJson(request) {
  // Checked twice on purpose: the header is a claim, the body is the fact.
  const declared = Number(request.headers.get("content-length") ?? 0);
  if (declared > MAX_BODY_BYTES) throw new Error("Request is too large.");

  const text = await request.text();
  if (text.length > MAX_BODY_BYTES) throw new Error("Request is too large.");
  return JSON.parse(text);
}

export default {
  async fetch(request, env) {
    const { status, body } = await handleCoachRequest({
      method: request.method,
      path: new URL(request.url).pathname,
      readBody: () => readJson(request),
      checkRateLimit: (path) => withinRateLimit(path, request, env),
      options: {
        // Workers has no `process.env`. Passing these through is what keeps
        // `coach.mjs` runtime-agnostic.
        apiKey: env.OPENAI_API_KEY,
        model: env.OPENAI_MODEL,
      },
    });

    return new Response(body === null ? null : JSON.stringify(body), {
      status,
      headers: corsHeaders(env.ALLOWED_ORIGIN),
    });
  },
};

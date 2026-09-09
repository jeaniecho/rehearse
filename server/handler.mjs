// Routing, validation and error shaping, with no runtime attached.
//
// Two shells import this: `server.mjs` for local Node, `worker.mjs` for
// Cloudflare. Keeping the decisions here rather than in each shell is
// deliberate — a duplicated model string once left `/health` reporting a
// model the app was not using, and an allowlist that had drifted from its
// schema silently dropped a field for a whole release.
import { DEFAULT_MODEL, evaluateWithOpenAI, respondWithOpenAI } from "./coach.mjs";

/// Enough for a scenario, a transcript and a long message, and far short of
/// anything worth paying to parse.
export const MAX_BODY_BYTES = 64 * 1024;

export function validRespond(payload) {
  if (!payload || typeof payload !== "object") return false;
  if (!payload.scenario || typeof payload.scenario !== "object") return false;
  if (typeof payload.managerResponse !== "string") return false;
  const length = payload.managerResponse.trim().length;
  return length >= 3 && length <= 2000;
}

export function validEvaluate(payload) {
  if (!payload || typeof payload !== "object") return false;
  if (!payload.scenario || typeof payload.scenario !== "object") return false;
  if (!Array.isArray(payload.history) || payload.history.length === 0) {
    return false;
  }
  return payload.history.every(
    (turn) => turn && typeof turn.managerResponse === "string",
  );
}

// Simulation and evaluation are separate model tasks with separate prompts
// (PRD §22), so they are separate endpoints too.
export const routes = {
  "/simulation/respond": { validate: validRespond, run: respondWithOpenAI },
  "/simulation/evaluate": { validate: validEvaluate, run: evaluateWithOpenAI },
};

export function corsHeaders(allowedOrigin = "*") {
  return {
    "access-control-allow-headers": "content-type",
    "access-control-allow-methods": "GET,POST,OPTIONS",
    "access-control-allow-origin": allowedOrigin,
    "content-type": "application/json; charset=utf-8",
  };
}

/**
 * Answers one request. Returns `{ status, body }`; the shell turns that into
 * whatever its runtime calls a response.
 *
 * `readBody` is a function rather than a value so a request that is never
 * going to be routed is never read.
 *
 * `options` carries `apiKey` and `model` from wherever the shell keeps its
 * environment — `process.env` on Node, the `env` argument on Workers. Passing
 * them explicitly is what lets `coach.mjs` stay free of both.
 *
 * `checkRateLimit(path)` returns false to refuse the request. The mechanism
 * belongs to the shell — Cloudflare has a binding for it, local Node has
 * nothing and passes none — but *which* routes are limited, and what a
 * refusal looks like, are decided here with every other route rule.
 */
export async function handleCoachRequest({
  method,
  path,
  readBody,
  options = {},
  checkRateLimit,
}) {
  if (method === "OPTIONS") return { status: 204, body: null };

  if (method === "GET" && path === "/health") {
    return {
      status: 200,
      body: {
        ok: true,
        model: options.model ?? DEFAULT_MODEL,
        routes: Object.keys(routes),
      },
    };
  }

  const route = method === "POST" ? routes[path] : undefined;
  if (!route) return { status: 404, body: { error: "Not found." } };

  // After routing so a wrong path cannot burn someone's quota, and before
  // the body is read so a flood does not get parsed on the way to being
  // refused. Only the two model-calling routes are limited: `/health` and
  // preflight cost nothing and are worth keeping answerable.
  if (checkRateLimit && !(await checkRateLimit(path))) {
    return {
      status: 429,
      body: { error: "Too many requests. Try again in a moment." },
    };
  }

  try {
    const payload = await readBody();
    if (!route.validate(payload)) {
      return { status: 400, body: { error: "Invalid coaching request." } };
    }
    return { status: 200, body: await route.run(payload, options) };
  } catch (error) {
    console.error(error);
    // A missing key is the operator's problem and a fixable one, so it is
    // worth telling apart from the model being down.
    const configurationError =
      error instanceof Error && error.message.includes("OPENAI_API_KEY");
    return {
      status: configurationError ? 503 : 502,
      body: {
        error: configurationError
          ? "The AI coach is not configured."
          : "The AI coach is temporarily unavailable.",
      },
    };
  }
}

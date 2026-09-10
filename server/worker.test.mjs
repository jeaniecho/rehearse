// Covers the shell seam — routing, status codes, CORS and the env plumbing.
//
// This file exists because the last bug here lived exactly where nothing
// looked: `coach.test.mjs` tests the request builders, and the Flutter tests
// drive a fake coach, so the mapping between them was never exercised.
import assert from "node:assert/strict";
import test from "node:test";

import { DEFAULT_MODEL } from "./coach.mjs";
import { handleCoachRequest } from "./handler.mjs";
import worker from "./worker.mjs";

const scenario = {
  id: "missed-deadlines",
  title: "The slipping deadline",
  context: "Jordan has missed two design handoffs this month.",
  goal: "Name the pattern and agree a next step.",
  personName: "Jordan Lee",
  personRole: "Senior product designer",
};

const respondBody = {
  sessionId: "worker-test",
  scenario,
  difficulty: "defensive",
  turn: { index: 1, isLast: false },
  history: [{ turnIndex: 0, managerResponse: "We need to talk about Friday." }],
  managerResponse: "The handoff slipped twice and engineering is blocked.",
};

/** A stand-in for the OpenAI endpoint that returns [body] as the model output. */
function modelReturning(body) {
  return async () => ({
    ok: true,
    json: async () => ({
      output: [
        {
          type: "message",
          content: [{ type: "output_text", text: JSON.stringify(body) }],
        },
      ],
    }),
  });
}

/** Swaps global fetch for the length of [run], so the worker can be driven
 *  end to end without reaching the network. */
async function withStubbedFetch(stub, run) {
  const real = globalThis.fetch;
  globalThis.fetch = stub;
  try {
    return await run();
  } finally {
    globalThis.fetch = real;
  }
}

const post = (path, body) =>
  new Request(`https://coach.test${path}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });

test("health reports the model that is actually live", async () => {
  const fallback = await handleCoachRequest({
    method: "GET",
    path: "/health",
    readBody: async () => ({}),
  });
  assert.equal(fallback.body.model, DEFAULT_MODEL);

  const overridden = await handleCoachRequest({
    method: "GET",
    path: "/health",
    readBody: async () => ({}),
    options: { model: "gpt-5.6-terra" },
  });
  assert.equal(overridden.body.model, "gpt-5.6-terra");
});

test("a request is never read unless it is going to be routed", async () => {
  let read = false;
  const result = await handleCoachRequest({
    method: "POST",
    path: "/nope",
    readBody: async () => {
      read = true;
      return {};
    },
  });

  assert.equal(result.status, 404);
  assert.equal(read, false);
});

test("a malformed payload is rejected before any model is called", async () => {
  const result = await handleCoachRequest({
    method: "POST",
    path: "/simulation/respond",
    readBody: async () => ({ scenario, managerResponse: "no" }),
    options: { apiKey: "unused" },
  });

  assert.equal(result.status, 400);
});

test("a missing key is a configuration error, not an outage", async () => {
  const result = await handleCoachRequest({
    method: "POST",
    path: "/simulation/respond",
    readBody: async () => respondBody,
    options: { apiKey: undefined },
  });

  assert.equal(result.status, 503);
  assert.match(result.body.error, /not configured/);
});

test("the worker answers health with CORS applied", async () => {
  const response = await worker.fetch(
    new Request("https://coach.test/health"),
    { ALLOWED_ORIGIN: "https://rehearse.app" },
  );

  assert.equal(response.status, 200);
  assert.equal(
    response.headers.get("access-control-allow-origin"),
    "https://rehearse.app",
  );
  assert.equal((await response.json()).ok, true);
});

test("a preflight carries no body", async () => {
  const response = await worker.fetch(
    new Request("https://coach.test/simulation/respond", { method: "OPTIONS" }),
    {},
  );

  assert.equal(response.status, 204);
  assert.equal(await response.text(), "");
});

test("the worker passes its env key through to the model call", async () => {
  // Proves the whole chain: Request -> handler -> coach -> OpenAI, using the
  // key from `env` rather than a `process.env` that Workers does not have.
  let sawAuth;
  const response = await withStubbedFetch(
    async (_url, options) => {
      sawAuth = options.headers.authorization;
      return modelReturning({
        reply: "The scope keeps moving though.",
        emotion: "defensive",
        resolution: "continuing",
      })();
    },
    () =>
      worker.fetch(post("/simulation/respond", respondBody), {
        OPENAI_API_KEY: "sk-from-env",
      }),
  );

  assert.equal(response.status, 200);
  assert.equal(sawAuth, "Bearer sk-from-env");
});

test("the declared resolution survives the worker too", async () => {
  // The Node shell has this covered in coach.test.mjs. Both shells ship, so
  // both are checked — a field dropped on one is a bug on that platform only.
  const response = await withStubbedFetch(
    modelReturning({
      reply: "Fine. I hear you.",
      emotion: "resigned",
      resolution: "resolved",
    }),
    () =>
      worker.fetch(post("/simulation/respond", respondBody), {
        OPENAI_API_KEY: "sk-test",
      }),
  );

  assert.equal((await response.json()).resolution, "resolved");
});

test("an oversized body is refused", async () => {
  const response = await worker.fetch(
    post("/simulation/respond", {
      ...respondBody,
      scenario: { ...scenario, context: "x".repeat(70 * 1024) },
    }),
    { OPENAI_API_KEY: "sk-test" },
  );

  assert.equal(response.status, 502);
});


/** A limiter binding that records its keys and answers [allow]. */
function limiter(allow) {
  const keys = [];
  return { keys, limit: async ({ key }) => (keys.push(key), { success: allow }) };
}

test("a refused caller never reaches the model", async () => {
  // The point of the limit. If this ever calls fetch, the limit is costing
  // money instead of saving it.
  let called = false;
  const response = await withStubbedFetch(
    async () => {
      called = true;
      throw new Error("should not have been called");
    },
    () =>
      worker.fetch(post("/simulation/respond", respondBody), {
        OPENAI_API_KEY: "sk-test",
        RESPOND_LIMITER: limiter(false),
      }),
  );

  assert.equal(response.status, 429);
  assert.equal(called, false);
});

test("the two endpoints draw on separate buckets", async () => {
  // A rehearsal sends three replies and one evaluation. Sharing one bucket
  // would let the cheap call starve the expensive one.
  const respond = limiter(true);
  const evaluate = limiter(false);

  const allowed = await withStubbedFetch(
    modelReturning({ reply: "Go on.", emotion: "calm", resolution: "continuing" }),
    () =>
      worker.fetch(post("/simulation/respond", respondBody), {
        OPENAI_API_KEY: "sk-test",
        RESPOND_LIMITER: respond,
        EVALUATE_LIMITER: evaluate,
      }),
  );

  assert.equal(allowed.status, 200);
  assert.equal(respond.keys.length, 1);
  assert.equal(evaluate.keys.length, 0, "the other bucket was untouched");
});

test("the limit is keyed on the caller, not the whole world", async () => {
  const bucket = limiter(true);
  await withStubbedFetch(
    modelReturning({ reply: "Go on.", emotion: "calm", resolution: "continuing" }),
    () =>
      worker.fetch(
        new Request("https://coach.test/simulation/respond", {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "cf-connecting-ip": "203.0.113.7",
          },
          body: JSON.stringify(respondBody),
        }),
        { OPENAI_API_KEY: "sk-test", RESPOND_LIMITER: bucket },
      ),
  );

  assert.deepEqual(bucket.keys, ["203.0.113.7"]);
});

test("a caller with no attributable address shares one bucket", async () => {
  const bucket = limiter(true);
  await withStubbedFetch(
    modelReturning({ reply: "Go on.", emotion: "calm", resolution: "continuing" }),
    () =>
      worker.fetch(post("/simulation/respond", respondBody), {
        OPENAI_API_KEY: "sk-test",
        RESPOND_LIMITER: bucket,
      }),
  );

  assert.deepEqual(bucket.keys, ["unattributed"]);
});

test("health and preflight are never rate limited", async () => {
  // Refusing these buys nothing — neither calls a model — and a health check
  // that can be rate limited is a monitoring problem.
  const bucket = limiter(false);
  const env = {
    RESPOND_LIMITER: bucket,
    EVALUATE_LIMITER: bucket,
    OPENAI_API_KEY: "sk-test",
  };

  const health = await worker.fetch(new Request("https://coach.test/health"), env);
  const preflight = await worker.fetch(
    new Request("https://coach.test/simulation/respond", { method: "OPTIONS" }),
    env,
  );

  assert.equal(health.status, 200);
  assert.equal(preflight.status, 204);
  assert.equal(bucket.keys.length, 0);
});

test("an unknown path cannot burn someone's quota", async () => {
  const bucket = limiter(true);
  const response = await worker.fetch(post("/nope", respondBody), {
    RESPOND_LIMITER: bucket,
  });

  assert.equal(response.status, 404);
  assert.equal(bucket.keys.length, 0);
});

test("no binding means no limit, not no service", async () => {
  // `wrangler dev` and the Node shell run without bindings.
  const response = await withStubbedFetch(
    modelReturning({ reply: "Go on.", emotion: "calm", resolution: "continuing" }),
    () =>
      worker.fetch(post("/simulation/respond", respondBody), {
        OPENAI_API_KEY: "sk-test",
      }),
  );

  assert.equal(response.status, 200);
});

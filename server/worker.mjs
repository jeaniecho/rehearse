// The Cloudflare Workers shell. All the decisions live in `handler.mjs`;
// this only translates between `Request`/`Response` and that.
//
// Why Workers: the evaluation call can take most of the 30s the client
// allows, and Workers bills CPU time rather than wall time — waiting on
// OpenAI costs nothing. What this actually computes (parse, build, ground a
// handful of quotes) sits well inside the free tier's 10ms budget.
import { MAX_BODY_BYTES, corsHeaders, handleCoachRequest } from "./handler.mjs";

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

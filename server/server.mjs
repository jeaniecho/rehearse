// The local Node shell, for `npm start` during development.
//
// Cloudflare is what runs in production — see `worker.mjs` and
// `wrangler.toml`. Both shells route through `handler.mjs`, so there is one
// place where a route, a validation rule or an error code is decided.
import { createServer } from "node:http";

import { MAX_BODY_BYTES, corsHeaders, handleCoachRequest } from "./handler.mjs";

const port = Number(process.env.PORT ?? 8787);
const host = process.env.HOST ?? "127.0.0.1";

async function readJson(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) throw new Error("Request is too large.");
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString("utf8"));
}

const server = createServer(async (request, response) => {
  const { status, body } = await handleCoachRequest({
    method: request.method,
    path: (request.url ?? "").split("?")[0],
    readBody: () => readJson(request),
    options: {
      apiKey: process.env.OPENAI_API_KEY,
      model: process.env.OPENAI_MODEL,
    },
  });

  response.writeHead(status, corsHeaders(process.env.ALLOWED_ORIGIN));
  response.end(body === null ? undefined : JSON.stringify(body));
});

server.listen(port, host, () => {
  console.log(`Rehearse coach listening on http://${host}:${port}`);
});

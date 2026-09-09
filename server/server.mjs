import { createServer } from "node:http";

import {
  DEFAULT_MODEL,
  evaluateWithOpenAI,
  respondWithOpenAI,
} from "./coach.mjs";

const port = Number(process.env.PORT ?? 8787);
const host = process.env.HOST ?? "127.0.0.1";
const allowedOrigin = process.env.ALLOWED_ORIGIN ?? "*";

function sendJson(response, status, body) {
  response.writeHead(status, {
    "access-control-allow-headers": "content-type",
    "access-control-allow-methods": "GET,POST,OPTIONS",
    "access-control-allow-origin": allowedOrigin,
    "content-type": "application/json; charset=utf-8",
  });
  response.end(JSON.stringify(body));
}

async function readJson(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > 64 * 1024) throw new Error("Request is too large.");
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString("utf8"));
}

function validRespond(payload) {
  if (!payload || typeof payload !== "object") return false;
  if (!payload.scenario || typeof payload.scenario !== "object") return false;
  if (typeof payload.managerResponse !== "string") return false;
  const length = payload.managerResponse.trim().length;
  return length >= 3 && length <= 2000;
}

function validEvaluate(payload) {
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
const routes = {
  "/simulation/respond": { validate: validRespond, run: respondWithOpenAI },
  "/simulation/evaluate": { validate: validEvaluate, run: evaluateWithOpenAI },
};

const server = createServer(async (request, response) => {
  if (request.method === "OPTIONS") {
    sendJson(response, 204, {});
    return;
  }

  if (request.method === "GET" && request.url === "/health") {
    sendJson(response, 200, {
      ok: true,
      model: process.env.OPENAI_MODEL ?? DEFAULT_MODEL,
      routes: Object.keys(routes),
    });
    return;
  }

  const route = request.method === "POST" ? routes[request.url] : undefined;
  if (!route) {
    sendJson(response, 404, { error: "Not found." });
    return;
  }

  try {
    const payload = await readJson(request);
    if (!route.validate(payload)) {
      sendJson(response, 400, { error: "Invalid coaching request." });
      return;
    }
    sendJson(response, 200, await route.run(payload));
  } catch (error) {
    console.error(error);
    const configurationError =
      error instanceof Error && error.message.includes("OPENAI_API_KEY");
    sendJson(response, configurationError ? 503 : 502, {
      error: configurationError
        ? "The AI coach is not configured."
        : "The AI coach is temporarily unavailable.",
    });
  }
});

server.listen(port, host, () => {
  console.log(`Rehearse coach listening on http://${host}:${port}`);
});

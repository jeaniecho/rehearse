import assert from "node:assert/strict";
import test from "node:test";

import {
  buildEvaluateRequest,
  temperamentFor,
  buildRespondRequest,
  evaluateWithOpenAI,
  extractOutputText,
  groundNotes,
  overallFrom,
  respondWithOpenAI,
} from "./coach.mjs";

const scenario = {
  title: "The slipping deadline",
  context: "A teammate missed two handoffs.",
  goal: "Agree on a clear next step.",
  personName: "Jordan Lee",
  personRole: "Senior product designer",
};

const managerSaid =
  "I see how much you have taken on. We still need to address the missed handoffs.";

const respondPayload = {
  sessionId: "local-test-session",
  scenario,
  difficulty: "defensive",
  turn: { index: 0, isLast: false },
  history: [],
  managerResponse: managerSaid,
};

const evaluatePayload = {
  sessionId: "local-test-session",
  scenario,
  history: [
    {
      turnIndex: 0,
      managerResponse: managerSaid,
      employeeReply: "The scope keeps moving though.",
    },
  ],
};

function respondWith(body) {
  return async (_url, options) => ({
    ok: true,
    json: async () => ({
      output: [
        {
          type: "message",
          content: [{ type: "output_text", text: JSON.stringify(body) }],
        },
      ],
      _request: JSON.parse(options.body),
    }),
  });
}

test("the simulation prompt stays in character and never coaches", () => {
  const request = buildRespondRequest(respondPayload);
  const instructions = request.input[0].content[0].text;

  assert.equal(request.text.format.name, "employee_reply");
  assert.match(instructions, /NOT a coach/);
  assert.match(instructions, /Stay in character/);
  assert.match(instructions, /untrusted data/);
  // The employee has to know who they are.
  assert.match(instructions, /Jordan Lee/);
});

// The authored dialogue runs 16 words at the median and 29 at its longest.
// A model reply twice that length stops reading as speech, which is the whole
// illusion — so the ceiling is in the prompt and asserted here.
test("the simulation prompt keeps the reply spoken-length", () => {
  const instructions = buildRespondRequest(respondPayload).input[0].content[0]
    .text;

  assert.match(instructions, /never more than 40/);
  assert.match(instructions, /spoken, not written/);
});

test("each difficulty describes materially different behaviour", () => {
  const levels = ["calm", "defensive", "veryDefensive"].map(temperamentFor);

  // PRD §7.2: "This must not be cosmetic."
  assert.equal(new Set(levels).size, 3);
  assert.match(levels[0], /listens?|resolved/i);
  assert.match(levels[1], /push back/i);
  assert.match(levels[2], /concede almost nothing/i);
  // Resistance is not licence to be unpleasant.
  assert.match(levels[2], /Do not insult/i);
});

test("an unknown difficulty falls back rather than dropping the trait", () => {
  assert.equal(temperamentFor(undefined), temperamentFor("defensive"));
  assert.equal(temperamentFor("nonsense"), temperamentFor("defensive"));
});

test("the chosen difficulty reaches the simulation prompt", () => {
  const veryDefensive = buildRespondRequest({
    ...respondPayload,
    difficulty: "veryDefensive",
  }).input[0].content[0].text;
  const calm = buildRespondRequest({
    ...respondPayload,
    difficulty: "calm",
  }).input[0].content[0].text;

  assert.notEqual(veryDefensive, calm);
  assert.ok(veryDefensive.includes(temperamentFor("veryDefensive")));
  assert.ok(calm.includes(temperamentFor("calm")));
});

test("difficulty does not leak into the evaluation prompt", () => {
  // Scoring judges the manager, not how hard the setting was. Mixing them
  // would make an easy session score better for no reason.
  const instructions = buildEvaluateRequest(evaluatePayload).input[0]
    .content[0].text;
  assert.ok(!instructions.includes(temperamentFor("veryDefensive")));
});

test("the evaluation prompt demands exact quotes and is a separate task", () => {
  const request = buildEvaluateRequest(evaluatePayload);
  const instructions = request.input[0].content[0].text;

  assert.equal(request.text.format.name, "conversation_evaluation");
  assert.match(instructions, /EXACTLY/);
  assert.match(instructions, /Never invent, paraphrase/);
  // It reads the whole transcript once, so it gets more room than a turn.
  assert.ok(request.max_output_tokens > buildRespondRequest(respondPayload).max_output_tokens);
});

test("neither request leaks the raw session id", () => {
  for (const request of [
    buildRespondRequest(respondPayload),
    buildEvaluateRequest(evaluatePayload),
  ]) {
    assert.equal(request.store, false);
    assert.equal(request.safety_identifier.length, 64);
    assert.ok(!JSON.stringify(request).includes("local-test-session"));
  }
});

test("extracts structured output text", () => {
  const text = extractOutputText({
    output: [
      {
        type: "message",
        content: [{ type: "output_text", text: '{"reply":"ok"}' }],
      },
    ],
  });
  assert.equal(text, '{"reply":"ok"}');
});

test("a refusal is surfaced rather than parsed", () => {
  assert.throws(
    () =>
      extractOutputText({
        output: [{ type: "message", content: [{ type: "refusal" }] }],
      }),
    /could not evaluate/,
  );
});

// Truncation and an empty answer look the same from here, and telling them
// apart in the log is the whole reason the reason is carried.
test("a truncated response says why it was empty", () => {
  assert.throws(
    () =>
      extractOutputText({
        status: "incomplete",
        incomplete_details: { reason: "max_output_tokens" },
        output: [{ type: "reasoning", summary: [] }],
      }),
    /incomplete: max_output_tokens/,
  );
});

test("an empty response reports what it spent", () => {
  assert.throws(
    () =>
      extractOutputText({
        status: "incomplete",
        incomplete_details: { reason: "max_output_tokens" },
        usage: { output_tokens: 6000, output_tokens_details: { reasoning_tokens: 5952 } },
        output: [],
      }),
    /6000 output, 5952 reasoning/,
  );
});

test("returns the employee reply", async () => {
  const result = await respondWithOpenAI(respondPayload, {
    apiKey: "test-key",
    fetchImpl: respondWith({
      reply: "The scope keeps moving though.",
      emotion: "defensive",
    }),
  });

  assert.equal(result.reply, "The scope keeps moving though.");
  assert.equal(result.emotion, "defensive");
});

test("the declared resolution reaches the client", async () => {
  // PRD §9's end conditions are carried by this one field. The mapping is an
  // allowlist, so a field can be in the schema, returned by the model, and
  // still silently dropped here — which is exactly what happened.
  const result = await respondWithOpenAI(respondPayload, {
    apiKey: "test-key",
    fetchImpl: respondWith({
      reply: "Fine. I hear you.",
      emotion: "resigned",
      resolution: "resolved",
    }),
  });

  assert.equal(result.resolution, "resolved");
});

test("keeps notes that quote the transcript and drops ones that do not", () => {
  const notes = [
    { quote: "we still need to address the missed handoffs", comment: "good" },
    { quote: "I hear you and I trust you completely", comment: "invented" },
    { quote: "", comment: "empty" },
  ];

  const kept = groundNotes(notes, evaluatePayload.history);
  assert.equal(kept.length, 1);
  assert.match(kept[0].comment, /good/);
});

test("grounding ignores case, punctuation, and smart quotes", () => {
  const kept = groundNotes(
    [{ quote: "“We still need, to address the missed handoffs!”", comment: "x" }],
    evaluatePayload.history,
  );
  assert.equal(kept.length, 1);
});

test("a fabricated quote never reaches the client", async () => {
  const result = await evaluateWithOpenAI(evaluatePayload, {
    apiKey: "test-key",
    fetchImpl: respondWith({
      clarity: 68,
      empathy: 90,
      directness: 62,
      confidence: 71,
      summary: "You made room for the pressure and still named the issue.",
      strengths: [
        {
          turn_index: 0,
          quote: "I see how much you have taken on",
          comment: "Acknowledged the load first.",
          suggestion: "",
        },
      ],
      improvements: [
        {
          turn_index: 0,
          quote: "let us circle back next week",
          comment: "Never said, so this must not survive.",
          suggestion: "Name the date.",
        },
      ],
    }),
  });

  // (68 + 90 + 62 + 71) / 4 — derived here, never asked of the model.
  assert.equal(result.overall_score, 73);
  assert.equal(result.strengths.length, 1);
  assert.equal(result.improvements.length, 0);
});

test("the headline is the mean of the four dimensions", () => {
  assert.equal(
    overallFrom({ clarity: 68, empathy: 90, directness: 62, confidence: 71 }),
    73,
  );
  // The case that sent this whole thing sideways: a weak conversation scores
  // low, not zero, and never disagrees with its own breakdown.
  assert.equal(
    overallFrom({ clarity: 10, empathy: 0, directness: 25, confidence: 15 }),
    13,
  );
  assert.equal(
    overallFrom({ clarity: 0, empathy: 0, directness: 0, confidence: 0 }),
    0,
  );
  assert.equal(
    overallFrom({ clarity: 100, empathy: 100, directness: 100, confidence: 100 }),
    100,
  );
});

test("a dimension the model mangles cannot produce a wild headline", () => {
  // Out of range, missing, and not a number: clamped rather than trusted.
  assert.equal(
    overallFrom({ clarity: 140, empathy: -20, directness: undefined, confidence: "72" }),
    43,
  );
});

test("a model that still volunteers an overall score is overruled", async () => {
  const result = await evaluateWithOpenAI(evaluatePayload, {
    apiKey: "test-key",
    fetchImpl: respondWith({
      overall_score: 0,
      clarity: 80,
      empathy: 80,
      directness: 80,
      confidence: 80,
      summary: "Handled well.",
      strengths: [],
      improvements: [],
    }),
  });

  assert.equal(result.overall_score, 80);
});

test("a missing key is a configuration error, not a crash", async () => {
  await assert.rejects(
    () => evaluateWithOpenAI(evaluatePayload, { apiKey: undefined, fetchImpl: null }),
    /OPENAI_API_KEY/,
  );
});

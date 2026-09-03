import assert from "node:assert/strict";
import test from "node:test";

import {
  buildEvaluateRequest,
  buildRespondRequest,
  evaluateWithOpenAI,
  extractOutputText,
  groundNotes,
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
      overall_score: 74,
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

  assert.equal(result.overall_score, 74);
  assert.equal(result.strengths.length, 1);
  assert.equal(result.improvements.length, 0);
});

test("a missing key is a configuration error, not a crash", async () => {
  await assert.rejects(
    () => evaluateWithOpenAI(evaluatePayload, { apiKey: undefined, fetchImpl: null }),
    /OPENAI_API_KEY/,
  );
});

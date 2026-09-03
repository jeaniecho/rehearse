import assert from "node:assert/strict";
import test from "node:test";

import { buildCoachRequest, evaluateWithOpenAI, extractOutputText } from "./coach.mjs";

const payload = {
  sessionId: "local-test-session",
  scenario: {
    title: "The slipping deadline",
    context: "A teammate missed two handoffs.",
    goal: "Agree on a clear next step.",
  },
  turn: {
    employeeLine: "I have been covering two roles.",
    prompt: "How do you open?",
    isLast: false,
  },
  history: [],
  managerResponse:
    "I see how much you have taken on. We still need to address the missed handoffs.",
};

test("builds a private structured Responses API request", () => {
  const request = buildCoachRequest(payload);
  assert.equal(request.model, "gpt-5.6-sol");
  assert.equal(request.store, false);
  assert.equal(request.reasoning.effort, "low");
  assert.equal(request.text.format.type, "json_schema");
  assert.equal(request.text.format.strict, true);
  assert.equal(request.safety_identifier.length, 64);
  assert.ok(!JSON.stringify(request).includes("local-test-session"));
});

test("extracts structured output text", () => {
  const text = extractOutputText({
    output: [
      {
        type: "message",
        content: [{ type: "output_text", text: '{"score_delta":12}' }],
      },
    ],
  });
  assert.equal(text, '{"score_delta":12}');
});

test("parses a successful OpenAI evaluation", async () => {
  const evaluation = {
    score_delta: 12,
    feedback: "Clear and empathetic.",
    clarity: 2,
    empathy: 2,
    courage: 1,
    employee_reply: "Okay, what should move?",
  };
  const fetchImpl = async (_url, options) => {
    const request = JSON.parse(options.body);
    assert.equal(request.text.format.name, "conversation_evaluation");
    return {
      ok: true,
      json: async () => ({
        output: [
          {
            type: "message",
            content: [
              { type: "output_text", text: JSON.stringify(evaluation) },
            ],
          },
        ],
      }),
    };
  };

  const result = await evaluateWithOpenAI(payload, {
    apiKey: "test-key",
    fetchImpl,
  });
  assert.deepEqual(result, evaluation);
});

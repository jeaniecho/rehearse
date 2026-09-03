# Rehearse — Product Requirements Document

> Handoff document for Claude Code  
> Product: **Rehearse**  
> Platform: **Flutter mobile app**  
> Primary goal: Ship a polished RevenueCat Shipaton MVP quickly, then iterate using real usage data.

---

## 0. How Claude Code should use this document

Before making changes:

1. Inspect the current repository and read:
   - `README.md`
   - `pubspec.yaml`
   - existing architecture / feature folders
   - current routing/navigation
   - state-management choice
   - backend/API integration
   - tests
   - analytics / RevenueCat / notification integrations
2. Run the project and identify what is already working.
3. Preserve existing architectural choices unless they materially block shipping.
4. Do **not** rewrite working code simply to match this PRD.
5. Create a short implementation checklist based on:
   - what already exists
   - what is missing
   - what is broken
6. Prioritize the P0 contest loop before any P1/P2 work.

The previous implementation was developed with Codex. Assume some screens, architecture, or integrations may already exist.

---

# 1. Product summary

**Rehearse** is a practice simulator for first-time managers who need to handle difficult workplace conversations.

Instead of giving generic leadership advice, Rehearse puts the user inside a realistic conversation with an AI employee. The employee reacts dynamically to what the manager says. After the conversation, Rehearse provides structured feedback and lets the manager retry weak moments.

### One-line pitch

> Practice the difficult conversation before it matters.

### Product analogy

Rehearse should feel closer to:

> **Duolingo × flight simulator × leadership coaching**

than:

> ChatGPT with a management prompt.

The simulation, consequences, evaluation, and retry loop are the product.

---

# 2. Competition context

Rehearse is being built for the **RevenueCat Shipaton 2026**.

### Primary competition target

**Leadership / Career Coaching category**

The app directly addresses:
- difficult conversations
- giving feedback
- setting boundaries
- saying no
- handling conflict
- managing performance
- building confidence through practice

### Secondary targets

Where implementation quality supports them:

- RevenueCat Design
- HAMM / monetization
- OneSignal retention
- Growth / experimentation
- #BuildInPublic

Do not add features purely to check competition boxes. Every integration should improve the core product.

---

# 3. Target user

## Primary persona

**First-time manager**

Typical profile:
- recently promoted from individual contributor
- technically competent but inexperienced with difficult people situations
- knows what they *should* do in theory
- struggles with wording, confidence, emotional reactions, and boundaries
- has an upcoming real conversation they are anxious about

Typical thought:

> “I know I need to talk to them. I just don’t know how to say it without making things worse.”

## Secondary future personas

Not MVP:

- tech leads
- founders
- sales managers
- HR professionals
- interview candidates
- customer-facing teams

The Shipaton version should stay focused on managers.

---

# 4. Core problem

Leadership advice is easy to read but hard to apply under pressure.

A manager may understand concepts like:
- be direct
- show empathy
- explain expectations
- avoid blame

…but still fail when the employee becomes:
- defensive
- emotional
- dismissive
- argumentative
- avoidant

Rehearse solves the gap between **knowing** and **performing**.

---

# 5. Product principles

## 5.1 Practice, not advice

Users should spend most of their time *responding*, not reading.

## 5.2 Realistic resistance

The AI should not be overly cooperative.

Different personalities should materially change the interaction.

## 5.3 Consequences

Weak communication should create believable consequences:
- ambiguity
- defensiveness
- loss of trust
- unresolved expectations
- escalation

Good communication should move the conversation toward resolution.

## 5.4 Specific feedback

Avoid generic feedback like:

> “You could improve your communication.”

Prefer:

> You said: “Maybe we can communicate more next time.”

> This leaves the expectation unclear. Try: “If a deadline is at risk, I need you to tell me as soon as you know.”

## 5.5 Retry is essential

Feedback alone is not enough.

The learning loop is:

```text
TRY
↓
FAIL / STRUGGLE
↓
UNDERSTAND
↓
RETRY
↓
IMPROVE
```

---

# 6. MVP scope

The minimum viable Shipaton product must support this complete loop:

```text
Choose scenario
→ choose employee difficulty/personality
→ complete a short AI conversation
→ receive structured feedback
→ retry the conversation
→ encounter a contextual monetization moment
```

If this loop is excellent, the MVP is successful.

---

# 7. P0 functional requirements

## 7.1 Scenario library

The home screen presents curated scenarios.

Initial scenario categories:

1. Give difficult feedback
2. Address poor performance
3. Set a boundary
4. Say no to a request
5. Handle conflict
6. Delegate clearly

Ship roughly **6–12 curated scenarios**.

Each scenario should contain:

```dart
Scenario {
  id
  category
  title
  summary
  context
  employeeName
  employeeRole
  employeeBackground
  managerGoal
  hiddenSuccessCriteria
  openingLine
  recommendedDuration
}
```

Example:

```text
Title:
Missed Deadlines

Context:
Alex is a strong engineer but has missed three important deadlines.

Goal:
Address the missed deadlines and establish a clear expectation for early risk communication.

Employee:
Alex Chen
Senior Engineer
```

Curated scenarios are preferred over AI-generated scenarios for MVP quality.

---

## 7.2 Difficulty / employee personality

Before the simulation starts, the user selects how challenging the employee should be.

MVP options:

- Calm
- Defensive
- Very Defensive

If current code already supports a richer personality system, keep it.

Possible internal personality dimensions:

```text
defensiveness
emotionality
openness
avoidance
aggression
```

The selected personality must affect:
- wording
- willingness to accept feedback
- likelihood of challenging the manager
- emotional escalation
- ease of reaching resolution

This must not be cosmetic.

---

## 7.3 Conversation simulation

The conversation is text-based for MVP.

### Requirements

- AI plays the employee, not the coach.
- User always plays the manager.
- AI stays in character.
- AI should not explain the simulation while it is happening.
- AI should not provide advice unless explicitly part of the scenario.
- Conversation should last roughly 4–7 manager turns.
- The AI can determine that the conversation is resolved or stalled.
- The app must also enforce a hard maximum turn count.

### Suggested response contract

```json
{
  "response": "Honestly, I think that's unfair. Nobody told me these deadlines were a problem until now.",
  "emotion": "defensive",
  "state": {
    "trust": 58,
    "clarity": 42,
    "tension": 72
  },
  "conversation_should_end": false,
  "end_reason": null
}
```

The exact schema can be adapted to existing code.

### Important

The UI, not the LLM, owns:
- navigation
- timers
- message history rendering
- session limits
- subscription state
- retry behavior
- analytics
- local persistence

Do not let the LLM determine application flow arbitrarily.

---

# 8. Simulation state

The product should maintain hidden or semi-hidden conversation state.

Suggested values:

```text
trust
tension
clarity
goal_progress
employee_openness
```

Not all of these need to be shown live.

### Why state exists

It gives the simulation continuity.

For example:

- vague statements reduce clarity
- blaming increases tension
- acknowledging concerns can increase trust
- direct expectations improve goal progress
- excessive softening may improve trust but fail the manager goal

This can be:
- LLM-generated structured values
- server-calculated
- hybrid

For MVP, structured LLM output is acceptable if reliable.

---

# 9. Conversation completion

A session ends when:

1. manager reaches the scenario goal
2. employee accepts or understands the expectation
3. conversation breaks down
4. maximum turn count is reached

The product should not require perfect resolution.

Difficult conversations can end with:
- success
- partial success
- unresolved
- escalated

These outcomes make the simulation feel credible.

---

# 10. Evaluation system

Evaluation is the most important product feature after the simulation itself.

Score only four dimensions in MVP:

### Clarity
Did the manager communicate the issue and expectation clearly?

### Empathy
Did the manager acknowledge the employee's perspective without avoiding the issue?

### Directness
Did the manager address the actual problem rather than soften, dodge, or over-explain?

### Confidence
Did the manager communicate with conviction and maintain appropriate boundaries?

Use scores from 0–100.

### Suggested evaluation response

```json
{
  "overall_score": 74,
  "outcome": "partial_success",
  "scores": {
    "clarity": 68,
    "empathy": 91,
    "directness": 62,
    "confidence": 76
  },
  "summary": "You created psychological safety but left the future expectation too vague.",
  "strengths": [
    {
      "title": "Acknowledged their perspective",
      "explanation": "You validated the workload concern before discussing accountability."
    }
  ],
  "improvements": [
    {
      "message_id": "user-message-3",
      "quote": "Maybe we can communicate more next time.",
      "issue": "The expectation is unclear.",
      "suggestion": "If a deadline is at risk, I need you to tell me as soon as you know."
    }
  ],
  "best_moment_message_id": "user-message-2",
  "retry_message_id": "user-message-3"
}
```

Use structured JSON validated server-side where possible.

---

# 11. Feedback screen

The results screen should feel like the payoff of the product.

Required:

- overall score
- four dimension scores
- session outcome
- 1–3 strengths
- 1–3 improvements
- quoted user wording
- explanation of why wording was weak
- example improved wording
- “Practice again” CTA

### High-value interaction

Where feasible:

**Practice this moment again**

The app identifies one weak response and lets the user retry.

True branching rewind is P1 if it is expensive.

For P0, acceptable fallback:

- show the weak moment
- start a new simulation with the same scenario
- coach the user to focus on that skill

Do not delay launch to implement a complex conversation tree.

---

# 12. Replay

## P0 version

Feedback references exact user messages and scrolls/highlights them.

## P1 version

Interactive session replay:
- conversation timeline
- highlighted weak moments
- highlighted strong moments
- retry from specific moment

Replay is more valuable than generic history.

---

# 13. Monetization

Use RevenueCat.

## Suggested free tier

Default MVP:

**3 free completed simulations total**

Alternative if already implemented:

**3 simulations per week**

Prefer the lifetime limit initially because it creates:
- simple onboarding
- simple entitlement logic
- clear funnel
- faster paywall exposure during testing

## Pro

Possible entitlement:

`pro`

Pro unlocks:

- unlimited simulations
- all scenarios
- advanced feedback
- higher difficulty
- future custom scenarios
- full replay/history

Do not artificially lock basic product quality.

Free users should experience enough value to understand why Pro matters.

---

# 14. Paywall behavior

The best paywall is contextual.

Preferred moment:

After the user completes enough simulations to understand the value.

Example:

```text
You tend to soften expectations when the employee pushes back.

Unlock unlimited practice and targeted coaching.
```

Then show RevenueCat paywall.

Avoid forcing a paywall before the first meaningful simulation.

### Initial pricing hypothesis

Do not hard-code these assumptions into architecture.

Possible test:

- Monthly: ~$7–10
- Annual: ~$40–50
- Optional 7-day trial

RevenueCat should remain the source of truth for packages and pricing.

---

# 15. OneSignal / notification concept

Notifications must provide user value.

MVP notification use case:

> “Do you have a difficult conversation coming up?”

User schedules an upcoming conversation.

Example:

```text
Performance conversation
Tomorrow at 10:00 AM
```

Reminder:

> Your conversation is tomorrow. Run one 5-minute rehearsal before you go in.

P0 if easy with existing architecture.

Otherwise P1 after the core app is submitted.

Do not build a generic notification engagement system.

---

# 16. Analytics

Use the project’s existing analytics solution if present.

Minimum events:

```text
app_opened

onboarding_started
onboarding_completed

scenario_viewed
scenario_started
difficulty_selected

simulation_started
simulation_message_sent
simulation_completed
simulation_abandoned

evaluation_requested
evaluation_viewed

retry_started
retry_completed

paywall_viewed
paywall_dismissed
trial_started
purchase_completed
restore_completed

reminder_created
notification_opened
```

Useful properties:

```text
scenario_id
scenario_category
difficulty
turn_count
simulation_duration_seconds
outcome
overall_score
is_pro
free_sessions_remaining
paywall_id
package_id
```

Do not send raw conversation contents to analytics.

---

# 17. Primary funnel

Track:

```text
install / first open
↓
onboarding complete
↓
scenario started
↓
simulation completed
↓
evaluation viewed
↓
second simulation started
↓
paywall viewed
↓
trial / purchase
```

The key activation metric should probably be:

> **First simulation completed**

Secondary activation:

> **User starts a second simulation**

That indicates the practice loop is compelling.

---

# 18. Onboarding

Keep onboarding very short.

Potential 2–3 screen sequence:

### Screen 1

**Practice the conversation before it matters.**

Rehearse difficult workplace conversations with realistic AI employees.

### Screen 2

**They won't always agree with you.**

Practice with different levels of resistance and defensiveness.

### Screen 3

**See exactly what to improve.**

Get feedback on clarity, empathy, directness, and confidence.

CTA:

**Start practicing**

Avoid questionnaires unless they directly personalize the first scenario.

---

# 19. Home screen

The home screen should optimize for starting practice.

Recommended hierarchy:

```text
Greeting / positioning

Continue / recommended scenario

Practice scenarios
- Difficult feedback
- Poor performance
- Boundaries
- Saying no
- Conflict
- Delegation
```

Avoid dashboards filled with metrics before users have enough sessions.

---

# 20. Visual / UX direction

The product should feel:
- calm
- premium
- focused
- slightly tense during simulation
- reassuring but not childish

Avoid generic chatbot styling where possible.

Potential visual ideas:
- employee profile card
- role / context card
- subtle emotional state transitions
- haptics when tension shifts
- polished score reveal
- animated feedback cards
- strong typography
- restrained motion

The simulation should be visually distinct from normal messaging apps.

---

# 21. AI architecture

Recommended boundary:

```text
Flutter
↓
Server / serverless endpoint
↓
LLM provider
```

Never ship provider API secrets in the client.

Suggested endpoints:

```text
POST /simulation/respond
POST /simulation/evaluate
```

If the existing backend has a different API shape, keep it if clean.

---

# 22. AI prompt responsibilities

## Simulation prompt should define

- scenario context
- employee identity
- employee personality
- hidden employee motivations
- manager objective
- current conversation state
- conversation history
- response constraints
- structured JSON schema
- rules against coaching the user

## Evaluation prompt should define

- scenario goal
- full transcript
- rubric
- scoring meaning
- quote-based critique requirement
- output schema

Keep simulation and evaluation as separate model tasks.

Do not use one giant prompt for everything.

---

# 23. Prompt quality requirements

Simulation must avoid:
- instantly agreeing
- repeating itself
- giving leadership advice
- acknowledging being AI
- breaking character
- unrealistic hostility
- extremely long messages

Employee messages should usually be concise:
- 1–4 sentences
- conversational
- emotionally believable

Evaluation must avoid:
- generic filler
- praise without evidence
- invented user quotes
- overly long essays
- contradictory scores

Every critique should reference actual behavior from the transcript.

---

# 24. Data model suggestions

Adapt these to existing architecture.

```dart
class Scenario {
  final String id;
  final ScenarioCategory category;
  final String title;
  final String summary;
  final String context;
  final EmployeeProfile employee;
  final String managerGoal;
  final List<String> successCriteria;
  final String openingLine;
}
```

```dart
class EmployeeProfile {
  final String name;
  final String role;
  final String background;
}
```

```dart
enum SimulationDifficulty {
  calm,
  defensive,
  veryDefensive,
}
```

```dart
class SimulationSession {
  final String id;
  final Scenario scenario;
  final SimulationDifficulty difficulty;
  final List<ConversationMessage> messages;
  final SimulationStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
}
```

```dart
class Evaluation {
  final int overallScore;
  final EvaluationScores scores;
  final SimulationOutcome outcome;
  final String summary;
  final List<FeedbackItem> strengths;
  final List<FeedbackItem> improvements;
}
```

---

# 25. Local persistence

Do not build accounts unless already present and stable.

MVP can persist locally:

- onboarding completed
- free sessions used
- recent sessions
- notification preference
- anonymous user ID

RevenueCat entitlement state remains external.

If backend authentication already exists, do not remove it merely for MVP simplicity.

---

# 26. Error states

Required graceful handling:

## LLM request fails

Show:

> Couldn't continue the simulation. Try again.

Preserve transcript.

Retry should not duplicate the user's message.

## Evaluation fails

The completed transcript must remain available.

Offer:

> Retry feedback

Do not force the user to replay the entire conversation.

## No network

Communicate clearly that simulations require internet.

## Invalid structured output

Backend should:
- validate
- repair/retry once if practical
- return controlled error

Do not crash UI parsing malformed model output.

## Subscription unavailable

Allow core free experience to continue.

---

# 27. Safety / content boundaries

This is a coaching simulator, not:
- HR legal advice
- mental health treatment
- employment law guidance
- disciplinary decision-making software

The app can simulate management conversations but should not present its feedback as authoritative HR/legal guidance.

Avoid generating discriminatory or retaliatory management recommendations.

---

# 28. Performance requirements

For a polished demo:

- chat send should immediately render local user message
- show typing / response state
- stream response if already supported
- otherwise target short perceived latency
- avoid blocking full-screen spinners
- feedback generation should have an intentional transition/loading state

The app should feel responsive even when AI calls take time.

---

# 29. Non-goals for contest MVP

Explicitly out of scope unless already implemented:

- voice conversation
- realtime speech
- custom scenario generation
- team accounts
- manager dashboard
- manager reports
- enterprise features
- social network
- friend challenges
- courses
- extensive gamification
- XP / levels / badges
- hundreds of scenarios
- web app
- multiple LLM providers exposed to user
- elaborate backend
- complex authentication
- AI avatars
- multiplayer roleplay

Do not add these before the P0 loop is polished.

---

# 30. P1 features

Only after P0 is stable:

- custom user scenario
- session history
- “practice this moment again”
- upcoming-conversation reminders
- richer personalities
- personalized recommended scenarios
- simple progress trends
- improved RevenueCat paywall experiments
- better first-session personalization

---

# 31. P2 / post-Shipaton

Potential product expansion:

- voice simulation
- personalized learning paths
- promotion conversations
- firing / termination practice
- salary conversations
- stakeholder communication
- negotiation
- sales roleplay
- interview practice
- team licenses
- manager coaching programs
- organization-specific scenarios

These are product opportunities, not current requirements.

---

# 32. App Store positioning

## Name

**Rehearse**

## Primary tagline

> Practice difficult conversations before they happen.

Alternative:

> The flight simulator for difficult conversations.

## Screenshot narrative

1. **The hard conversation is tomorrow.**  
   Practice it today.

2. **They won’t always agree with you.**  
   Practice realistic resistance.

3. **See exactly where you lost the conversation.**  
   Get specific feedback.

4. **Try again until it feels natural.**  
   Build confidence through repetition.

---

# 33. Demo-worthy scenario

The submission/demo should feature one strong scenario.

Recommended:

## Missed deadlines

Employee:
**Alex Chen — Senior Engineer**

Context:
Alex is talented but has missed three important deadlines.

Personality:
Defensive.

Opening:

> “Honestly, I’m surprised we’re having this conversation. The deadlines weren’t realistic to begin with.”

Ideal demo arc:

1. user gives vague feedback
2. Alex pushes back
3. user attempts recovery
4. session ends
5. feedback shows exact vague wording
6. Rehearse suggests stronger wording
7. retry CTA appears

This communicates the product in seconds.

---

# 34. Acceptance criteria — P0

The contest MVP is complete when all of the following work on a real device:

### Product loop

- [ ] User can complete onboarding.
- [ ] User can browse curated scenarios.
- [ ] User can select a scenario.
- [ ] User can select difficulty.
- [ ] User can start a simulation.
- [ ] AI remains in character.
- [ ] User can complete a full session.
- [ ] Session has a deterministic end condition.
- [ ] Evaluation is generated.
- [ ] Evaluation contains the four required scores.
- [ ] Feedback references actual user wording.
- [ ] User can retry the scenario.

### Reliability

- [ ] AI/API errors are handled without losing the transcript.
- [ ] Malformed AI responses do not crash the app.
- [ ] Loading states are intentional.
- [ ] Keyboard/chat UX works correctly.
- [ ] App survives background/foreground during a simulation reasonably.

### Monetization

- [ ] RevenueCat initializes correctly.
- [ ] Free session limit works.
- [ ] Paywall can be displayed.
- [ ] Purchase works in sandbox.
- [ ] Restore works.
- [ ] Pro entitlement unlocks the expected behavior.

### Analytics

- [ ] Core funnel events fire.
- [ ] No raw sensitive transcript is sent to analytics.

### Release

- [ ] Production backend keys are secure.
- [ ] Privacy policy exists.
- [ ] Store metadata is ready.
- [ ] TestFlight / equivalent release build works.
- [ ] Crash monitoring is enabled if available.

---

# 35. Definition of product quality

The MVP should trigger two reactions:

### During simulation

> “This actually feels uncomfortable.”

The employee pushes back realistically enough that the user has to think.

### During feedback

> “That’s actually useful.”

The critique must be specific enough that the user can immediately try a better response.

If those two moments work, prioritize polish over feature expansion.

---

# 36. Claude Code implementation guidance

When resuming this repository:

### First

Report:

```text
CURRENT STATE
- Existing architecture:
- State management:
- Navigation:
- Implemented screens:
- AI integration:
- RevenueCat:
- Analytics:
- Notifications:
- Tests:
- Known TODOs:
```

Then create:

```text
NEXT P0 TASKS
1.
2.
3.
...
```

### Coding priorities

1. preserve working code
2. complete vertical slice
3. remove blockers
4. improve reliability
5. add monetization
6. instrument funnel
7. polish
8. only then add P1 features

### Avoid

- broad refactors
- changing state-management libraries mid-project
- premature abstraction
- replacing packages without clear benefit
- speculative architecture
- implementing P2 features
- turning this into a generic AI chat app

The deadline rewards shipping.

---

# 37. Final MVP definition

Rehearse v1 is:

> A first-time manager chooses a difficult workplace scenario, practices a short realistic conversation with an AI employee who can resist and react, receives specific structured feedback on clarity, empathy, directness, and confidence, and immediately gets another chance to improve.

Everything should serve that loop.

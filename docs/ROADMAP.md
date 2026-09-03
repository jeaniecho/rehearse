# Rehearse — Shipaton Roadmap

> Execution roadmap for Claude Code / project continuation.  
> Optimize for a polished contest MVP first, then use remaining Shipaton time for user feedback, monetization experiments, growth, and submission quality.

---

> **This file is the plan of record. It is not updated to match the code.**
>
> The live checklist asked for in §3 lives in **[`STATUS.md`](STATUS.md)** —
> what is complete, partial, missing, and next. Read that first; come back here
> for the reasoning and the milestone shape.
>
> As of the last audit: the practice loop is complete and polished, and
> **M4 (RevenueCat + analytics) has not been started.** Day 0 below is closed;
> everything from Day 4 on is open.

---

# 0. Operating rules

1. Inspect the existing repository before implementing tasks.
2. Mark existing work as complete rather than rebuilding it.
3. P0 wins over P1.
4. Working vertical slices win over architectural perfection.
5. Do not introduce major new infrastructure unless a P0 requirement needs it.
6. The core loop must be stable before secondary competition integrations.
7. Every day should end with a runnable app.

---

# 1. Priority system

## P0 — Must ship

Without these, Rehearse is not a complete product:

- curated scenarios
- difficulty selection
- AI employee simulation
- deterministic session end
- structured evaluation
- retry flow
- polished core UX
- RevenueCat monetization
- core analytics
- production release build
- store submission

## P1 — Strong competition value

Do after P0 is stable:

- session replay
- retry weak moment
- upcoming conversation reminder / OneSignal
- improved paywall experiment
- session history
- simple progress
- richer animation/polish

## P2 — Post-contest / only if everything else is done

- voice
- custom scenarios
- complex progress system
- learning paths
- accounts / teams
- enterprise
- social features
- broad scenario library

---

# 2. Milestone overview

```text
M0 — Audit existing repo
M1 — Complete fake/local vertical slice
M2 — Real AI simulation
M3 — Evaluation + retry
M4 — Monetization + analytics
M5 — Polish + reliability
M6 — Release + store submission
M7 — Launch + user learning
M8 — Growth / monetization experiments
M9 — Shipaton submission package
```

---

# 3. Day 0 — Resume / repo audit

## Goal

Understand exactly where Codex stopped.

## Tasks

- [x] Run `flutter pub get`.
- [x] Run static analysis. — clean
- [x] Run tests. — 106 Flutter, 3 server, all passing
- [x] Launch app. — release web build, served and inspected. **Not yet run on a
      physical device or simulator.**
- [x] Read README and project docs.
- [x] Map project structure. — see [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [x] Identify state-management library. — none; `StatefulWidget` +
      `ChangeNotifier` through `InheritedNotifier`
- [x] Identify routing/navigation. — imperative `Navigator.push`, no named routes
- [x] Identify backend/API approach. — Node http proxy in `server/`, OpenAI
      Responses API, `POST /evaluate`
- [x] Identify existing AI implementation. — one combined simulation +
      evaluation prompt, with an offline fallback coach
- [x] Identify RevenueCat status. — **absent**
- [x] Identify analytics status. — **absent**
- [x] Identify notification status. — **absent**
- [x] Search `TODO`, `FIXME`, commented stubs. — none found
- [x] Check git status and recent commits.
- [x] List current blockers. — see [`STATUS.md`](STATUS.md) §2

## Deliverable

Add/update a local implementation checklist.

**Done — see [`STATUS.md`](STATUS.md) §2**, which carries this exact shape
(already complete / partially complete / missing / broken) against the real
repository.

Do not refactor yet.

---

# 4. Day 1 — End-to-end product skeleton

## Goal

A user can walk through the entire product using local/mock data.

If Codex already completed part of this, skip completed tasks.

## P0

- [ ] Establish/confirm theme tokens.
- [ ] Onboarding.
- [ ] Scenario library screen.
- [ ] Scenario details/setup.
- [ ] Difficulty selection.
- [ ] Conversation UI.
- [ ] Fake conversation state.
- [ ] Evaluation/results UI.
- [ ] Retry CTA.
- [ ] Basic free-session UX.
- [ ] Navigation through complete loop.

## Scenario seed content

Create approximately:

- [ ] 2 difficult feedback scenarios
- [ ] 2 performance scenarios
- [ ] 1 boundary scenario
- [ ] 1 saying-no scenario
- [ ] 1 conflict scenario
- [ ] 1 delegation scenario

Target: 8 scenarios.

## End-of-day definition

You should be able to screen-record:

```text
home
→ scenario
→ difficulty
→ fake simulation
→ feedback
→ retry
```

Do not integrate extra features until this exists.

---

# 5. Day 2 — Real AI simulation

## Goal

Replace fake employee responses with reliable real AI behavior.

## P0 backend

- [ ] Secure LLM key server-side.
- [ ] Implement/confirm `/simulation/respond`.
- [ ] Define structured response schema.
- [ ] Validate model JSON.
- [ ] Add controlled retry/repair for malformed output.
- [ ] Add server errors with useful client messages.

## P0 simulation prompt

Prompt should contain:

- [ ] employee identity
- [ ] employee background
- [ ] scenario context
- [ ] manager goal
- [ ] selected difficulty/personality
- [ ] hidden behavior constraints
- [ ] current state
- [ ] transcript
- [ ] explicit “stay in character”
- [ ] explicit “do not coach”
- [ ] response length rules
- [ ] structured schema

## P0 client

- [ ] Optimistic rendering of user message.
- [ ] Typing/loading state.
- [ ] AI response rendering.
- [ ] Prevent duplicate sends.
- [ ] Preserve transcript on error.
- [ ] Hard max turn count.
- [ ] Conversation end state.

## Prompt test matrix

Manually test:

- [ ] excellent manager response
- [ ] vague manager response
- [ ] hostile manager response
- [ ] employee receives blame
- [ ] manager apologizes excessively
- [ ] manager goes off-topic
- [ ] empty/very short message
- [ ] very long message
- [ ] repeated user message

## Quality bar

Employee should:
- resist naturally
- stay concise
- not become a coach
- not instantly agree
- not become absurdly hostile
- react to previous turns

---

# 6. Day 3 — Evaluation and learning loop

## Goal

Make the post-session feedback feel substantially more useful than ChatGPT.

## P0 backend

- [ ] Implement/confirm `/simulation/evaluate`.
- [ ] Separate evaluation prompt from simulation prompt.
- [ ] Define evaluation JSON schema.
- [ ] Validate exact transcript quotes.
- [ ] Handle malformed output.

## Required scores

- [ ] clarity
- [ ] empathy
- [ ] directness
- [ ] confidence
- [ ] overall

## Required feedback

- [ ] session outcome
- [ ] concise summary
- [ ] 1–3 specific strengths
- [ ] 1–3 specific improvements
- [ ] exact user quote
- [ ] explanation
- [ ] suggested stronger wording

## P0 UI

- [ ] polished score reveal
- [ ] dimension cards/bars
- [ ] strength section
- [ ] improvement section
- [ ] quote comparison
- [ ] practice again

## P1, only if cheap

- [ ] highlight weak message in transcript
- [ ] “practice this moment again”

Do not build true rewind if it threatens schedule.

## Quality test

Run the same scenario with:
1. intentionally poor conversation
2. mediocre conversation
3. strong conversation

Scores and feedback must meaningfully differ.

---

# 7. Day 4 — RevenueCat + analytics

## Goal

Turn the product into an instrumented subscription app.

---

## RevenueCat P0

- [ ] Configure project.
- [ ] Add SDK.
- [ ] Configure `pro` entitlement.
- [ ] Configure products/packages.
- [ ] Fetch offerings dynamically.
- [ ] Implement paywall.
- [ ] Purchase flow.
- [ ] Restore flow.
- [ ] Entitlement refresh.
- [ ] Handle cancelled purchase.
- [ ] Handle unavailable offerings.
- [ ] Test sandbox purchase.

## Suggested free model

Start with:

**3 completed simulations free**

Then Pro.

If a different free model is already implemented and working, preserve it unless data suggests otherwise.

## Contextual paywall

Preferred:

```text
You've completed your free practice sessions.

You tend to soften expectations when employees push back.

Keep practicing with unlimited simulations and deeper feedback.
```

Do not show the first paywall before the user understands the product.

---

## Analytics P0

Instrument:

- [ ] onboarding_started
- [ ] onboarding_completed
- [ ] scenario_viewed
- [ ] scenario_started
- [ ] difficulty_selected
- [ ] simulation_started
- [ ] simulation_message_sent
- [ ] simulation_completed
- [ ] simulation_abandoned
- [ ] evaluation_viewed
- [ ] retry_started
- [ ] paywall_viewed
- [ ] paywall_dismissed
- [ ] trial_started
- [ ] purchase_completed
- [ ] restore_completed

Properties:

- scenario ID
- category
- difficulty
- number of turns
- duration
- score
- outcome
- subscription state

Never send raw transcript content into analytics.

---

# 8. Day 5 — Product polish and reliability

## Goal

No major feature development.

Make the core loop feel premium.

## UX P0

- [ ] chat keyboard behavior
- [ ] auto-scroll
- [ ] safe areas
- [ ] text overflow
- [ ] disabled send states
- [ ] loading transitions
- [ ] empty states
- [ ] haptics
- [ ] transitions
- [ ] score reveal
- [ ] error toasts/cards
- [ ] retry behavior
- [ ] app background/foreground

## Visual review

Test every P0 screen at:
- [ ] small phone
- [ ] normal phone
- [ ] large phone
- [ ] Android
- [ ] iOS

Where practical.

## Reliability P0

- [ ] API timeout
- [ ] server 500
- [ ] no connection
- [ ] malformed AI output
- [ ] evaluation failure
- [ ] RevenueCat failure
- [ ] cancelled payment
- [ ] app killed during simulation
- [ ] duplicate tap/send

## Tests

Prioritize high-value tests:

- [ ] evaluation parsing
- [ ] simulation parsing
- [ ] entitlement logic
- [ ] session-limit logic
- [ ] important state transitions

Don't chase arbitrary coverage.

---

# 9. Day 6 — Notifications + release preparation

## Goal

Prepare submission-quality builds and secondary competition integration.

## P1 OneSignal

If core P0 is stable:

- [ ] Add/configure OneSignal.
- [ ] User can schedule an upcoming conversation.
- [ ] Store reminder metadata.
- [ ] Send or schedule useful rehearsal reminder.
- [ ] Track notification opened.

Example:

> Your performance conversation is tomorrow. Run one 5-minute rehearsal before you go in.

If notification integration becomes a blocker, stop and prioritize store release.

---

## Store/release P0

- [ ] production app ID/package
- [ ] icon
- [ ] launch screen
- [ ] version/build number
- [ ] signing
- [ ] production environment config
- [ ] privacy policy
- [ ] subscription metadata
- [ ] App Store privacy answers
- [ ] Google Play data-safety answers if shipping Android
- [ ] store screenshots
- [ ] description
- [ ] support URL
- [ ] test purchase setup
- [ ] crash reporting

## QA

Perform one clean install flow from scratch.

Record issues.

Fix only blockers and high-impact polish.

---

# 10. Day 7 — Submit and launch

## Goal

Stop feature development.

## P0

- [ ] final smoke test
- [ ] production backend check
- [ ] production RevenueCat check
- [ ] submit iOS
- [ ] submit Android if included
- [ ] create TestFlight/external test build
- [ ] verify analytics events in production/test environment
- [ ] record first usable demo footage

## Launch content

Create one short product demo:

```text
Scenario:
Missed deadlines

Difficulty:
Defensive

Employee:
"Honestly, I think this is unfair..."

User responds poorly.

Employee pushes back.

Feedback:
"You softened the expectation."

Suggested response appears.

Retry.
```

This should make the app understandable with audio muted.

---

# 11. Week 2 — User learning

After submission, stop guessing.

## Target users

Find:
- first-time engineering managers
- tech leads
- founders
- small-team managers

## Goal

Get the first 20–50 meaningful users/testers.

Quality matters more than raw volume initially.

## Interview question

Ask:

> What difficult conversation are you currently avoiding?

Capture themes.

Do not ask users to design features.

---

## Metrics to inspect

- onboarding completion
- scenario start rate
- simulation completion
- evaluation view
- second simulation rate
- paywall view rate
- trial/purchase rate
- average session length
- scenario popularity
- drop-off turn

---

## Product iteration P1

Based on data:

- [ ] improve weak onboarding
- [ ] fix highest simulation drop-off
- [ ] improve poor scenario
- [ ] improve AI resistance
- [ ] improve evaluation specificity
- [ ] add most-requested scenario
- [ ] improve paywall messaging

One change at a time where measurement matters.

---

# 12. Week 3 — Monetization and growth experiments

## RevenueCat experiment candidates

### Experiment A — Paywall message

A:
> Unlimited leadership practice.

B:
> Be ready for the conversation tomorrow.

Measure:
- paywall → trial/purchase

### Experiment B — Packaging

Example only:

A:
- monthly + annual

B:
- annual emphasized + trial

Use RevenueCat offerings rather than code changes where possible.

### Experiment C — Free limit

Potential:
- 2 free sessions
- 3 free sessions

Only test after enough users exist to make results interpretable.

---

# 13. Retention experiment

Implement one useful return trigger.

Best option:

**Upcoming conversation reminder**

Flow:

```text
After session
→ "When is the real conversation?"
→ select date/time
→ rehearsal reminder
```

This directly connects notification behavior to user intent.

Potential event:

```text
reminder_created
notification_opened
simulation_started_from_notification
```

---

# 14. Build-in-public roadmap

Create content from actual development/product decisions.

Potential posts:

### Build day

> I'm building a simulator that makes first-time managers practice difficult conversations instead of reading generic advice.

### AI behavior

> The hardest part wasn't generating dialogue. It was making the employee push back without becoming unrealistic.

### Product insight

> A manager can sound empathetic and still fail because they never state the expectation.

### Demo

> I intentionally gave terrible feedback to a defensive AI employee. Here's where the conversation broke down.

### Growth experiment

> We changed the paywall after users kept completing one session but not understanding why they should subscribe.

Prefer concrete lessons/screens over generic “day N building my app” posts.

---

# 15. Viral-content test

Rehearse has a potentially repeatable demo format.

Examples:

- “Can I survive a performance review with an extremely defensive employee?”
- “I tried firing the world's most argumentative AI employee.”
- “I gave terrible manager feedback on purpose.”
- “The same feedback with a calm vs defensive employee.”

If one format gets traction, repeat the format with different scenarios.

---

# 16. P1 scenario expansion

Add based on real demand.

Candidates:

- missed deadlines
- underperformance
- recurring lateness
- promotion denied
- compensation disappointment
- employee wants scope they aren't ready for
- boundary around after-hours messages
- saying no to unrealistic request
- team conflict
- giving critical feedback to a high performer
- delegating instead of taking work back
- employee blaming another teammate

Avoid large quantity.

Ten excellent scenarios beat fifty generic scenarios.

---

# 17. Replay / retry milestone

Once the base loop is stable, prioritize:

```text
SESSION REPLAY
↓
weak moment highlighted
↓
why it failed
↓
better wording
↓
retry
```

## Simple implementation

P1-A:

- evaluation returns `retry_message_id`
- result screen highlights that message
- “Practice again” starts the same scenario

## Advanced implementation

P1-B:

- restore conversation snapshot before weak message
- regenerate employee state
- user retries from that exact turn

Only implement advanced branching if stability remains high.

---

# 18. Shipaton submission preparation

Do not wait until the final day.

## Submission narrative

The story should be:

### Problem

New managers know difficult conversations matter but often avoid them because reading advice doesn't prepare them for pushback.

### Solution

Rehearse gives them a realistic AI employee to practice with.

### Differentiation

The AI does not coach during the conversation.

It resists.

Choices have consequences.

Then Rehearse identifies the exact moments where communication became vague, indirect, or unproductive.

### Learning loop

Practice → feedback → retry.

### Business

Subscription-based repeated practice with contextual monetization.

### Retention

Users can rehearse before a scheduled real conversation.

### Iteration

Show actual usage/experiment learnings gathered after launch.

---

# 19. Two-minute demo outline

Target approximately:

## 0:00–0:10

Problem + pitch.

> Difficult conversations are hard because the other person doesn't follow your script.

## 0:10–0:25

Choose:

> Missed deadlines → Defensive employee.

## 0:25–0:55

Show 2–3 conversation turns.

Make one intentionally imperfect response.

## 0:55–1:20

Show employee reaction and finish session.

## 1:20–1:45

Show structured evaluation:
- scores
- quote
- critique
- better wording

## 1:45–1:55

Show retry / reminder / Pro briefly.

## 1:55–2:00

Close:

> Practice the conversation before it matters.

Keep the product on screen almost the entire time.

---

# 20. Final contest QA checklist

## Core

- [ ] first run works
- [ ] scenario starts
- [ ] AI responds
- [ ] AI remains in character
- [ ] session ends
- [ ] feedback generates
- [ ] retry works

## Design

- [ ] no broken layouts
- [ ] no obvious debug UI
- [ ] loading looks intentional
- [ ] polished transitions
- [ ] screenshots look coherent

## RevenueCat

- [ ] offerings load
- [ ] paywall works
- [ ] purchase tested
- [ ] restore tested
- [ ] entitlement unlock tested

## Analytics

- [ ] key events visible
- [ ] event properties useful

## Notification

- [ ] reminder useful
- [ ] deep link / open behavior correct

## Release

- [ ] production API
- [ ] no secrets in client
- [ ] privacy policy
- [ ] store build
- [ ] stable demo account/state if required

## Submission

- [ ] description
- [ ] screenshots
- [ ] two-minute video
- [ ] competition integrations named clearly
- [ ] build-in-public links
- [ ] experiment/growth results summarized

---

# 21. Definition of done — 7-day MVP

The MVP is done when a brand-new user can:

1. install Rehearse
2. understand the value in under 30 seconds
3. choose a relevant management scenario
4. select employee difficulty
5. complete a realistic 3–5 minute simulation
6. receive specific useful feedback
7. understand what they should say differently
8. immediately practice again
9. encounter a reasonable Pro upgrade path

…and the entire experience is reliable enough to record without staging around bugs.

---

# 22. Definition of done — Shipaton submission

The project is done for Shipaton when:

- production app is submitted/released
- core simulation is polished
- RevenueCat is real, not decorative
- analytics capture the funnel
- at least one retention mechanism is meaningful if feasible
- real users have tested it
- at least one product/growth/monetization iteration was made from evidence
- the demo clearly shows resistance → feedback → retry
- screenshots communicate the product without explanation
- submission tells a coherent product story

---

# 23. Immediate next action for Claude Code

After reading this file and `PRD.md`:

1. Inspect the current repo.
2. Run the app.
3. Compare current implementation against P0.
4. Do not rewrite completed work.
5. Choose the **single highest-impact missing P0 vertical-slice task**.
6. Implement it.
7. Run analysis/tests/app.
8. Update this roadmap/checklist based on actual repository state.

The next priority should always be whatever gets the user closer to:

```text
scenario
→ realistic simulation
→ useful feedback
→ retry
```

# Rehearse — implementation status

> The live checklist [`ROADMAP.md`](ROADMAP.md) §3 asks for, measured against
> [`PRD.md`](PRD.md). Update this file whenever the answer changes; it is the
> document a new session should read first.
>
> **Last audited:** 2026-09-03, after analytics.
> **Verified by:** `flutter analyze` (clean), `flutter test` (166 passing),
> `cd server && npm test` (3 passing), `flutter build web --release` and
> `flutter build apk --debug` (both succeed).

---

## 1. The one-paragraph summary

The **practice loop runs end to end and is genuinely polished**: seven curated
scenarios, a briefing, a three-turn conversation in guided or free-form mode,
AI or offline scoring, and a coaching report. **Monetization is now built**:
RevenueCat, a three-rehearsal free limit, and a contextual paywall, all
covered by tests — but it has never completed a sandbox purchase, because that
needs App Store Connect and Play Console configuration. See
[`REVENUECAT.md`](REVENUECAT.md).

**Analytics is now built too** — the PRD §17 funnel, with the "never send
transcript content" rule enforced by the type system rather than by
discipline. See [`ANALYTICS.md`](ANALYTICS.md).

The one commercial P0 still missing is **onboarding**.

Two structural gaps inside the loop matter more than their size suggests:
**difficulty is a label, not a behaviour**, and **simulation and evaluation
share one prompt**, which is why feedback is a generic sentence instead of
"you said X, try Y".

---

## 2. Checklist in the roadmap's own format

### Already complete

- Curated scenario library — 7 scenarios, guarded by `test/scenarios_test.dart`.
- Scenario briefing screen with context, goal, and the trap to watch for.
- Conversation UI: chat layout, progress, auto-scroll, safe areas, disabled
  send while evaluating, transcript preserved on error.
- Guided mode (authored branching choices) and free-form mode (typed or
  dictated).
- Server-side LLM proxy. **No provider key ever reaches the client.**
- Structured JSON schema, validated on both sides.
- Graceful degradation: `ResilientCoachService` falls back to an on-device
  heuristic coach, so the app works with no key and no network.
- Deterministic session end (fixed turn count) and a coaching report.
- Retry CTA and "choose another".
- Local persistence of finished sessions: streak, weekly count, averages,
  per-scenario best, full history, clearable.
- Spoken employee replies with a persisted mute toggle *(P2 — see §5)*.
- Production bundle id `app.rehearse.rehearse` on both platforms; version
  `1.0.0+1`.
- Layout verified at 1.0×/1.3×/1.6× text scale by `test/text_scale_test.dart`.
- **RevenueCat**: SDK, `pro` entitlement, offerings fetched dynamically,
  paywall, purchase, restore (on the paywall and the progress screen), live
  entitlement refresh, and correct handling of cancelled purchases and
  unavailable offerings.
- **Free-session limit**: 3 completed rehearsals, lifetime, counted separately
  from practice history so clearing history cannot hand sessions back.
- **Contextual paywall** that opens on the weakest skill the person's own
  history shows, with copy overridable from offering metadata.
- **Analytics**: the PRD §17 funnel end to end, including abandonment with the
  turn reached, retry as its own attempt, and paywall triggers that
  distinguish a forced paywall from a voluntary upsell. Entitlement rides
  along as super properties. Provider-agnostic behind a three-method sink.

### Partially complete

| Item | What exists | What the PRD wants |
|---|---|---|
| **Difficulty** | `ScenarioDifficulty` is a fixed property of each scenario, rendered as a pill on the briefing | A **user choice before the session** (Calm / Defensive / Very Defensive) that materially changes wording, resistance, and escalation. PRD §7.2: "This must not be cosmetic." |
| **Evaluation dimensions** | clarity, empathy, **courage** | clarity, empathy, **directness**, **confidence** (PRD §10) |
| **Evaluation content** | one generic sentence per turn; report picks best/worst by score | exact user quote → why it was weak → suggested stronger wording (PRD §5.4, §10) |
| **AI architecture** | one `/evaluate` call does simulation *and* scoring in a single 350-token prompt | separate simulation and evaluation prompts. PRD §22: "Do not use one giant prompt for everything." |
| **Conversation length** | fixed 3 turns | 4–7 manager turns, with the model able to declare resolved or stalled |
| **Retry** | restarts the scenario from turn 1 | highlight the weak moment first, then retry (P0 fallback, PRD §11) |
| **Scenario coverage** | 7 of the 8 seeded categories | delegation is missing; boundary and saying-no are collapsed into one scenario (see §4) |
| **Malformed AI output** | falls back to the offline coach | server-side repair/retry once, then a controlled error (PRD §26) |
| **Error states** | inline messages, transcript preserved | "Retry feedback" without replaying the conversation |
| **Empty states / transitions** | present on home and progress | haptics and an animated score reveal are not built |

### Missing

Everything below is **P0 in the PRD** unless marked otherwise.

- **Onboarding.** App opens straight onto the home screen. This is now the
  last missing P0, and the copy is already written in PRD §18.
- Five PRD §16 events cannot fire yet because the feature does not exist:
  `onboarding_started`, `onboarding_completed`, `difficulty_selected`,
  `reminder_created`, `notification_opened`.
- **Optimistic message rendering.** The manager's own message does not appear
  until the coach responds — PRD §28 wants it rendered immediately.
- **Session outcome** (success / partial / unresolved / escalated).
- **Simulation state** (trust, tension, clarity, goal progress).
- **Employee background** field — the prompt has name and role only.
- **Crash reporting.**
- **App icon and launch screen** — still the stock Flutter logo. This is also a
  store-screenshot problem, not just a release checkbox.
- **Privacy policy**, store metadata, screenshots, signing config.
- OneSignal reminders *(P1)*.
- Session replay / "practice this moment again" *(P1)*.
- Dark theme *(not in the PRD; see §6)*.

### Broken

Nothing. Analysis is clean, all 166 Flutter tests and 3 server tests pass, and
both the web and Android builds succeed.

The two known **defects** are cosmetic but real, and both are documented in
§6 rather than here because they are quality issues rather than breakage.

---

## 3. Where the code stands per roadmap milestone

| Milestone | State |
|---|---|
| **M0** Audit existing repo | ✅ this document |
| **M1** Local vertical slice | 🟡 loop and free-session UX complete; onboarding and difficulty selection missing |
| **M2** Real AI simulation | 🟡 works, but one combined prompt and no personality input |
| **M3** Evaluation + retry | 🟡 scores and retry exist; quote-based critique does not |
| **M4** Monetization + analytics | 🟡 both built and tested; RevenueCat has never completed a sandbox purchase |
| **M5** Polish + reliability | 🟢 ahead of schedule — this is the strongest area |
| **M6** Release + submission | ❌ bundle id and version only |
| **M7–M9** Launch, growth, submission package | ❌ not started |

Onboarding is the one untouched P0. M4's remaining risk is not code — it is
that no real transaction and no real event have been observed end to end.

---

## 4. Scenario coverage against the Day 1 seed list

Target was 8 across six categories. Seven exist.

| Roadmap category | Covered by | |
|---|---|---|
| Difficult feedback ×2 | `missed-deadlines`, `high-performer` | ✅ |
| Performance ×2 | `missed-deadlines`, `promotion-denied` | 🟡 one is a career conversation, not a performance one |
| Boundary ×1 | `say-no` | 🟡 shared |
| Saying no ×1 | `say-no` | 🟡 same scenario as boundary |
| Conflict ×1 | `peer-conflict` | ✅ |
| Delegation ×1 | — | ❌ **missing** |

Beyond the seed list: `upward-feedback` and `resignation`.

Two writes would close this: a **delegation** scenario (PRD §7.1 category 6,
"delegating instead of taking work back"), and splitting **boundary** from
**saying no** — an after-hours-messages boundary is a distinct conversation
from declining a request.

The PRD is explicit that this should stop around 10: "Ten excellent scenarios
beat fifty generic scenarios."

---

## 5. Where the current build diverges from the plan

Recorded so the next session does not have to rediscover it.

**Voice is P2 and it is built.** The PRD lists "voice conversation" and
"realtime speech" under non-goals (§29) and P2 (§31); the roadmap agrees (§1).
Dictated answers and spoken replies both exist. The PRD's own escape clause —
"unless already implemented" — applies, and the work is done, tested, and
isolated behind `SpeechInputService` / `SpeechOutputService`, so it costs
nothing to keep. It should not be extended, and no further voice work belongs
before M4.

**Progress and history are P1 and they are built.** Session history and simple
progress sit in the roadmap's P1 list. They exist, with a streak, averages and
a trend. Note that PRD §19 cautions against "dashboards filled with metrics
before users have enough sessions" — the home screen already handles this by
showing the intro card until the first rehearsal is finished.

**Courage instead of directness and confidence.** The app scores three
dimensions; the PRD specifies four. Changing this is not just a rename: it
touches the server schema, `PracticeResponse`, `PracticeSummary`, the stored
`PracticeRecord` (which needs a migration or a version field), the report, and
the progress screen. Worth doing before there is stored user data to migrate,
not after.

**One prompt does two jobs.** `server/coach.mjs` asks a single model call to
score the manager *and* reply in character, inside `max_output_tokens: 350`.
This is the root cause of generic feedback: there is no budget for a quoted
critique, and the developer prompt has to tell the model both to coach and to
stay in character. Splitting it into `/simulation/respond` and
`/simulation/evaluate` is the highest-leverage change inside the loop.

---

## 6. Known quality defects

Both were measured, not guessed. Neither is in the PRD, so neither is P0 — but
both affect the screenshots the submission is judged on.

**Contrast.** Three pairs in the palette fail WCAG AA for body text:

| Pair | Ratio | Where |
|---|---|---|
| coral on peach | **2.34:1** | the coach's feedback text — the most important copy in the app |
| coral on canvas | **2.79:1** | "RECOMMENDED" and other eyebrow labels |
| muted on peach / mint | 3.8–4.1:1 | coach card bodies |

4.5:1 is the floor for body text. The forest-on-mint pair used for positive
feedback passes at 7.63:1, so only the warm half of the palette is affected.

**No dark theme.** `lib/app.dart` sets `theme:` only. `AppColors` are const
values referenced directly by roughly forty widgets, so adding one is a
palette-indirection change across the widget layer, not a one-line addition.

---

## 7. Recommended next actions

Ordered by what moves the submission, not by what is most interesting.

1. **Finish RevenueCat in the dashboards and complete a sandbox purchase.**
   Follow [`REVENUECAT.md`](REVENUECAT.md) §2–§6. The code is done; this is
   store configuration plus one device test, and until it happens the
   monetization is unproven.
2. **Point analytics at a real PostHog project and watch the funnel fill.**
   One `--dart-define` ([`ANALYTICS.md`](ANALYTICS.md) §Setup). Do it at the
   same time as the sandbox purchase so the monetization funnel is verified
   in one pass.
3. **Split the prompt, add quote-based critique.** This is what makes the
   feedback "actually useful" (PRD §35) and what the two-minute demo has to
   show. Do it with the dimension change in one pass.
4. **Difficulty selection.** Make the existing enum a pre-session choice that
   reaches the simulation prompt.
5. **Onboarding**, three screens, copy already written in PRD §18.
6. **App icon and launch screen.** An hour, and it is in every screenshot.
7. Contrast fixes and dark theme, if there is time before submission.

---

## 8. Handy facts

```text
State management : plain StatefulWidget + ChangeNotifier via InheritedNotifier
                   (no provider / riverpod / bloc)
Navigation       : imperative Navigator.push, no named routes or router package
Backend          : Node http server in server/, OpenAI Responses API
Persistence      : shared_preferences
Monetization     : RevenueCat (purchases_flutter), entitlement `pro`,
                   3 free completed rehearsals, keys via --dart-define
Analytics        : PostHog behind a provider-agnostic sink, key via
                   --dart-define, no-op without one
Dependencies     : http, speech_to_text, shared_preferences, flutter_tts,
                   purchases_flutter, posthog_flutter
Tests            : 166 Flutter + 3 server
TODO/FIXME       : none
```

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for how the pieces fit together,
[`REVENUECAT.md`](REVENUECAT.md) for store setup, and
[`ANALYTICS.md`](ANALYTICS.md) for the tracking plan.

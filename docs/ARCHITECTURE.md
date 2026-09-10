# Rehearse — architecture

How the code is actually put together. For what is missing, see
[`STATUS.md`](STATUS.md).

The guiding constraint: **the app must work with no API key and no network.**
Every remote capability has a local fallback, and the demo never depends on one.

---

## The loop

```text
_Root ──▶ OnboardingScreen (first run only)
  │
  ▼
HomeScreen ──▶ BriefScreen ──▶ PracticeScreen ──▶ ResultsScreen
    │            pick mode  │     3 turns          score + coaching
    │                       │                              │
    │              out of free rehearsals?                 │
    │                       │                              │
    │                  PaywallScreen                       │
    │                                                      │
    └──────────────── popUntil(isFirst) ◀──────────────────┘
                                                           │
                                       PracticeHistory.add() + one free
                                       rehearsal spent
```

`_Root` in `app.dart` picks the first screen, and waits on
`AppSettings.isLoaded` rather than assuming — otherwise a returning manager
sees a frame of onboarding on every cold start. Until then it shows a branded
launch state.

`ProgressScreen` hangs off the home header. Navigation is imperative
`Navigator.push` with `MaterialPageRoute` — there are no named routes and no
router package.

---

## Layers

```text
lib/
  main.dart            runApp
  app.dart             owns the four notifiers and installs their scopes
  data/
    scenarios.dart     all authored content — 7 const Scenario values
  models/
    scenario.dart          Scenario, DialogueTurn, ResponseChoice
    practice_response.dart PracticeResponse (one scored turn), PracticeMode
    practice_summary.dart  the scored outcome of a finished session
    coaching_note.dart     one quoted observation, and its grounding check
    practice_record.dart   one stored session
    subscription.dart      plans, offers, purchase outcomes
  screens/             onboarding, home, brief, practice, results, progress,
                       paywall
  services/
    coach_service.dart        remote + offline + resilient scoring
    speech_input_service.dart dictation
    speech_output_service.dart spoken replies
    practice_history.dart     stored sessions + momentum figures
    app_settings.dart         device preferences + the key/value store
    subscription.dart         entitlement + the free allowance (the gate)
    subscription_client.dart  RevenueCat, behind an interface
    analytics.dart            the typed funnel
    analytics_sink.dart       PostHog, behind an interface
    crash_reporter.dart       Sentry, behind an interface
  theme/app_theme.dart   AppColors tokens + the Material 3 theme
  widgets/               shared UI + the four InheritedNotifier scopes
server/
  handler.mjs          routes, validation, error shaping — no runtime
  worker.mjs           Cloudflare shell (production)
  server.mjs           Node shell (local `npm start`)
  coach.mjs            prompt construction and OpenAI Responses call
  wrangler.toml        deployment config
```

Three routes, two shells, one set of decisions: `GET /health`,
`POST /simulation/respond`, `POST /simulation/evaluate`.

---

## State management

Plain `StatefulWidget` for screen-local state; `ChangeNotifier` exposed through
`InheritedNotifier` for the four pieces of app-wide state. **No provider,
riverpod, or bloc** — do not introduce one without a reason the PRD requires.

```text
RehearseApp (StatefulWidget, owns the notifiers, calls load() in initState)
  └── RehearseScope — nests all four:
        PracticeHistoryScope      (InheritedNotifier<PracticeHistory>)
        AppSettingsScope          (InheritedNotifier<AppSettings>)
        SubscriptionScope         (InheritedNotifier<Subscription>)
        AnalyticsScope            (InheritedNotifier<Analytics>)
          └── MaterialApp
```

All four scopes sit **above** `MaterialApp`, so pushed routes still find them
by walking up through the `Navigator`.

`RehearseScope` exists because `app.dart` and every harness that wants a
realistic tree were each writing that nest out by hand — four chances to leave
one out and test something the app is not. Every service on it is **optional**,
so a test can still supply only what the screen under test reads; an omitted
one is simply absent, which is what hand-nesting gave you anyway.

Each scope offers two accessors, and the difference matters:

- `of(context)` — subscribes; the caller rebuilds when the notifier fires.
- `maybeOf(context)` — returns null when there is no scope, so a screen can be
  pumped standalone in a test. `ResultsScreen` uses this to degrade to "don't
  record" rather than crash.

> **Writing to a notifier during build throws.** `ResultsScreen` records a
> session from `didChangeDependencies`, which runs inside the build phase, so
> the write is deferred with `addPostFrameCallback`. Any new write on a build
> path needs the same treatment.

---

## Scoring

One number, computed in one place, so the report and the stored record can
never disagree.

```text
ResponseChoice / AI response
        │  scoreDelta (-10..14), four dimensions (-2..2 each)
        ▼
PracticeResponse                      one manager turn
        │
        ▼
PracticeSummary.fromResponses()       starts at 50; deltas sum for the score,
        │                             dimensions × 8; both clamped 0..100
        ├──▶ ResultsScreen            headline, summary, ring, bars, notes
        └──▶ PracticeRecord           persisted
```

A three-turn best path lands around 88–90; a worst path lands below 52. Those
bands are what `PracticeSummary.headline` switches on, and
`test/scenarios_test.dart` asserts every authored scenario reaches them.

The rubric is PRD §10's four dimensions: **clarity, empathy, directness,
confidence**. `PracticeSummary.skills` returns them in report order, and both
the coaching report and the progress screen render that map rather than
listing bars by hand, so the two cannot fall out of step.

> Records written before the fourth dimension existed stored directness under
> the name `courage` — which is what the server schema always described it as.
> `PracticeRecord.tryFromJson` maps it across. Confidence was genuinely not
> measured then, so it stays **null** rather than becoming a fabricated 50,
> and `averageConfidence` returns null until some rehearsal has actually been
> scored on it.

---

## The coach

Two jobs, two prompts, two endpoints — PRD §22 is explicit that one giant
prompt should not do both, and the old combined call is exactly why feedback
used to be a generic sentence.

```text
                    createCoachService()
                            │
              REHEARSE_COACH_URL set?
                    │               │
                   yes              no
                    │               │
        ResilientCoachService       └──▶ OfflineCoachService
           │            │
      RemoteCoachService └── on ANY error ──▶ OfflineCoachService
           │
           ├── POST /simulation/respond    per turn, 15s
           │     the employee answers in character, and never coaches
           │
           └── POST /simulation/evaluate   once at the end, 30s
                 the whole transcript, scored, with quoted critique
```

### Where it runs

Cloudflare Workers. The evaluation call can take most of the 30s the client
allows, and Workers bills **CPU time, not wall time** — waiting on OpenAI is
free. What this actually computes (parse, build a request, ground a handful
of quotes) sits well inside the free tier's 10ms budget, and one external
subrequest per call is nothing against a limit of 50.

That suits code with no dependencies and no state: nothing here needs a
process that stays warm.

```bash
cd server
npx wrangler secret put OPENAI_API_KEY   # a secret, never a var
npm run deploy
```

`handler.mjs` holds every decision; `worker.mjs` and `server.mjs` only
translate to and from their runtime's request type. That split is deliberate
— two shells each owning a copy of the routing is how `/health` once ended
up reporting a model the app was not using.

> **The key is the whole reason a backend exists.** `--dart-define` values are
> compiled into `libapp.so` as plain text and come straight back out of a
> release build with `strings`. There is no version of shipping the provider
> key in the client that is safe.

### The rate limit

Unauthenticated and spends money, so this is the only thing between a script
and the OpenAI bill. Two Cloudflare rate-limit bindings, keyed on client IP,
sized from real usage rather than a round number:

| Bucket | Limit | Why |
|---|---|---|
| `RESPOND_LIMITER` | 30 / 60s | a person going quickly sends ~2/min |
| `EVALUATE_LIMITER` | 10 / 60s | exactly one per rehearsal, and the expensive half |

Separate buckets so the cheap call cannot starve the expensive one. The
headroom is for carrier NAT — roughly fifteen people can share one address
before anybody legitimate is refused.

It caps a saturating IP at **about $14 a day** against no ceiling at all.
Cloudflare counts per location and is explicit that this is eventually
consistent, so that is the right order of magnitude rather than a guarantee.
`/health` and preflight are never limited: neither calls a model, and a
health check that can be rate limited is a monitoring problem.

Which routes are limited lives in `handler.mjs` with the other route rules;
only the mechanism is in `worker.mjs`, because only Cloudflare has one. Local
Node passes no limiter, so `npm start` is unlimited.

> A refusal is a 429, and `ResilientCoachService` treats every non-200 the
> same way — it falls back to the offline coach without saying so. Someone
> rate limited gets the demo coach and no explanation. That is the right
> trade for a limit this generous, but it is the reason the limits have
> headroom rather than being tight.

`ALLOWED_ORIGIN` still needs setting before this is public. The rate limit
bounds the damage; CORS narrows who can try.

### Node, locally

`npm start` still runs the same routes through `server.mjs` for development,
reading `process.env` where the worker reads its `env` argument. `coach.mjs`
knows about neither — the shells pass `apiKey` and `model` in explicitly,
which is what keeps it runtime-agnostic.

### The model

Both endpoints run `gpt-5-nano`, set once as `DEFAULT_MODEL` in
`server/coach.mjs` and overridable per deployment with `OPENAI_MODEL`.
`/health` reports whichever is live — it imports the constant rather than
repeating it, because a health check that names the wrong model is worse
than one that names none.

It is the cheapest model in the family: about **$0.001 per rehearsal**
against $0.054 on `gpt-5.6-sol`, measured on the real payloads — 3 respond
calls at ~2,100 input and 900 output tokens, one evaluate at ~950 and 1,200.
Output dominates, which is why the evaluation call is over half the bill on
any model.

OpenAI positions nano for summarization and classification and points at
`gpt-5.6-luna` for more demanding work, so the evaluation prompt is the one
under the most strain here: it has to hold a strict `json_schema` and copy
the manager's words character for character for the quoted critique. If that
degrades, `/simulation/evaluate` is the endpoint to move up first — the two
build functions already take a model argument, so splitting them is a small
change rather than a rewrite.

### During the conversation

`respond()` carries the chosen `SimulationDifficulty` and returns what the
other person says, plus a `SimulationResolution` — `continuing`, `resolved`
or `breakdown`.

That second field is PRD §9's first three end conditions, and it is the only
thing that lets a conversation stop before the turns run out. It never
reaches the screen: §7.3 says the simulation must not explain itself while it
runs, so it decides whether there is another turn and nothing else. It is
also ignored on the opening exchange — a model that declares victory after
one message would take away the practice the person came for.

### How a conversation ends, and how that is reported

Two different questions, answered in two different places, because they can
disagree — a manager can handle a conversation well and still lose the room.

| | Where it comes from |
|---|---|
| **Ending early** (§9) | `SimulationResolution` from `respond()`, free-form only |
| **The outcome** (§11) | `SessionOutcome` on `PracticeSummary` |

`SessionOutcome` is success / partial / unresolved / escalated, and is
**never derived from the score** — that would make the report claim the
simulation modelled something it did not. Every value traces to one of three
sources:

- **Free-form, online.** `/simulation/evaluate` returns it, judged on the
  transcript. An unreadable value falls back to `unresolved` rather than to
  whatever the score implies.
- **Guided.** Authored on the closing `ResponseChoice.resolution`. A guided
  conversation cannot end early — the authored turns always run out — so the
  closing move is what the other person is left with. `scenarios_test.dart`
  asserts every scenario's last turn carries one, that no earlier turn does,
  and that all four values are reachable somewhere in the library.
- **Free-form, offline.** The closing message is matched to the nearest
  authored closing choice by `_closestChoice`, the same mechanism the offline
  scores already use, and that choice's authored resolution is the outcome.
  Below the similarity floor nothing authored applies and the answer is
  `unresolved` — not a failure verdict, just the honest statement that
  nothing here saw the expectation land.

> **Stakes and difficulty are different things.** `Scenario.stakes`
> (warm-up / challenging / high-stakes) is how heavy the situation is, and is
> authored. `SimulationDifficulty` (calm / defensive / very-defensive) is how
> hard the other person pushes, and is chosen per session. A high-stakes
> conversation can be held with someone calm. They used to share a name, which
> made the picker unreadable next to the briefing pill.

The level is the only thing that changes between simulation prompts, so
`TEMPERAMENTS` in `server/coach.mjs` has to carry the whole difference: each
entry names how readily the person accepts a point, how hard they challenge,
and how far they escalate. A server test asserts the three are distinct and
that resistance never becomes licence to be unpleasant.

Difficulty deliberately does **not** reach the evaluation prompt. Scoring
judges the manager, not how hard the setting was; mixing them would make an
easy session score better for no reason. **Nothing scores a turn
while the conversation is running** (PRD §7.3): the consequence of a weak
message is the reply it earns, not a note about it. Guided mode is the
exception, and only because its feedback is authored rather than generated —
it is a teaching mode.

### At the end

`evaluate()` reads the transcript once and returns absolute 0-100 dimensions
plus `strengths` and `improvements`, each carrying:

| Field | |
|---|---|
| `turnIndex` | which manager turn it refers to |
| `quote` | the manager's own words, **verbatim** |
| `comment` | why it worked, or why it did not |
| `suggestion` | stronger wording — improvements only |

> **Quotes are validated on both sides.** Models paraphrase, and a critique of
> words nobody said would poison the one thing this report has to get right.
> `groundNotes` in `server/coach.mjs` and `CoachingNote.isGroundedIn` both
> normalise case, punctuation and smart quotes, then drop any note whose quote
> cannot be found in a manager turn. A dropped note is better than a
> fabricated one.

### Three sources, one shape

Every mode produces the same `PracticeSummary`, so the report renders one
thing:

| Mode | Score from | Quotes are | Suggestions are |
|---|---|---|---|
| Guided | authored per-turn deltas | the choice you picked | the strongest choice you did not |
| Free-form, AI | the evaluation call | validated model output | model output |
| Free-form, offline | keyword and similarity heuristics | what you typed | **the authored best choice for that turn** |

The offline coach cannot vary mid-conversation resistance, because those lines
are authored — but it does vary how the conversation *lands*, since a very
defensive person does not sign off agreeing. Guided mode offers no difficulty
control at all rather than a cosmetic one.

That last row matters: with no key and no network the report still quotes you
and still offers real alternative wording, because the authored content
already contains the strongest version of each turn.

**The key never reaches the client.** `OPENAI_API_KEY` lives only in the
server environment. The Flutter app knows a URL and nothing else.

## Speech

Both directions sit behind an interface so tests inject a fake and the device
implementation is never constructed in a widget test.

| | Interface | Device implementation | Package |
|---|---|---|---|
| In | `SpeechInputService` | `DeviceSpeechInputService` | `speech_to_text` |
| Out | `SpeechOutputService` | `DeviceSpeechOutputService` | `flutter_tts` |

Rules the practice screen enforces:

- Speaking stops the instant the microphone opens, and on dispose.
- A line is tracked by content, so a rebuild cannot restart it mid-sentence.
- If `initialize()` returns false the app stays silent and hides the control.
  **Speech is an enhancement; nothing in the loop may depend on it.**

Speech rate is read from `getSpeechRateValidRange` rather than hardcoded,
because Android treats 1.0 as normal and iOS treats 0.5 as normal.

---

## Monetization

```text
                  createSubscriptionClient()
                            │
            REHEARSE_REVENUECAT_<PLATFORM>_KEY set?
                    │                   │
                   yes                  no (includes web)
                    │                   │
    RevenueCatSubscriptionClient        └──▶ UnconfiguredSubscriptionClient
                    │                            configure() == false
                    ▼
              Subscription  ── the gate: canStartPractice
                    │
        ┌───────────┴───────────┐
   entitlement `pro`      free sessions used
   (store, live)          (local, monotonic)
```

`Subscription` owns the single question the UI asks — *may this person start
another rehearsal?* — because the answer depends on both halves.

Three rules:

1. **An unconfigured build never gates.** No key, or a failed `configure()`,
   means unlimited free rehearsals and no paywall anywhere. This keeps the
   demo runnable and satisfies PRD §26.
2. **The free counter is not the practice history.** It lives under its own
   settings key, so clearing your history — a privacy action — cannot hand
   back free sessions.
3. **Only a completed rehearsal counts.** `ResultsScreen` spends the session
   when the report is reached, so abandoning one costs nothing.

Prices and packages are never hardcoded; they come from the current RevenueCat
offering. Paywall copy can also come from **offering metadata**
(`headline`, `subhead`, `cta`), which makes wording experiments a dashboard
change rather than a release. Absent that, the paywall falls back to the
weakest skill in the person's own history — see
[`REVENUECAT.md`](REVENUECAT.md).

Restore lives on the progress screen as well as the paywall, because the app
stores require it to be reachable without an upgrade prompt in the way.

## Analytics

```text
Screens ──▶ Analytics (typed funnel) ──▶ AnalyticsSink ──▶ PostHog
                                              │
                                    no key ──▶ NoopAnalyticsSink
```

`Analytics` exposes one typed method per funnel step. **No method accepts free
text** — every parameter is an id, an enum, a number, or a boolean, which is
what makes PRD §16's "never send raw conversation contents" a property of the
type system rather than of everyone's discipline. The manager's response
reaches it only as a character count.

Two tests hold that line: one plays a full free-form rehearsal with a
distinctive phrase and searches every payload for it, and one asserts that
every string emitted is catalog metadata from an allowlist.

`AnalyticsSink` is three methods, so swapping PostHog for Amplitude, Mixpanel,
or Segment is one class and no call-site changes. Event names and properties
are the contract — see [`ANALYTICS.md`](ANALYTICS.md).

Entitlement is registered as super properties whenever it changes, so any
funnel can be split by free versus Pro without threading state through each
call.

## Crashes

`CrashReporter` wraps Sentry, and `main` runs the app inside it. With no DSN
it runs the app and forgets errors, like every other remote capability here.

Screenshots, view hierarchies and user-interaction breadcrumbs are all off:
each of them can carry the text of a rehearsal, which is the one thing that
must not leave the device except to the coach.

It also reports something that is not a crash. `ResilientCoachService` takes
an `onFallback` callback, so when the AI coach fails and the offline coach
takes over, that is sent as a handled warning. The degradation is invisible in
the app beyond a badge — right for the person practising, wrong for whoever
runs the service.

## Persistence

`shared_preferences`, wrapped so tests never touch a platform channel.

| Notifier | Store interface | Key |
|---|---|---|
| `PracticeHistory` | `PracticeHistoryStore` | `rehearse.practice_history` (string list of JSON) |
| `AppSettings` | `SettingsStore` | `rehearse.spoken_replies` (bool), `rehearse.onboarding_completed` (bool) |
| `Subscription` | `SettingsStore` | `rehearse.free_sessions_used` (int) |

Each has a `SharedPreferences…` implementation and an `InMemory…` one.

Three rules hold throughout:

1. **Every read and write failure is swallowed.** Storage must never interrupt
   a rehearsal. A failed load yields an empty history, not an error screen.
2. **A corrupt entry is skipped, not fatal.** `PracticeRecord.tryFromJson`
   returns null rather than throwing, so one bad row written by an older build
   cannot take the rest of someone's history with it.
3. **Records are capped** at `PracticeHistory.maxRecords` (200).

There is no schema version field yet. Adding or renaming a scored dimension
will need one — see `STATUS.md` §5.

---

## Theme

`AppColors` holds flat `const Color` tokens; `AppTheme.light` builds the
Material 3 theme. Widgets reference `AppColors.*` **directly**, not through
`Theme.of(context)`, which is why adding a dark theme is a change across the
whole widget layer rather than a single addition in `app.dart`.

Scenario cards use the tint set — `peach`, `lavender`, `mint`, `sky`, `butter`,
`rose` — all light enough to carry `AppColors.ink`.

### Two families

`AppTheme.fontFamily` (Plus Jakarta Sans) is the app. `AppTheme.serifFontFamily`
(Literata) reaches exactly two `TextStyle`s, both in `results_screen.dart`: the
quote in `_Quote`, and the rewrite in the `STRONGER` box. The rule is *sans is
the app talking, serif is what a person said* — and a note card is the one place
that has to hold your line, our read of it, and a better line in a single
column, which one family can only distinguish by convention. The quote was
italic for that reason before the serif existed.

Neither family goes through `ThemeData`, which takes a single `fontFamily`; the
serif is named on the two styles directly. `AppTheme.serifFallback` points at
the sans, because both strings can come from the model and the bundled Literata
is subset to latin — a glyph it lacks falls back rather than drawing a box.

The serif is a point larger than the sans beside it (15 against 14) so the two
*look* the same size. `tool/generate_screenshots.dart` loads both families, or
the coaching report — the one store shot with a quote in it — renders the serif
as boxes.

`AppTheme.overlayStyle` is the status bar, and it is set in two places
because there are two ways a screen gets one. An `AppBar` picks its own
style by estimating the brightness of its background, and this app bar is
transparent — which estimates as *dark* and asks the system for white icons
on a white bar. `AppBarTheme.systemOverlayStyle` overrides that; `app.dart`
calls `SystemChrome.setSystemUIOverlayStyle` once for home and onboarding,
which have no app bar to assert it for them. The two brightness fields are
deliberate opposites: Android names the icons, iOS names the background.

Home and onboarding both put their header *outside* the scrollable — a
`Column` of a fixed `Padding` and an `Expanded` list — so it stays put and
the content cannot ride up under the status bar. The header carries its own
bottom padding rather than leaning on the list's top padding, because the
list's scrolls away and the first line passing underneath would be sliced
against the logo.

`Paper.lift` (in `lib/theme/`) is the one thing the UI borrows from the
illustrations: a contact shadow. A card separated only by a hairline border
reads as drawn *on* the page; the marks read as paper because of edge and
shadow, and this lends a card the same treatment so it reads as laid on it.
`AppTheme.cardTheme` carries the same weight through `elevation`, because
`Card` takes an elevation rather than a shadow list — move one, move the other.

A **grain texture was prototyped and dropped**, and `paper.dart` records why
at length so it is not proposed again. Briefly: shadow alone carries the
material, and grain costs a surface that can no longer state a contrast ratio
— which matters while §6's three pairs still fail — bakes in a light-mode
assumption, and repeats the mistake `AppColors.canvas` already names. Applied
to the whole app it also flattens the figure and ground the marks depend on:
they read as objects because the page behind them is plain.

`Eyebrow` is the small all-caps label — the kicker above a screen title, and
the smaller one inside a card. There were eleven of these written out by hand,
all at 800 weight but spread across three sizes and six letter-spacings, which
is how something meant to read as one element stops doing so. `SCORE` on the
coaching report is deliberately **not** one: it is tracked much wider because
it sits under a 64pt numeral.

`ScoreRing` carries an accessibility rule worth preserving: it grows with the
text scale and caps both together at 1.4×, so scaled numerals stay inside the
circle. It takes explicit colours, with an `onDark` variant for the progress
banner.

---

## Brand assets

### Illustrations

Ten paper cut-out marks identify the seven scenarios, the empty progress
screen, the paywall, and the app's own header — `BrandMark` shows the `logo`
mark beside the wordmark, where it used to draw a forest square with a
Material glyph in it. `Illustration` (in `lib/widgets/`) is the only thing
that knows where they live; a scenario's mark is found by its id, so there is
no table to keep in step and no field on `Scenario` to forget.

The masters are large and stay out of the bundle. `art/illustrations/` holds
them; `tool/generate_illustrations.dart` cuts the `1.0x` / `2.0x` / `3.0x`
variants that ship into `assets/illustrations/`. The style, the prompts and
the sizes are in [`ILLUSTRATIONS.md`](ILLUSTRATIONS.md).

Two things follow from an asset being a real image rather than a glyph. A
widget test's clock does not run the decode, so any harness that captures a
frame has to `await Illustration.precacheAll` first or the marks come out
blank — both `tool/generate_screenshots.dart` and `test/visual_qa_test.dart`
do. And the variant Flutter picks comes from the *device pixel ratio*, which
is why the screenshot harness now lays out at a real ratio of 3 rather than
faking 1 and rasterising at 3: the second lays out identically but resolves
every asset at `1.0x`, and the store would get upscaled art.

### Icon and splash

What is left in `BrandMarkPainter` is the icon and the splash, which stay
**drawn in Dart** rather than shipped as art:
`lib/theme/brand_mark_painter.dart` paints two speech bubbles on a 1024 grid
using the same `AppColors` as the rest of the app, so the icon cannot drift
from the brand. The same painter renders Flutter's own launch state, which is
why the handoff from the native splash is invisible.

To regenerate after changing the mark:

```bash
flutter test tool/generate_app_icon.dart   # masters -> assets/icon/
dart run flutter_launcher_icons             # fan out to every platform
git checkout -- ios/Runner.xcodeproj/project.pbxproj
```

> **That last line is not optional.** flutter_launcher_icons 0.14.4 does a
> naive string replace on the pbxproj and clobbers
> `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` — a boolean —
> with `AppIcon`, on the two build configurations that have no
> `ASSETCATALOG_COMPILER_APPICON_NAME` line of their own. The project already
> sets the icon name correctly, so the edit is pure damage.

Four masters come out of the generator, and each exists for a reason:

| Master | Used for | Why it differs |
|---|---|---|
| `app_icon` | iOS, web, Android legacy | opaque, mark nearly full-bleed |
| `app_icon_foreground` | Android adaptive | transparent; sized so the mark still fills the circle *after* flutter_launcher_icons adds its own 16% inset |
| `app_icon_monochrome` | Android 13 themed icons | one colour, with the gap between bubbles cut out rather than painted, so a tint keeps them legible |
| `launch_mark` | both splashes | inked forest-on-canvas, because the icon's cream bubble is invisible on the splash colour |

`test/app_icon_test.dart` guards the outputs, most importantly that the iOS
1024 icon has no alpha channel — App Store Connect rejects one that does, at
the last step of submission.

## Navigation

Three tabs, and everything else pushed over them.

```text
TabsScreen (IndexedStack + NavigationBar)
  ├── HomeScreen      Practice — the scenario list
  ├── ProgressScreen  Progress — streak, skills, session history
  └── YouScreen       You — plan and Restore, preferences, your data
```

An `IndexedStack` rather than a swapped child, so each tab keeps its scroll
position and its state. There is **no per-tab navigator and no router**:
`BriefScreen`, `PracticeScreen`, `ResultsScreen` and `PaywallScreen` are all
still imperative `Navigator.push` onto the root navigator, which is what puts
them *over* the bar. A flow that covers the bar is the behaviour we want — a
rehearsal is not a place you tab away from.

Two consequences worth knowing. A tab root has nothing to pop, so
`ProgressScreen` takes an optional `onPickScenario` and its empty state
switches tab instead of popping; passed nothing, it falls back to
`maybePop`, which is what lets it still be pumped on its own in a test. And
`Scaffold` strips the bottom inset from its body when it has a
`bottomNavigationBar`, so the screens inside see a bottom padding of zero and
do not double-count the home indicator.

The **Practice** tab leads with a card for whatever is next — the scenario
`HomeScreen.recommendedScenario` picks — and then the library, grouped by
`ScenarioStakes` into warm-up, challenging and high stakes, two across. That
grouping is the only one the content supports: `skill` is unique per scenario
and would put one in each group, while stakes splits 2/2/3 and happens to be
a difficulty ramp, which is the order a library like this wants to be read in.

The featured scenario is left **out** of the grid rather than repeated in it.
On a phone the card and the first group are on screen together, and the same
scenario twice reads as a mistake rather than a shortcut.

The tiles size to their content — `IntrinsicHeight` and a `Row` of two, not a
grid with a fixed aspect ratio. A title wraps to three lines at 1.6× text and
a tile that could not grow would clip it; `test/text_scale_test.dart` is what
holds that.

The **You** tab exists because the progress screen was answering two
questions at once — "how am I doing" and "what have you got of mine". It
carries plan state and Restore, the two preferences, what the app keeps, and
a way back to the intro. Restore in particular has to be reachable without an
upgrade prompt in the way, which is a store requirement and was previously
satisfied only by a card halfway down the progress screen.

`DifficultyPicker` is shared with the briefing, because the same setting is
reachable from both: the briefing sets it for this rehearsal, You sets what a
briefing opens on. It takes a `keyPrefix` for one reason — the tabs stay built
underneath a pushed briefing, so both copies are in the tree at once and a
finder would otherwise match two.

"Show the intro again" clears the onboarding flag and navigates nothing. The
root already watches that flag and swaps itself, which is the same path a
first run takes.

---

## The practice screen

The one screen split across files. It was 1,356 lines, which is the only
place in the app where "where is X" is a real question:

```text
practice_screen.dart      PracticeScreen and its State — the turn loop
practice/transcript.dart  what the conversation looks like
practice/composer.dart    what you answer with, in both modes
```

The two halves are **`part`s, not libraries.** Their widgets stay private to
the screen, which is the point: they are its innards rather than a set
anything else may reach for, and making them public to solve a file-length
problem would have invited exactly that. The cost is that a part carries no
imports of its own — the library's are at the top of `practice_screen.dart`.

`_PracticeScreenState` stays whole at ~570 lines. Splitting it means lifting
the turn loop into a controller, which is a rewrite of working code rather
than a move, and nothing has asked for one.

---

## Testing

| File | Covers |
|---|---|
| `widget_test.dart` | the full loop end to end, plus dictation |
| `scenarios_test.dart` | authored content invariants, per scenario |
| `practice_history_test.dart` | scoring maths, JSON, streak, averages, storage failure |
| `progress_test.dart` | home momentum, recommendation, progress screen |
| `spoken_replies_test.dart` | when the character speaks, mute, persistence |
| `text_scale_test.dart` | every screen at 1.0×, 1.3×, 1.6× |
| `coach_service_test.dart` | remote parsing and offline scoring |
| `subscription_test.dart` | the gate, purchase and restore outcomes, and the paywall |
| `analytics_test.dart` | the funnel end to end, and that no content leaks |
| `onboarding_test.dart` | first run, skip, the no-flash launch, and copy honesty |
| `app_icon_test.dart` | the generated icons and splashes on every platform |
| `visual_qa_test.dart` | renders each screen to `/tmp/rehearse-*.png` |

Two of these are unusual and deliberate:

**`text_scale_test.dart` has no assertions.** Flutter reports a layout overflow
as a test failure, so laying every screen out at a large text scale *is* the
assertion. It has caught four real overflows.

**`visual_qa_test.dart` writes PNGs** for visual review. Text renders as boxes
because there is no real font in the test environment — it verifies layout, not
typography. Real-font problems need a browser: `flutter build web && ` serve
`build/web` (there is a `.claude/launch.json` for this).

`scenarios_test.dart` is the guard on the content. It asserts complete
briefings, unique ids and characters, an opening line matching turn one, scores
inside the coach's range, one clearly best answer per turn with a real gap to
the runner-up, and a best path that reaches the top band while the worst does
not. **Add a scenario and it is checked automatically.**

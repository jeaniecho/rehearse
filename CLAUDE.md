# Rehearse — working notes

A practice simulator for first-time managers rehearsing difficult workplace
conversations. Flutter app plus a small Node proxy to an LLM.

## Read these first

| Document | What it is |
|---|---|
| [`docs/STATUS.md`](docs/STATUS.md) | **Start here.** What is built, what is missing, what to do next. |
| [`docs/PRD.md`](docs/PRD.md) | The product spec. Requirements, priorities, acceptance criteria. |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Day-by-day execution plan and milestones. |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | How the code is put together. |
| [`docs/REVENUECAT.md`](docs/REVENUECAT.md) | Dashboard and store setup, and how the app behaves without keys. |
| [`docs/ANALYTICS.md`](docs/ANALYTICS.md) | The tracking plan, and the rule that no event may carry free text. |

`PRD.md` and `ROADMAP.md` are the plan of record — **do not edit them to match
the code.** When reality diverges, record it in `STATUS.md`.

## Commands

```bash
flutter pub get
flutter analyze                 # must be clean
flutter test                    # 166 tests
cd server && npm test           # 3 tests
```

```bash
flutter run                     # offline demo coach, unmetered, no keys needed
```

With monetization (see `docs/REVENUECAT.md`):

```bash
flutter run --dart-define=REHEARSE_REVENUECAT_IOS_KEY=appl_xxx --dart-define=REHEARSE_REVENUECAT_ANDROID_KEY=goog_xxx
```

With the AI coach:

```bash
cd server && OPENAI_API_KEY=... npm start
flutter run --dart-define=REHEARSE_COACH_URL=http://127.0.0.1:8787
```

To check layout with real fonts (widget tests render text as boxes):

```bash
flutter build web --release
```

then serve `build/web` — `.claude/launch.json` has a config for it.

## Priorities

From `ROADMAP.md` §0, and they hold:

1. P0 beats P1. RevenueCat and analytics are built; **onboarding is the last
   untouched P0**. Neither a sandbox purchase nor a real analytics event has
   been observed end to end yet.
2. Working vertical slices beat architectural perfection.
3. Do not rewrite working code to match the PRD more literally.
4. Every day ends with a runnable app.
5. Voice, custom scenarios, and a broad scenario library are P2. Do not extend
   them. (Voice already exists — see `STATUS.md` §5.)

## Conventions

- **Plain `StatefulWidget` + `ChangeNotifier` via `InheritedNotifier`.** No
  provider, riverpod, or bloc. Do not introduce one.
- **Imperative `Navigator.push`.** No named routes, no router package.
- Services are declared as an `abstract interface class` with a device
  implementation and an in-memory or fake counterpart, injected through an
  optional widget constructor parameter. Follow the pattern for anything new
  that touches a platform channel or the network.
- Colours come from `AppColors` directly, not `Theme.of(context)`.
- Prose in the UI and in comments uses typographic apostrophes (`’`).
- Comments explain **why**, not what. Match the existing density — sparse.
- `dart format` before committing.

## Invariants — do not break these

- **No provider API key in the client, ever.** `OPENAI_API_KEY` lives only in
  the server environment. The app knows a URL and nothing else.
- **The app must work with no keys and no network.** `ResilientCoachService`
  falls back to `OfflineCoachService`, and an unconfigured `Subscription`
  never gates. Every remote capability needs a local fallback, and the demo
  must never depend on one.
- **Never gate on a store that isn't there.** No RevenueCat key, or a failed
  `configure()`, means unlimited free rehearsals — never a locked app.
- **The free-session counter is not the practice history.** Clearing history
  is a privacy action and must not hand back free sessions.
- **Storage failures never interrupt a rehearsal.** Reads and writes are
  wrapped; a corrupt record is skipped, not thrown.
- **Speech is an enhancement.** If the device has no voice, the app stays
  silent and hides the control. Nothing in the loop may depend on it.
- **Never write to a `ChangeNotifier` during build.** Defer with
  `addPostFrameCallback` — see `ResultsScreen`.
- **Scoring lives in `PracticeSummary`**, so the report and the stored record
  cannot disagree. Do not recompute it in a widget.
- **Never send transcript content to analytics** (PRD §16). No method on
  `Analytics` may take a `String` parameter — use an id or an enum. There are
  tests that will fail if this slips.

## Testing notes

- `test/scenarios_test.dart` guards all authored content. Add a scenario and it
  is checked automatically; if it fails, the scenario is wrong, not the test.
- `test/text_scale_test.dart` has no assertions on purpose — Flutter reports a
  layout overflow as a test failure, so laying screens out at 1.3× and 1.6×
  text *is* the assertion.
- Widget tests render text as boxes. Real-font problems only show in a browser.

## Current shape

```text
lib/data       authored scenario content (7 scenarios)
lib/models     Scenario, PracticeResponse, PracticeSummary, PracticeRecord,
               Subscription plans and outcomes
lib/screens    home, brief, practice, results, progress, paywall
lib/services   coach (remote/offline/resilient), speech in/out, history,
               settings, subscription + RevenueCat, analytics + PostHog
lib/theme      AppColors tokens + Material 3 theme
lib/widgets    shared UI + the four InheritedNotifier scopes
server         Node proxy: GET /health, POST /evaluate
```

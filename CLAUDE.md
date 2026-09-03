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

`PRD.md` and `ROADMAP.md` are the plan of record — **do not edit them to match
the code.** When reality diverges, record it in `STATUS.md`.

## Commands

```bash
flutter pub get
flutter analyze                 # must be clean
flutter test                    # 106 tests
cd server && npm test           # 3 tests
```

```bash
flutter run                     # offline demo coach, no key needed
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

1. P0 beats P1. The contest is a **RevenueCat** contest; monetization and
   analytics are P0 and are not built. Polish is already ahead of them.
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
- **The app must work with no key and no network.** `ResilientCoachService`
  falls back to `OfflineCoachService`. Every remote capability needs a local
  fallback, and the demo must never depend on one.
- **Storage failures never interrupt a rehearsal.** Reads and writes are
  wrapped; a corrupt record is skipped, not thrown.
- **Speech is an enhancement.** If the device has no voice, the app stays
  silent and hides the control. Nothing in the loop may depend on it.
- **Never write to a `ChangeNotifier` during build.** Defer with
  `addPostFrameCallback` — see `ResultsScreen`.
- **Scoring lives in `PracticeSummary`**, so the report and the stored record
  cannot disagree. Do not recompute it in a widget.
- **Never send transcript content to analytics** when analytics is added
  (PRD §16).

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
lib/models     Scenario, PracticeResponse, PracticeSummary, PracticeRecord
lib/screens    home, brief, practice, results, progress
lib/services   coach (remote/offline/resilient), speech in/out, history, settings
lib/theme      AppColors tokens + Material 3 theme
lib/widgets    shared UI + the two InheritedNotifier scopes
server         Node proxy: GET /health, POST /evaluate
```

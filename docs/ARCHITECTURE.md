# Rehearse — architecture

How the code is actually put together, as of commit `7c7f191`. For what is
missing, see [`STATUS.md`](STATUS.md).

The guiding constraint: **the app must work with no API key and no network.**
Every remote capability has a local fallback, and the demo never depends on one.

---

## The loop

```text
HomeScreen ──▶ BriefScreen ──▶ PracticeScreen ──▶ ResultsScreen
    │            pick mode        3 turns            score + coaching
    │                                                      │
    └──────────────── popUntil(isFirst) ◀──────────────────┘
                                                           │
                                                    PracticeHistory.add()
```

`ProgressScreen` hangs off the home header. Navigation is imperative
`Navigator.push` with `MaterialPageRoute` — there are no named routes and no
router package.

---

## Layers

```text
lib/
  main.dart            runApp
  app.dart             owns PracticeHistory + AppSettings, installs both scopes
  data/
    scenarios.dart     all authored content — 7 const Scenario values
  models/
    scenario.dart          Scenario, DialogueTurn, ResponseChoice
    practice_response.dart PracticeResponse (one scored turn), PracticeMode
    practice_summary.dart  scoring maths for a finished session
    practice_record.dart   one stored session
  screens/             home, brief, practice, results, progress
  services/
    coach_service.dart        remote + offline + resilient scoring
    speech_input_service.dart dictation
    speech_output_service.dart spoken replies
    practice_history.dart     stored sessions + momentum figures
    app_settings.dart         device preferences
  theme/app_theme.dart   AppColors tokens + the Material 3 theme
  widgets/               shared UI + the two InheritedNotifier scopes
server/
  server.mjs           http server: GET /health, POST /evaluate
  coach.mjs            prompt construction and OpenAI Responses call
```

---

## State management

Plain `StatefulWidget` for screen-local state; `ChangeNotifier` exposed through
`InheritedNotifier` for the two pieces of app-wide state. **No provider,
riverpod, or bloc** — do not introduce one without a reason the PRD requires.

```text
RehearseApp (StatefulWidget, owns both notifiers, calls load() in initState)
  └── PracticeHistoryScope   (InheritedNotifier<PracticeHistory>)
        └── AppSettingsScope (InheritedNotifier<AppSettings>)
              └── MaterialApp
```

Both scopes sit **above** `MaterialApp`, so pushed routes still find them by
walking up through the `Navigator`.

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
        │  scoreDelta (-10..14), clarity/empathy/courage (-2..2)
        ▼
PracticeResponse                      one manager turn
        │
        ▼
PracticeSummary.fromResponses()       starts at 50; deltas sum for the score,
        │                             dimensions × 8; both clamped 0..100
        ├──▶ ResultsScreen            headline, summary, ring, bars
        └──▶ PracticeRecord           persisted
```

A three-turn best path lands around 88–90; a worst path lands below 52. Those
bands are what `PracticeSummary.headline` switches on, and
`test/scenarios_test.dart` asserts every authored scenario reaches them.

> The dimensions are **clarity, empathy, courage**. The PRD specifies
> **clarity, empathy, directness, confidence**. See `STATUS.md` §5.

---

## The coach

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
      POST {baseUrl}/evaluate  (15s timeout)
           │
      Node proxy ──▶ OpenAI Responses API (strict json_schema)
```

`ResilientCoachService` catches **every** throwable from the primary, including
a `FormatException` from a malformed payload. That is deliberate: a bad
response degrades to offline scoring rather than interrupting a rehearsal. It
also means remote failures are invisible in the UI beyond the
`AI COACH` / `DEMO COACH` badge — worth remembering when debugging.

`OfflineCoachService` first tries a Jaccard token overlap against the authored
choices for the turn; above 0.2 similarity it borrows that choice's scoring.
Below that it falls back to keyword signals for each dimension. Employee
replies come from the next authored turn.

**The key never reaches the client.** `OPENAI_API_KEY` lives only in the server
environment. The Flutter app knows a URL and nothing else.

### Request shape

`POST /evaluate` takes `{sessionId, scenario, turn, history, managerResponse}`
and returns `{score_delta, feedback, clarity, empathy, courage, employee_reply}`.

One model call does both jobs — scoring and staying in character — inside
`max_output_tokens: 350`. The `sessionId` is hashed to a `safety_identifier`
and `store: false` is set, so no transcript is retained by the provider.

---

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

## Persistence

`shared_preferences`, wrapped so tests never touch a platform channel.

| Notifier | Store interface | Key |
|---|---|---|
| `PracticeHistory` | `PracticeHistoryStore` | `rehearse.practice_history` (string list of JSON) |
| `AppSettings` | `SettingsStore` | `rehearse.spoken_replies` (bool) |

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

Two shared widgets carry accessibility rules worth preserving:

- `MetaPill` ellipsizes its label, so a long string cannot overflow its card.
- `ScoreRing` grows with the text scale and caps both together at 1.4×, so
  scaled numerals stay inside the circle. It takes explicit colours, with an
  `onDark` variant for the progress banner.

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

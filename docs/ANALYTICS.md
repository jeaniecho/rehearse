# Analytics

The PRD §17 funnel, instrumented. Provider-agnostic by design: PostHog is
wired up, and swapping it is one class.

**Nothing here is required to run the app.** With no key every event is a
no-op.

---

## The rule that shapes the design

> Never send raw conversation contents to analytics. — PRD §16

This is enforced by the type system rather than by discipline. **No method on
`Analytics` accepts free text.** Every parameter is an id, an enum, a number,
or a boolean; the manager's response reaches the facade only as a character
count. Adding a `String` parameter to a tracking method is the one change that
should never pass review — it needs an enum or an id instead.

Two tests hold the line:

- A full free-form rehearsal is played with a distinctive phrase typed in, and
  every recorded payload is searched for it. The scenario's own prose and the
  authored choice text are checked too.
- Every string value emitted by the facade is asserted to be catalog metadata
  from a known allowlist.

---

## Events

Fired today, in funnel order.

| Event | When | Notable properties |
|---|---|---|
| `app_opened` | app start | — |
| `onboarding_started` | the intro is shown on first run | — |
| `onboarding_completed` | the intro is finished or skipped | `pages_seen`, `skipped` |
| `scenario_viewed` | the briefing is shown | `scenario_id`, `scenario_skill`, `scenario_stakes` |
| `scenario_started` | start is tapped and the gate passes | `mode`, `difficulty` |
| `difficulty_selected` | the resistance level is changed | `difficulty` |
| `simulation_started` | the conversation screen mounts | `difficulty`, `is_retry` |
| `retry_started` | as above, when `is_retry` | |
| `simulation_message_sent` | one manager turn is committed | `turn_index`, `response_length`, `coach` |
| `simulation_completed` | the conversation ends — the turns run out, or the simulation declares it resolved or broken down (PRD §9) | `turn_count`, `simulation_duration_seconds`, the four dimension scores, `score_band`, `outcome` |
| `retry_completed` | as above, when `is_retry` | |
| `simulation_abandoned` | the screen is left before the report | `turn_reached`, `simulation_duration_seconds` |
| `evaluation_viewed` | the coaching report is shown | scores, `score_band` |
| `paywall_viewed` | the paywall opens | `trigger`, `paywall_id`, `plan_count` |
| `paywall_dismissed` | it is closed without buying | `trigger`, `paywall_id` |
| `purchase_completed` | a purchase clears | `package_id`, `paywall_id` |
| `trial_started` | as above, when the plan had a trial | |
| `restore_completed` | restore finishes either way | `restored`, `from` |

### Super properties

Attached to every event, refreshed whenever entitlement changes:

`is_pro`, `billing_configured`

That means any funnel can be split by free versus Pro without threading state
through each call.

### Not yet emitted

These are in PRD §16 but the feature does not exist:

`reminder_created`, `notification_opened`

Add the event in the same commit as the feature, not before. An event that
never fires is worse than a missing one — it looks like a measured zero.

### Deliberate naming differences from the PRD

- **`score_band` and `outcome` are both sent, and they are not the same
  measure.** `score_band` buckets the score (`strong` / `solid` / `mixed` /
  `struggled`); `outcome` is PRD §9's success / partial / unresolved /
  escalated, judged on how the conversation ended rather than on how well it
  was handled. They disagree often, and that gap is the interesting one — a
  funnel that only had the band could not tell a manager who handled it well
  and still lost the room from one who did neither. This note used to say the
  simulation had no outcome model; it does now.
- **`scenario_skill`, not `scenario_category`.** Scenarios carry a skill, not
  a category.
- **`scenario_stakes` and `difficulty` are separate.** The first is how heavy
  the scenario is, authored. The second is how hard the manager asked the
  other person to push, chosen. Collapsing them would make "hard scenarios
  score worse" indistinguishable from "hard settings score worse".
- **`evaluation_requested` is folded into `simulation_message_sent`**, which
  already records the coach that scored the turn.
- **Setting the default pushback level on You is not an event.** The funnel
  cares about the level a rehearsal actually ran at, which `simulation_started`
  already carries. `difficulty_selected` stays what it is: a choice made about
  a specific scenario, on its briefing.
- **`trigger` and `from` say `settings`, and the tab is called You.** The
  plan card and Restore live on the You tab; the property values are named
  for the kind of surface rather than the label on it, so a copy change to
  the tab does not break a funnel. Values are `lockedScenario` /
  `homeUpsell` / `settingsUpsell` for `trigger`, and `paywall` / `settings`
  for `from`.
- **`lockedScenario` is the only forced paywall.** The free tier is two
  conversations rehearsed without limit, so nobody is ever stopped
  mid-habit — the paywall appears when they reach for a conversation the
  free tier does not include. `scenario_id` on the surrounding
  `scenario_viewed` says which one, which is the question worth asking of
  this funnel: what were people trying to open when they met the price.
- **There is no `free_sessions_remaining`.** It went when the free tier
  stopped being a count. Nothing had been sent to a live project yet, so no
  history was lost — which is the only reason the rename was cheap. After
  the first real event it would not have been.

---

## The funnel

PRD §17, and what to query:

```text
app_opened
   ↓
onboarding_completed     first-run completion
   ↓
scenario_viewed          browse rate
   ↓
scenario_started         commitment
   ↓
simulation_started
   ↓
simulation_completed     ← the activation metric
   ↓
evaluation_viewed
   ↓
simulation_started #2    ← secondary activation: the loop is compelling
   ↓
paywall_viewed
   ↓
purchase_completed / trial_started
```

`simulation_abandoned` carries `turn_reached`, which answers the roadmap's
"drop-off turn" question directly.

---

## Setup

1. Create a PostHog project (cloud or self-hosted).
2. Copy the **project API key** — the `phc_…` one. It is publishable and
   designed to ship in clients.
3. Run with it:

```bash
flutter run --dart-define=REHEARSE_POSTHOG_KEY=phc_xxxxxxxx
```

For EU cloud or self-hosted, add the host:

```bash
--dart-define=REHEARSE_POSTHOG_HOST=https://eu.i.posthog.com
```

Both platforms set `com.posthog.posthog.AUTO_INIT` to `false` in native
config, because setup happens from Dart with the build-time key. That is a
boolean, not a secret — **no key is ever committed.**

Autocapture, application lifecycle events, and session replay are all off.
Screens are named by the funnel above rather than guessed from the widget
tree, and replay would record what people type into a rehearsal.

---

## Swapping providers

`AnalyticsSink` is three methods. To move to Amplitude, Mixpanel, or Segment,
write one class and change `createAnalyticsSink()`:

```dart
abstract interface class AnalyticsSink {
  Future<bool> configure();
  Future<void> track(String event, Map<String, Object> properties);
  Future<void> setSuperProperties(Map<String, Object> properties);
}
```

No call site changes. The event names and properties above are the contract,
not PostHog.

---

## Behaviour without a key

| Situation | What happens |
|---|---|
| No `REHEARSE_POSTHOG_KEY` | `NoopAnalyticsSink`. Every call is silently dropped; `Analytics.isEnabled` is false. |
| Key present, setup throws | Same — caught, and the app starts normally. |
| A single event fails to send | Swallowed. Telemetry never interrupts a rehearsal. |

`flutter test` and the web preview never reach a network.

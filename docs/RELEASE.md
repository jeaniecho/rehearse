# Release

Everything between a green build and a submitted app. Drafted ahead of time
so none of it is discovered at 2am on deadline day.

Most of this is not done. The items marked ✅ are code and assets that exist
in the repo — Android signing is the only one verified end to end, against a
real `--release` bundle. Most unchecked boxes need an account, a certificate,
or a human decision; one needs code, and is called out as such.

---

## 1. Where things stand

| | |
|---|---|
| ✅ | Production bundle id `app.rehearse.rehearse`, both platforms |
| ✅ | Version `1.0.0+1` |
| ✅ | App icon, adaptive icon, themed icon, favicon, PWA icons |
| ✅ | Launch screen on both platforms |
| ✅ | Crash reporting wired ([§6](#6-crash-reporting)) |
| ✅ | Privacy policy and terms **live** at `jeanie.dev/rehearse-privacy` and `/rehearse-terms` |
| ✅ | Store copy drafted ([§3](#3-store-listing)) |
| ✅ | Screenshots generated ([§4](#4-screenshots)) |
| ✅ | Android release signing — verified against a real `--release` bundle |
| ❌ | iOS signing: distribution certificate and profile |
| ❌ | Store records created, metadata entered |
| 🟡 | Subscriptions: offerings return real prices; no purchase yet |
| ✅ | Terms of Use and Privacy Policy links on the paywall (Apple 3.1.2) |
| 🟡 | Coach server deployed and answering at `https://coach.example.invalid`, with `OPENAI_API_KEY` set as a secret and `ALLOWED_ORIGIN` live. Still needs `REHEARSE_COACH_URL` compiled into the release build |
| ✅ | iPhone-only (`TARGETED_DEVICE_FAMILY = "1"`), so no iPad review surface and no iPad screenshots |
| ✅ | Export compliance answered in Info.plist (`ITSAppUsesNonExemptEncryption = false`) |
| ❌ | TestFlight / internal testing build |

---

## 2. Before anything else

Four things gate everything downstream, in this order:

1. **Point the release build at the coach server.** It is deployed and both
   routes answer, but `REHEARSE_COACH_URL` has no default, so a build without
   it ships on the offline demo coach and the app does not do what §3's
   description says it does — silently, because `ResilientCoachService` falls
   back rather than failing. Everything in §9's "The product" checklist needs
   this define, and so does judging whether the prompts are any good.
2. **Legal pages — done.** `/rehearse-privacy` and `/rehearse-terms` are
   deployed and return 200 from the `jeanie-dev` repository, which Firebase
   serves from `react/dist`. Both stores need a reachable policy URL, and the
   paywall links both.
3. **Finish subscriptions.** [`REVENUECAT.md`](REVENUECAT.md) §2–4. Products
   sit in "Missing Metadata" until their localizations and review screenshot
   are filled in, and offerings come back empty until then — which looks
   exactly like a bug in the app. As of 2026-09-11 iOS offerings *do* return
   real prices, so this is mostly done; the gap is a completed purchase.
4. **Decide the free tier.** Currently the first conversation of each tier
   of stakes — `peer-conflict`, `missed-deadlines` and `say-no` — rehearsed
   without limit. It is one constant,
   `Subscription.freeScenarioIds`, and changing it later means shipping a
   build; changing the *price* does not, because that comes from RevenueCat.
   It replaced a lifetime count of three rehearsals, which a reinstall
   reset; see [`ARCHITECTURE.md`](ARCHITECTURE.md), "Why this is not a
   count".

---

## 3. Store listing

### Name and subtitle

```text
Name      Rehearse
Subtitle  Practice hard conversations
```

`Rehearse` is 8 characters, leaving room in the 30-character App Store name
field. The subtitle is 29 of 30.

### Promotional text (App Store, 170 max — editable without review)

```text
The conversation you have been putting off goes better when it is not the
first time you have had it.
```

### Description

```text
You know you need to have the conversation. You just do not know how to say
it without making things worse.

Rehearse is a practice room for the conversations managers avoid. Pick a
situation, choose how hard the other person pushes back, and have it — with
someone who reacts to what you actually say. Then find out where it went
wrong, in your own words.

PRACTICE, NOT ADVICE
Reading about difficult conversations does not prepare you for one. Four
minutes of rehearsing does. Every scenario is a real situation with a real
goal and a trap most people fall into.

THEY WILL NOT JUST AGREE
Choose calm, defensive, or very defensive. A vague message earns a vague
answer. Soften the expectation and watch it disappear. Nothing coaches you
mid-conversation, because nothing does in the room either.

SEE THE EXACT MOMENT
Afterwards you get a score for clarity, empathy, directness and confidence —
and the specific sentence that cost you, quoted back, with stronger wording
to use instead.

SEVEN SITUATIONS
· The slipping deadline — repeated missed commitments
· The impossible request — saying no to your director
· The tense teammate — repairing a strained relationship
· The feedback upward — telling your own manager something hard
· The promotion that isn't — delivering a no you promised would be a yes
· The brilliant difficult one — behaviour from someone you cannot lose
· The notice you didn't see coming — hearing a resignation well

PRIVATE
Your practice history never leaves your phone, and you can erase it whenever
you like. Nothing you say in a rehearsal is stored anywhere.

Rehearse is a coaching simulator. It is not HR, legal, or medical advice.
```

### Keywords (App Store, 100 characters, comma-separated, no spaces)

```text
manager,leadership,feedback,difficult,conversation,coaching,management,1on1,practice,communication
```

99 characters. Do not repeat words from the name or subtitle — the store
already indexes those.

### Play Store short description (80 max)

```text
Rehearse difficult work conversations before you have to have them for real.
```

### Category and age

| | App Store | Play |
|---|---|---|
| Primary | Business | Business |
| Secondary | Education | — |
| Rating | 4+ | Everyone |

Nothing in the app is objectionable, but the content questionnaires ask about
"infrequent/mild mature themes" — the scenarios are workplace conflict, which
is not a mature theme. Answer no to all of them.

---

## 4. Screenshots

```bash
flutter test tool/generate_screenshots.dart
```

Six 1290×2796 PNGs land in `build/screenshots/` — the exact size App Store
Connect requires for a 6.7" iPhone, and accepted by Play. The home and
progress shots are taken **through `TabsScreen`**, so the store sees the
tab bar the app actually has rather than a screen without one.

They are captures of the **real screens** with seeded data, not mockups, so
they cannot drift from the app. The generator loads the system font and the
Material icon font, because the test environment ships neither and without
them every glyph renders as a box.

> This used to work only on a Mac, because the generator borrowed the system
> typeface. The app bundles its own now, so the harness loads that instead and
> the output is identical on any machine. The run still warns and the images
> are still unusable if the bundled font fails to load.

Suggested captions, in order:

| File | Caption |
|---|---|
| `01-home` | The conversation you're avoiding |
| `02-brief` | Know the goal before you walk in |
| `03-practice` | They answer what you actually said |
| `04-report` | See the sentence that cost you |
| `05-progress` | Watch the habit build |
| `06-onboarding` | Practice before it matters |

Both stores also want a 6.5" set; scale the same images, or add the size to
`_size` in the generator and re-run.

**No iPad set is needed.** The app is iPhone-only as of 2026-09-13 —
`TARGETED_DEVICE_FAMILY = "1"`. Flutter's default is `"1,2"`, which would
have put the app in front of a reviewer on a 13" iPad, on a layout drawn for
a phone, and required an iPad screenshot set to submit at all.

---

## 5. App privacy answers

Answer these from what the app actually does. Getting them wrong is a
rejection, and getting them *loosely* wrong is worse — the answers are public.

### App Store Connect — App Privacy

**Data used to track you:** none. The app has no advertising identifier, no
ad SDK, and no cross-app tracking.

**Data linked to you:** none. There is no account, so nothing can be linked
to an identity.

**Data not linked to you:**

| Category | Collected | Purpose |
|---|---|---|
| Purchases | Purchase history | App functionality |
| Usage Data | Product interaction | Analytics, App functionality |
| Diagnostics | Crash data, performance data | App functionality |
| Other Data | Rehearsal text sent to the coach | App functionality |

Notes for the reviewer form:

- **"Other Data"** is the free-form text a person types or dictates during a
  rehearsal. It is transmitted to generate the reply and the feedback, is not
  retained, and is not linked to an identity.
- If you disable analytics for launch (ship without `REHEARSE_POSTHOG_KEY`),
  drop the Usage Data row. **Do not declare what you do not collect.**

### Google Play — Data safety

- **Does your app collect or share any of the required user data types?** Yes
- **Is all data encrypted in transit?** Yes
- **Do you provide a way to request data deletion?** Yes — in-app for practice
  history, and by email for analytics and crash records

| Type | Collected | Shared | Optional | Purpose |
|---|---|---|---|---|
| Purchase history | Yes | No | No | App functionality |
| App interactions | Yes | No | No | Analytics |
| Crash logs | Yes | No | No | App functionality |
| Diagnostics | Yes | No | No | App functionality |
| Other user-generated content | Yes | Yes¹ | No | App functionality |

¹ Rehearsal text is processed by OpenAI to produce the reply. Play counts a
third-party processor as sharing, so declare it.

### The microphone

Both stores ask why. The Info.plist strings are already written:

> Rehearse uses the microphone while you practice a response.
> Rehearse turns your spoken practice response into text.

Reviewers test this. Make sure dictation works on the review build, or note
in review notes that typing is always available.

---

## 6. Crash reporting

Sentry, behind the same interface pattern as everything else — no DSN means
no reporting and no behaviour change.

```bash
flutter run --dart-define=REHEARSE_SENTRY_DSN=https://…@…ingest.sentry.io/… \
            --dart-define=REHEARSE_ENVIRONMENT=production
```

Deliberately configured off:

| Setting | Why |
|---|---|
| `sendDefaultPii = false` | A crash report is for diagnosing a crash |
| `attachScreenshot = false` | A screenshot of the practice screen carries the transcript |
| `enableUserInteractionBreadcrumbs = false` | Same |

`attachViewHierarchy` would also carry it, and is off by default. It is left
alone rather than set explicitly because the API is still marked
experimental — **check it is still off** when upgrading the SDK.

It also reports one thing that is not a crash: **when the AI coach fails and
the offline coach takes over.** That degradation is invisible in the app
beyond a badge, which is right for the person practising and wrong for
whoever runs the service.

---

## 7. Signing

Neither platform can be signed from this repo — both need accounts and
private keys that must never be committed.

### iOS

1. Apple Developer Program membership.
2. In Xcode, Runner target → Signing & Capabilities: set the team, let Xcode
   manage signing.
3. Add the **In-App Purchase** capability (also required by
   [`REVENUECAT.md`](REVENUECAT.md)).
4. `flutter build ipa --dart-define=…` with every key from §8, then upload
   through Transporter or Xcode.

### Android

1. Generate an upload keystore. **Do not commit it, and do not commit
   `key.properties`** — add both to `.gitignore` before creating them.
2. `android/app/build.gradle.kts` reads the keystore from `key.properties`
   and falls back to the debug key only when it is absent. Done and verified
   against a real `--release` bundle.
3. `flutter build appbundle --dart-define=…`.
4. Enrol in Play App Signing.

---

## 8. Every key the release build needs

None of these are in the repo, and none should be.

```bash
flutter build ipa \
  --dart-define=REHEARSE_COACH_URL=https://coach.example.invalid \
  --dart-define=REHEARSE_REVENUECAT_IOS_KEY=appl_… \
  --dart-define=REHEARSE_REVENUECAT_ANDROID_KEY=goog_… \
  --dart-define=REHEARSE_POSTHOG_KEY=phc_… \
  --dart-define=REHEARSE_SENTRY_DSN=https://… \
  --dart-define=REHEARSE_ENVIRONMENT=production
```

A `--dart-define-from-file=release.json` is easier to get right. **Add it to
`.gitignore` the moment you create it.**

The one secret that must never appear in any of these is `OPENAI_API_KEY`.
That lives only in the coach server's environment. The app knows a URL.

---

## 9. Before you press submit

Run through this on a real device, on the build you are actually shipping:

**The loop**
- [ ] Fresh install opens on the intro, and finishing it lands on the home screen
- [ ] A guided rehearsal completes and produces a report
- [ ] A free-form rehearsal completes, with real replies from the coach
- [ ] The report quotes something you genuinely said
- [ ] All three difficulty levels produce visibly different pushback
- [ ] Retry works
- [ ] Aeroplane mode: the app still runs, on the offline coach

**Money**
- [ ] The three free conversations repeat without ever hitting a paywall
- [ ] A locked conversation opens its briefing, then paywalls on start
- [ ] Real prices load, not placeholders
- [ ] Sandbox purchase completes and unlocks
- [ ] Delete, reinstall, restore — Pro comes back, from the You tab, and the
      locked conversations are still locked until it does
- [ ] The transaction appears in RevenueCat

**Telemetry** — PostHog and Sentry both confirmed receiving, 2026-09-13
- [x] Events arrive in PostHog and the funnel is walkable
- [ ] No event contains anything anyone typed
- [ ] A deliberate crash arrives in Sentry — the DSN is verified and the app
      connects to the ingest host, but no error has yet been raised *by the
      app itself*, only sent to the project directly

**Presentation**
- [ ] Icon correct on the home screen, no white box behind it
- [ ] Splash matches the app's first frame
- [ ] Nothing overflows at the largest accessibility text size
- [ ] Privacy policy URL loads

---

## 10. Known gaps at submission

Say these out loud rather than hoping nobody notices.

- **The scenarios are 3 turns.** The PRD wants 4–7 with the model deciding
  when a conversation has resolved. Three is a complete rehearsal; it is not
  the full design.
- **No dark theme.**

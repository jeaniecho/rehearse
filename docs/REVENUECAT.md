# RevenueCat setup

The app-side integration is complete and tested. What remains is dashboard and
store configuration, which cannot be done from the repository.

**Nothing here is required to run or demo the app.** With no keys the app runs
unmetered and never shows a paywall — see [Behaviour without keys](#behaviour-without-keys).

---

## 1. What is already built

| PRD §13/§14 requirement | State |
|---|---|
| SDK added | ✅ `purchases_flutter` ^10.10.1 |
| `pro` entitlement | ✅ referenced as `RevenueCatKeys.entitlement` |
| Offerings fetched dynamically | ✅ never hardcoded prices |
| Paywall | ✅ `lib/screens/paywall_screen.dart` |
| Purchase flow | ✅ |
| Restore flow | ✅ on the paywall **and** the progress screen |
| Entitlement refresh | ✅ `addCustomerInfoUpdateListener`, so renewals and expiries arrive live |
| Cancelled purchase | ✅ treated as a normal outcome, no error shown |
| Unavailable offerings | ✅ retry state, never a dead end |
| Free session limit | ✅ 3 completed rehearsals, lifetime |
| Contextual paywall | ✅ opens on the pattern the person's own history shows |
| Sandbox purchase tested | ❌ **needs steps 2–5 below** |

---

## 2. RevenueCat dashboard

1. Create the project.
2. Add the iOS app with bundle id `app.rehearse.rehearse`.
3. Add the Android app with package `app.rehearse.rehearse`.
4. Create an entitlement with the identifier **`pro`** exactly — the app looks
   for that string, and a mismatch means purchases succeed while Pro never
   unlocks.
5. Create products and attach them to `pro`.
6. Create an offering, mark it **current**, and add packages. The app reads
   whatever packages the current offering contains, so `$rc_monthly` and
   `$rc_annual` need no code change.

### Suggested first packaging

From PRD §14, to be treated as a hypothesis rather than a decision:

| Package | Price | Notes |
|---|---|---|
| Monthly | ~$7–10 | |
| Annual | ~$40–50 | optional 7-day trial |

The paywall preselects annual when it exists, and shows the per-month price
alongside it. A free trial on a package is detected automatically and changes
the call to action to "Start my free trial".

### Paywall copy from the dashboard

The paywall reads three optional string keys from the **offering metadata**, so
wording can be changed and A/B tested without shipping a build:

| Key | Replaces |
|---|---|
| `headline` | "Keep going." |
| `subhead` | the personalized line derived from practice history |
| `cta` | the button label |

This is what makes roadmap §12 Experiment A a dashboard change rather than a
release. Leave `subhead` unset to keep the personalized copy, which is usually
stronger than anything generic.

---

## 3. App Store Connect

1. Create the auto-renewable subscriptions, matching the product ids used in
   RevenueCat.
2. Create a subscription group and fill in the localizations and review
   screenshot — subscriptions stay in "Missing Metadata" without them, and
   offerings will come back empty.
3. Generate an **In-App Purchase Key** and upload it to RevenueCat.
4. Add the **In-App Purchase** capability to the Runner target in Xcode.
5. Create a sandbox tester in Users and Access.

## 4. Google Play Console

1. Create the subscriptions with base plans.
2. Upload a build to a testing track — products do not activate until one
   exists.
3. Link the Play service account credentials to RevenueCat.
4. Add licence testers.

---

## 5. Running with keys

The public SDK keys are supplied at build time, the same way the coach URL is.
They are publishable client keys rather than secrets, but they stay out of the
repository so each environment can differ.

```bash
flutter run \
  --dart-define=REHEARSE_REVENUECAT_IOS_KEY=appl_xxxxxxxx \
  --dart-define=REHEARSE_REVENUECAT_ANDROID_KEY=goog_xxxxxxxx
```

For a release build, pass the same defines to `flutter build`. A
`--dart-define-from-file=keys.json` file is easier for CI — add it to
`.gitignore` if you create one.

### Every key the app reads

All of them are optional. With none set the app runs on the offline coach,
gates nothing, and reports nothing.

| Key | Absent means |
|---|---|
| `REHEARSE_REVENUECAT_IOS_KEY` | no gate, no counter, no paywall on iOS |
| `REHEARSE_REVENUECAT_ANDROID_KEY` | the same on Android |
| `REHEARSE_COACH_URL` | the on-device offline coach answers |
| `REHEARSE_POSTHOG_KEY` | analytics is a no-op sink |
| `REHEARSE_POSTHOG_HOST` | `https://us.i.posthog.com` |
| `REHEARSE_SENTRY_DSN` | crash reporting is off |
| `REHEARSE_ENVIRONMENT` | `development` |

### Not retyping them

`.vscode/launch.json` is committed, carrying placeholders. The RevenueCat SDK
keys are publishable rather than secret, so everyone starting from a config
that already runs is worth more than keeping the file out of the repository.

Replace the placeholders with your own, then stop git seeing the change:

```bash
git update-index --skip-worktree .vscode/launch.json
```

Without that the file shows as modified forever, and someone eventually
commits their own keys over the placeholders by accident. To edit the
committed version deliberately — adding a configuration, say — reverse it
with `--no-skip-worktree` first.

```jsonc
{
  "version": "0.2.0",
  "configurations": [
    { "name": "Rehearse (demo)", "request": "launch", "type": "dart",
      "program": "lib/main.dart" },
    { "name": "Rehearse (with keys)", "request": "launch", "type": "dart",
      "program": "lib/main.dart",
      "toolArgs": [
        "--dart-define=REHEARSE_REVENUECAT_ANDROID_KEY=goog_xxxxxxxx",
        "--dart-define=REHEARSE_REVENUECAT_IOS_KEY=appl_xxxxxxxx"
      ] },
    { "name": "Rehearse (with keys, release)", "request": "launch",
      "type": "dart", "program": "lib/main.dart", "flutterMode": "release",
      "toolArgs": [
        "--dart-define=REHEARSE_REVENUECAT_ANDROID_KEY=goog_xxxxxxxx",
        "--dart-define=REHEARSE_REVENUECAT_IOS_KEY=appl_xxxxxxxx"
      ] }
  ]
}
```

Three configurations, because the app has three states worth launching. The
demo path — no keys at all — is the one that has to keep working and is the
easiest to stop exercising once a key is in the file. The release one is
what §6 needs: a sandbox purchase cannot be completed in debug against a
simulator, and a release build additionally has no Dart VM service, which is
the usual way round a physical device refusing the debug connection.

> **Never commit a `sk_` secret key.** Those are server keys and have no place
> in a client at all.

---

## 6. Verifying a sandbox purchase

Once steps 2–5 are done:

1. Run on a real device with a sandbox account signed in. Simulators cannot
   complete StoreKit purchases.
2. Finish three rehearsals. The home screen counts down as you go.
3. Start a fourth. The paywall should appear on tapping start, not before.
4. Check that real store prices appear. Placeholder prices mean the offering
   is not current or the products are not approved.
5. Buy. The paywall should close and drop you straight into the rehearsal.
6. Confirm the transaction appears in the RevenueCat dashboard.
7. Delete and reinstall the app, then use **Restore purchases** on the progress
   screen. Pro should come back.

### If offerings come back empty

Almost always one of:

- the offering is not marked current
- products are still in "Missing Metadata" in App Store Connect
- the In-App Purchase Key was never uploaded to RevenueCat
- on Android, no build has been uploaded to a testing track yet

The app handles this correctly — it shows a retry rather than an error — but
nothing can be sold until it is fixed.

---

## Behaviour without keys

This matters for the demo and for anyone cloning the repo.

| Situation | What happens |
|---|---|
| No key for the platform | `isConfigured` is false. **No gate, no counter, no paywall, no plan card.** Unlimited rehearsals. |
| Web | Always unconfigured. RevenueCat Web Billing is a separate product and is not wired up. |
| Key present, SDK fails to configure | Same as no key — the failure is caught and the app runs free. |
| Key present, offerings fail to load | The gate still applies, and the paywall shows a retry state. |

This follows PRD §26 ("subscription unavailable → allow the core free
experience to continue") and the repo's standing rule that **the app must work
with no keys and no network**. It also means `flutter test` and the web
preview never touch a store.

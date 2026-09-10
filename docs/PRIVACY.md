# Rehearse — Privacy Policy

**Last updated: 11 September 2026**

> **Published at** <https://jeanie.dev/rehearse-privacy>, rendered from this
> file by `react/src/pages/terms/RehearsePrivacy.tsx` in the `jeanie-dev`
> repository. The two have to be changed together — this file is the source of
> truth for the wording, and the page is what the stores and the app link to.
>
> This describes the app as built. If you change what is sent anywhere, this
> file has to change in the same commit — `docs/RELEASE.md` says why that
> matters.

---

Rehearse is a practice app for difficult workplace conversations. You rehearse
with a simulated colleague and get feedback afterwards.

**There is no account.** We never ask for your name, email address, phone
number, employer, or the names of real people. Nothing you write is tied to an
identity, because there is no identity to tie it to.

---

## What stays on your device

All of the following is stored only on your phone, is never uploaded, and is
deleted when you delete the app:

- Your practice history — scores, skill breakdowns, dates, and which scenarios
  you rehearsed
- Your streak and progress figures
- Your preferences, including whether the other person's replies are spoken
  aloud and how much resistance you last chose
- How many free rehearsals you have used

You can erase your practice history at any time from the **You** tab. That
deletes it permanently from the device.

**We never store what you actually said in a rehearsal**, on your device or
anywhere else. The transcript exists only while the conversation is open, and
is gone when you leave it.

---

## What leaves your device

### The words you type or speak in a rehearsal

In free-form mode, each message you send is transmitted to the Rehearse coach
service so the simulated colleague can reply, and once more at the end of the
conversation so it can be scored. From there it is passed to **OpenAI**, which
generates the reply and the feedback.

- The request is marked so that **OpenAI does not retain it for training**
  (`store: false`).
- We send a **randomly generated, per-session identifier**, hashed before it
  leaves the server. It is not linked to you, your device, or any other
  session.
- The Rehearse coach service does not write your messages to a database or a
  log file. It passes them on and returns the answer.

OpenAI's handling of API data is described in their
[API data usage policy](https://openai.com/policies/api-data-usage-policies).

**In guided mode, nothing you choose leaves your device.** The conversation is
scripted and scored locally. The same is true whenever the app is running on
its built-in offline coach, which is what happens if the coach service is not
configured or cannot be reached.

### Speech

If you dictate a response, your device's own speech recognition converts it to
text. **On some devices and operating system versions this sends audio to
Apple or Google** to be transcribed, under their privacy policies rather than
ours. Rehearse never records, stores, or transmits audio itself.

Spoken replies are produced by your device's built-in text-to-speech voice.

Both are optional. Typing works everywhere, and the spoken replies can be
muted.

### Usage analytics

We record how the app is used so we can tell which parts work. Events are sent
to **PostHog**.

**No conversation content is ever included.** This is enforced in the code
rather than by policy: the analytics interface physically cannot accept free
text, and automated tests fail if a rehearsal's words appear in any event.

What an event can contain:

- Which screen or step was reached, and when
- Which scenario, by its fixed identifier — for example `missed-deadlines`
- Which resistance level and practice mode you chose
- How many turns a conversation ran, how long it took, and **how many
  characters** your message was — never the characters themselves
- Your scores
- Whether you have a subscription, and how many free rehearsals remain

Analytics is off entirely unless the app has been built with an analytics key.

### Purchases

Subscriptions are handled by **RevenueCat**, which records the purchase, its
status, and an anonymous identifier it generates. Payment itself is handled by
Apple or Google — **we never see your card details, billing address, or the
name on the account.**

### Crashes

If the app crashes we may receive a diagnostic report through **Sentry**: the
error, where in the code it happened, the device model, and the operating
system version. Reports are configured not to include personal data, and never
include conversation content.

---

## What we never do

- We do not sell your data.
- We do not share it with advertisers, and there is no advertising in the app.
- We do not build a profile of you, or use anything you write to train a model.
- We do not ask for contacts, photos, location, or your calendar.

---

## Permissions the app asks for

| Permission | Why |
|---|---|
| Microphone | Only to dictate a response, and only while you hold the conversation. Declining it leaves typing fully available. |
| Speech recognition (iOS) | To turn that dictation into text. |
| Bluetooth (Android) | So dictation works with a paired headset. |
| Internet | For the AI coach, purchases, and analytics. The app is fully usable offline without it. |

---

## Children

Rehearse is made for working adults and is not directed at children. We do not
knowingly collect anything from anyone under 13, or under the minimum age in
your country.

---

## Your rights

Because there is no account, most of your data is already entirely under your
control:

- **Practice history** — erase it in the app, from the You tab.
- **Everything on the device** — deleting the app removes all of it.
- **Analytics and crash reports** — email us and we will delete records
  associated with your installation.
- **Purchases** — managed through your Apple or Google account.

If you are in the UK, EU, or California, you have additional rights of access,
correction, deletion, and objection. Write to us and we will act on them.

---

## Changes

If this policy changes materially we will update the date at the top and note
the change in the app's release notes.

---

## Contact

Jeanie Cho
support@example.invalid

# Rehearse

Rehearse is a private practice room for difficult workplace conversations. It
helps new managers build confidence through short, branching simulations and
specific feedback on clarity, empathy, and courage.

## Contest MVP

- Three playable leadership scenarios: clear feedback, boundaries, and repair.
- A briefing before each conversation with context, goal, and a common trap.
- Three escalating decisions per scenario with immediate coaching.
- A final conversation score and skill-by-skill coaching report.
- A responsive Material 3 experience for iOS, Android, and web.
- Fully local scenario logic, so the demo is fast and reliable without an API
  key or network connection.

## Project structure

- `lib/data`: curated branching scenario content
- `lib/models`: scenario and response models
- `lib/screens`: home, briefing, simulation, and coaching report
- `lib/theme`: visual tokens and Material theme
- `lib/widgets`: shared layout and brand components

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
flutter analyze
flutter test
```

The next product step is to replace the curated response options with a
conversation service that accepts spoken or typed free-form answers while
preserving the same scenario and coaching models.

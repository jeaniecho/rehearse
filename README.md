# Rehearse

Rehearse is a private practice room for difficult workplace conversations. It
helps new managers build confidence through short, branching simulations and
specific feedback on clarity, empathy, and courage.

## Contest MVP

- Three playable leadership scenarios: clear feedback, boundaries, and repair.
- A briefing before each conversation with context, goal, and a common trap.
- Guided choices or typed free-form answers for every scenario.
- AI-personalized scoring and in-character replies through a secure server.
- Automatic offline coaching when the server is not configured or unavailable.
- A final conversation score and skill-by-skill coaching report.
- A responsive Material 3 experience for iOS, Android, and web.
- Fully local scenario logic, so the demo is fast and reliable without an API
  key or network connection.

## Project structure

- `lib/data`: curated branching scenario content
- `lib/models`: scenario and response models
- `lib/screens`: home, briefing, simulation, and coaching report
- `lib/services`: remote and offline coaching implementations
- `lib/theme`: visual tokens and Material theme
- `lib/widgets`: shared layout and brand components
- `server`: lightweight OpenAI Responses API proxy and tests

## Run

```sh
flutter pub get
flutter run
```

Without configuration, free-form mode uses the private on-device demo coach.
Guided mode is always available.

## Enable the AI coach

The OpenAI API key belongs on the server, never in the Flutter app or repository.

1. Set `OPENAI_API_KEY` in the server environment or secret manager.
2. Start the coach:

   ```sh
   cd server
   npm start
   ```

3. Point Flutter at it:

   ```sh
   flutter run --dart-define=REHEARSE_COACH_URL=http://127.0.0.1:8787
   ```

The server defaults to `gpt-5.6-sol` with low reasoning effort for responsive
turn-by-turn feedback. Override it with `OPENAI_MODEL` after evaluating quality,
latency, and cost. It listens only on `127.0.0.1` during local development;
deployment environments can set `HOST` and should restrict `ALLOWED_ORIGIN`.
For Android Emulator, use `http://10.0.2.2:8787` and set `HOST=0.0.0.0`
only on a trusted development network.

## Verify

```sh
flutter analyze
flutter test
cd server && npm test
```

The next product step is speech input and optional spoken character replies.

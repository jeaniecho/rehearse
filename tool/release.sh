#!/usr/bin/env bash
#
# One command to build a store-ready Rehearse, with every key read from
# release.json rather than typed out.
#
#   tool/release.sh ios        # .ipa, for Transporter or Xcode
#   tool/release.sh android    # .aab, for Play
#   tool/release.sh both
#   tool/release.sh check      # validate the keys, build nothing
#
# The checks below are not ceremony. `REHEARSE_COACH_URL` has no default and
# `ResilientCoachService` falls back silently, so a build missing it ships as
# the offline demo and nothing says so — not a crash, not a log, just an app
# that quietly is not the one the store listing describes.
set -euo pipefail

cd "$(dirname "$0")/.."

KEYS_FILE="release.json"
REQUIRED=(
  REHEARSE_COACH_URL
  REHEARSE_REVENUECAT_IOS_KEY
  REHEARSE_REVENUECAT_ANDROID_KEY
  REHEARSE_POSTHOG_KEY
  REHEARSE_SENTRY_DSN
  REHEARSE_ENVIRONMENT
)

target="${1:-both}"

die() { printf '\n  ✗ %s\n\n' "$1" >&2; exit 1; }
step() { printf '\n  %s\n' "$1"; }

if [[ ! -f "$KEYS_FILE" ]]; then
  die "No $KEYS_FILE. Copy the template and fill it in:
      cp release.json.example release.json
    It is gitignored. See docs/RELEASE.md §8."
fi

# Values are never printed — only whether they are there.
missing=$(python3 - "$KEYS_FILE" "${REQUIRED[@]}" <<'PY'
import json, sys
path, *required = sys.argv[1:]
try:
    keys = json.load(open(path))
except json.JSONDecodeError as error:
    print(f"!{path} is not valid JSON: {error}")
    raise SystemExit
absent = [
    name for name in required
    if not str(keys.get(name, "")).strip() or "xxxx" in str(keys.get(name, ""))
]
print(" ".join(absent))
PY
)

case "$missing" in
  "!"*) die "${missing#!}" ;;
  ?*) die "$KEYS_FILE is missing or still has a placeholder for: $missing" ;;
esac

environment=$(python3 -c "import json;print(json.load(open('$KEYS_FILE')).get('REHEARSE_ENVIRONMENT',''))")
[[ "$environment" == "production" ]] ||
  printf '\n  ! REHEARSE_ENVIRONMENT is "%s", not "production" — analytics and\n    crashes will land in the wrong bucket.\n' "$environment"

# A URL that is set but wrong fails exactly as silently as one that is absent,
# so it is asked whether it is alive before anything is built.
coach=$(python3 -c "import json;print(json.load(open('$KEYS_FILE'))['REHEARSE_COACH_URL'].rstrip('/'))")
step "Coach   $coach"
health=$(curl -fsS -m 20 "$coach/health" 2>/dev/null) ||
  die "The coach did not answer at $coach/health.
    A build made against a dead URL falls back to the offline demo coach
    without ever saying so. Fix the URL or deploy the worker first:
      cd server && npm run deploy"
printf '          %s\n' "$health"

step "Keys    $KEYS_FILE — all ${#REQUIRED[@]} present"
step "Version $(grep '^version:' pubspec.yaml | awk '{print $2}')"

if [[ "$target" == "check" ]]; then
  step "Check only. Nothing built."
  exit 0
fi

case "$target" in
  ios|android|both) ;;
  *) die "Unknown target '$target'. Use ios, android, both, or check." ;;
esac

# Nothing ships from a red tree.
step "Tests   analyze + flutter test"
flutter analyze >/dev/null
flutter test >/dev/null

if [[ "$target" == "ios" || "$target" == "both" ]]; then
  step "Build   ios"
  flutter build ipa --dart-define-from-file="$KEYS_FILE"
  printf '\n  ✓ build/ios/ipa/*.ipa — upload with Transporter or Xcode\n'
fi

if [[ "$target" == "android" || "$target" == "both" ]]; then
  step "Build   android"
  flutter build appbundle --dart-define-from-file="$KEYS_FILE"
  printf '\n  ✓ build/app/outputs/bundle/release/app-release.aab — upload to Play\n'
fi

printf '\n  Before submitting, walk docs/RELEASE.md §9 on this build.\n\n'

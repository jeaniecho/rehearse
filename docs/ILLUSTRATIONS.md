# Illustrations

The scenario marks and the app icon, and the prompts that produce them.

Keep this file in step with `art/illustrations/`. An image regenerated from
a half-remembered prompt is how a set stops looking like a set.

---

## 1. The style

**Layered paper cut-out collage.** Chosen from an eight-way board over soft
3D render, flat editorial, isometric vector, ink sketch, Bauhaus
abstraction, monoline and risograph.

It was picked because it reads as commissioned rather than generated, which
is the whole point of the exercise — an app about difficult workplace
conversations was being labelled with emoji, and emoji carry a levity the
subject cannot afford.

### The style block

Prepend this to every subject, unchanged. It is the reason the set looks
like one set: the camera, the light and the material never move.

```
Layered paper cut-out collage illustration. Visible paper edges and
thickness, soft drop shadows between the layers, slightly textured stock.
Gentle key light from the upper left, one soft contact shadow beneath.
Three-quarter view from slightly above, identical camera angle and
identical lighting for every image in this set. Single object, centred,
occupying about 80% of a square frame. Transparent background.

No text, no letters, no numbers, no faces, no hands, no logos.

Restrained professional palette only: deep green #17624A, charcoal
#3A342F, warm off-white #F7F5F1, light warm grey #E4E4E7, with one small
accent of muted amber #C8873A. No other colours, no bright saturation, no
glow, no sparkles.

Chunky simplified forms with few separate parts; no small details such as
wheels, casters, hinges or clasps.

Square, 1024x1024.
```

---

## 2. The eleven subjects

Append one line to the block above. Filenames are load-bearing — the code
looks them up by scenario id.

| File | Subject |
|---|---|
| `missed-deadlines.png` | A desk calendar block, its top page peeling and lifting away at one corner. |
| `say-no.png` | A stack of folders with one more folder hovering just above it, not yet placed. |
| `peer-conflict.png` | A flat disc torn cleanly into two halves, the halves slightly offset with a ragged tear between them. |
| `upward-feedback.png` | A small speech bubble rising toward a larger speech bubble above it. |
| `promotion-denied.png` | An open gift box with its lid lifted off and set beside it, the box clearly empty. |
| `high-performer.png` | A faceted cut gemstone on a flat base, one facet edge sharper than the rest. |
| `resignation.png` | A sealed envelope standing upright, a single door key leaning against it. |
| `delegation.png` | A shallow out-tray holding one thick sheet, the sheet sitting slightly proud of the tray as though just set down. |
| `empty-progress.png` | A bar chart with only the first, shortest bar present. |
| `pro-unlock.png` | An open padlock resting on its side, shackle lifted. |
| `logo.png` | Two overlapping speech bubbles, the left deep green and the right warm off-white, with a small muted amber bubble showing in the gap between them. |

The first eight are the scenarios, shown at 40pt in the home list and on
the briefing. `empty-progress` is the progress screen before the first
rehearsal, and `pro-unlock` heads the paywall; both are shown at 120pt.

`logo` is the mark in the `BrandMark` lockup — the app's own header, on
home, onboarding and the coaching report — at 44pt. It is the app icon's
subject drawn on a transparent ground, which is why the two look related
and why this one has no background of its own. It replaced a forest square
with a Material `forum` glyph in it; the wordmark beside it is still type.

### Two subjects that had to be replaced

Recorded so they are not proposed again.

**A step-ladder with a missing rung** was the first attempt at
`promotion-denied`. It renders as an ordinary step stool. The meaning lived
in an absence, and a style built entirely from positive shapes is the worst
possible one for drawing something that is not there.

**Two office chairs angled away from each other** was the first attempt at
`peer-conflict`. The model drew them facing, and the whole meaning was in
the angle. A relationship that subtle does not survive generation, let alone
40pt.

The rule both of them break: **put the meaning in the object, not in a
spatial relationship between objects.** A torn disc and an empty box each
say one thing on their own.

---

## 3. Export

- Square PNG, transparent background, 1024×1024 or larger. The set that
  shipped is 1254.
- Generate the whole set in one session so the model holds the style.
  Regenerate anything that drifts rather than accepting a near-miss; one
  off-style image makes the set look assembled.
- Check the detailed ones at size before committing to the set. At 40pt
  the difference between a gemstone and a grey blob is a few pixels.

### The masters do not ship

`art/illustrations/` holds them, outside the bundle, because together they
are about 12 MB — more than the rest of the app. What ships is cut from
them to the size each mark is actually drawn at, at the three pixel ratios
Flutter resolves:

```bash
flutter test tool/generate_illustrations.dart   # art/ -> assets/illustrations/
```

| | 1.0x | 2.0x | 3.0x |
|---|---|---|---|
| the seven scenario marks | 88px | 176 | 264 |
| `empty-progress`, `pro-unlock` | 120px | 240 | 360 |
| `logo` | 44px | 88 | 132 |

`Illustration.sizes` is the list, and the generator reads it, so the two
cannot disagree. That is 1.1 MB for the whole set.

The value is the size a mark is cut to, which is the **largest** it is drawn
anywhere — not the only size it is drawn at. Scenario marks appear three
times: 88pt on the home card for whatever is next, 56pt in the home grid,
40pt on the briefing. Downscaling is cheap and stays sharp, so one cut at the
top size serves all three; upscaling is what goes soft, which is why the cut
follows the largest use rather than the commonest.

Do not downscale by hand, and do not put a master in `assets/` — the
generator mipmaps, and a 1254 → 40 downscale done in one bilinear step
turns the paper texture into noise.

### Adding a scenario

Add the mark under `art/illustrations/`, named for the scenario id, add it
to `Illustration.sizes`, and re-run the generator. There is no path table to
update — `Illustration.scenario` builds one from the id — and
`test/scenarios_test.dart` fails until the master, all three variants, and
the scenario itself agree.

---

## 4. The app icon

Shipped. `assets/icon/app_icon.png` is the master; see
[`ARCHITECTURE.md`](ARCHITECTURE.md) for how it fans out.

An icon has to survive 29×29, so it is drawn more boldly than the
illustrations and its background is part of the artwork — the App Store
rejects an icon with an alpha channel.

```
A layered paper cut-out collage app icon. Two overlapping speech bubbles,
one deep green #17624A and one warm off-white #F7F5F1, with a small muted
amber #C8873A accent shape. Visible paper edges and thickness, soft drop
shadows between the layers, slightly textured stock.

The background is a SOLID warm off-white #F7F5F1 filling the entire square
edge to edge — fully opaque, no transparency anywhere.

Square 1024x1024. Perfectly square corners: no rounded corners, no circle,
no border, no frame, no outer shadow. The bubbles are centred and occupy
about 65% of the canvas, leaving generous even margins so nothing important
sits near a corner.

Bold simple shapes that stay readable when shrunk to 30 pixels. Keep the
paper texture subtle and fine — heavy grain disappears at small sizes. No
text, no letters, no numbers.
```

**Known limitation.** At 29pt — iOS Settings and Spotlight — the off-white
bubble merges into the off-white ground and the icon reads as a green
crescent with an amber sliver rather than as two bubbles. It holds at 60pt
and above. The fix is the same prompt on a deep green `#17624A` ground with
off-white and amber bubbles, which separates at every size. Worth trying
before submission.

Only the master is an illustration. The Android adaptive and themed layers
stay drawn by `tool/generate_app_icon.dart`, because both are flat by
definition and a rendered paper texture would only muddy them.

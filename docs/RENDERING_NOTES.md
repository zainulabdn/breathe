# Rendering notes

Things learned by running this on a device that are not obvious from the code.

## The Impeller inherited-opacity validation log

In debug builds you will see this, repeating per frame:

```
[ERROR:flutter/impeller/entity/contents/contents.cc(119)]
Contents::SetInheritedOpacity should never be called when
Contents::CanAcceptOpacity returns false.
```

**What it is.** Flutter has a peephole optimisation: rather than allocating an
offscreen layer for an `Opacity`/`FadeTransition`, it tries to push the alpha
down into the child's draw calls. `drawRawAtlas` with a `colors` array and a
blend mode — which is how every dot in this app is tinted and faded — declines
that, so the engine falls back to a `saveLayer`. The log is the engine
complaining that the caller asked before checking.

**What it costs.** Rendering is correct; the fallback path is the normal one.
The real cost is one offscreen render pass for the duration of whatever is
fading. Fine for a 400ms route transition, not fine for something animating
continuously.

**It is debug-only.** Impeller validation logs are compiled out of release
builds. Do not spend time trying to silence it in the log — spend it on the
cases where the `saveLayer` is actually in a hot path.

**Where we cared.** `HeroCarousel` dimmed its neighbouring cards with an
`Opacity`, which meant a `saveLayer` on every frame of every swipe. It now
draws a black scrim over the card instead — over a near-black page the two are
visually identical, and a scrim composites with no offscreen pass. The
remaining occurrences are route transitions and one-shot entrance fades, where
a single `saveLayer` is the right trade for simple code.

**Rule of thumb.** Fading a dot surface *continuously* → use a scrim, or fold
the alpha into the painter's own colours. Fading one *once* → `Opacity` is fine.

## Bloom must be a gradient sprite, not a scaled circle

`DotAtlas` carries two sprites: a hard-edged circle for dots, and a soft radial
gradient for bloom. Scaling the hard circle up and fading it does not read as
glow — at realistic dot spacings it resolves as a flat disc with a visible rim,
which on a black ground looks like a dark halo ring around every dot. This was
very visible on the onboarding dome before it was fixed.

Because the glow sprite falls to zero alpha at its rim, its bloom opacities look
alarmingly high next to the old values (0.42 vs 0.16). That is expected — peak
alpha is not average coverage.

## Additive blending rejects inherited opacity too

`BlendMode.plus` on the hero card's bloom had the same effect as the atlas case
above, for the same reason. Plain source-over with a slightly lower alpha looks
the same here and avoids it.

## Profiling is still owed

Everything above is reasoning plus visual inspection, **not** measurement.
Simulators only run debug builds — `flutter run --profile` refuses them outright
— so no frame timings exist for this app yet. The 120fps target in
ANIMATION_SPEC §0 is unverified until it runs on physical hardware.

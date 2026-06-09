# Design Specification

<!--
INSTRUCTIONS FOR HUMANS:
The design contract for everything user-facing — the UI peer of
ARCHITECTURE.md. Anything you leave unspecified, the agents fill with the
most generic plausible answer; the further down this file you specify, the
more the product looks like yours instead of theirs.

Three ways to use it:
- You have a design → fill this file (or paste a spec that covers the same
  sections) before starting the orchestrator. It is then the law for all UI.
- The product has a UI but you have no design → leave the template unfilled;
  the orchestrator drafts every section in the design phase (iteration 1,
  challenged by the same critic that attacks ARCHITECTURE.md) and you review
  it at the first-hour checkpoint.
- No UI → ignore this file; it stays inert.

Sections marked ★ must be filled — by you or by the design phase — before
any UI task is spawned. D0/D1/D5/D6 multiply consistency but may start thin.

How agents use it:
- Workers build UI from this file and never edit it — `integrate`
  mechanically refuses any branch that touches it.
- Where this file is silent, workers don't stop and don't ask: they
  extrapolate from the identity, principles, and tokens. The orchestrator
  then folds genuinely new shared components and tokens back into this
  file as they land (D4/D2 + Change log), so it always matches the built
  product. You are never asked to approve a component.
- The first UI task materializes §D2 verbatim as the project's token
  stylesheet and builds the §D4 base components; every later UI brief names
  the sections it implements.

Steer it like everything else: small design changes via FEEDBACK.md
## Inbox; identity-level changes by editing this file between runs.
-->

---

## D0 · Design identity

<!--
Two paragraphs at most: the single expressive idea the product is
recognized by, and the discipline around it.
- Name ONE signature element (an object, a typographic form, a layout move)
  and list where it appears.
- State what stays deliberately plain so the signature reads: chrome, how
  many colors, how much motion.
If there is no signature, write "none — strictly utilitarian" so agents
stop looking for one.
-->

-

---

## D1 · Design principles

<!--
5–8 numbered rules a worker can apply to a screen you never specified.
Operational, not aspirational: "every count appears with its unit in plain
words", not "clean and modern". Good principles decide real cases: what
earns the accent color, what is allowed to animate, which voice a string
belongs to, who owns the bottom of a mobile viewport.
-->

1.
2.
3.

---

## ★ D2 · Design tokens

<!--
THE single source of truth: every visual value in D3–D6 — and in the built
product — references a token defined here by name. Hardcoding a raw value
where a token exists is a defect; a genuine new need becomes a new token,
added by the orchestrator as it lands. Define every group in
one CSS block; comment each token with what it is FOR, not what it looks
like. State the theming rule (e.g. "dark overrides color tokens only") and
the webfont policy explicitly.
-->

```css
:root {
  /* ---- Type families ----
     Raw stacks plus SEMANTIC ALIASES that name roles, not typefaces
     (e.g. --font-app, --font-meta). Implementation uses the aliases only;
     give each alias one comment naming the kind of text it owns. */

  /* ---- Type scale ----
     Every size in the product, smallest to largest, each commented with
     its use — a size with no named use does not exist. Include line
     heights, weights, and letterspacing if used. */

  /* ---- Color ----
     Page background(s) and surfaces, text hierarchy, rules/borders, ONE
     accent (plus on-accent and wash variants), semantic verdict/status
     colors with washes, focus. Theme variants override these under an
     attribute selector (e.g. [data-theme="dark"]). */

  /* ---- Spacing ----
     One scale (e.g. --space-1..8). Every margin, padding, and gap comes
     from it. */

  /* ---- Radii & shadows ----
     Few levels; state what each is reserved for. */

  /* ---- Layout & ergonomics ----
     Content measures (reading and app widths), minimum hit-target size,
     and any signature structural value (indents, bar heights). */

  /* ---- Motion ----
     Durations and easing, each with its use. State the motion budget —
     what is ALLOWED to move — and the prefers-reduced-motion rule. */
}
```

**Breakpoints** — custom properties cannot be used inside `@media`; define the canonical constants here, write them literally in code, comment them `/* bp-* */`:

| Name | Value | What changes there |
|---|---|---|
| `bp-…` | | |

**Token usage rules**

<!-- The cross-cutting bindings workers get wrong when left to guess: which
family/size/color each recurring text role gets, the universal focus style,
the reduced-motion rule. One line each. -->

-

---

## ★ D3 · Screen specifications

<!--
Describe the GLOBAL SHELL first: navigation chrome, any full-screen
takeover patterns, page background, content max-widths. Then one subsection
per screen — every screen in scope, each using this skeleton:

### 3.N <Screen>
**Purpose.** One sentence: what the user comes here to do.
**Regions.** Numbered, top to bottom; every visual value names a D2 token.
**Layout sketch.** ASCII, mobile and desktop side by side — optional, but
it settles layout arguments cheaply.
**Responsive.** What changes at each D2 breakpoint.
**States.** All four, every screen: Empty · Loading · Error · Overflow
(too many items / too-long strings). Error states name what happened and
the next action.
-->

**Global shell.**

### 3.1

---

## ★ D4 · Component library

<!--
One subsection per shared component (PascalCase), each using this skeleton:

### <ComponentName>
**Anatomy.** Each part with its tokens — family, size, color, spacing,
border, radius, shadow. Every value names a D2 token.
**Variants / props.** Each variant and what changes with it.
**States.** default · hover · selected · disabled · focus · loading ·
error — whichever apply; anything interactive always defines focus.

Start with the signature object from D0, then the workhorses: buttons,
inputs, list rows, status/feedback elements, empty states. If a value
recurs across components, promote it to a D2 token.
-->

###

---

## D5 · Interaction & microcopy

<!--
The behaviors and words that make N screens feel like one product:
- Feedback choreography: a ms-by-ms timeline for the product's core
  feedback moment(s), naming D2 motion tokens — and what NEVER happens
  (sounds, bounces, layout shift).
- Keyboard map, if desktop matters: context · key · action table.
- Touch ergonomics: what owns each zone of the mobile viewport; where
  destructive actions live.
- Microcopy table: the FINAL strings for every recurring moment — empty
  states, verdicts, confirmations, errors. Workers copy them verbatim.
- Voice rules for strings the table doesn't cover: e.g. every error names
  what happened and the next action; nothing apologizes; buttons say
  exactly what they do.
-->

---

## D6 · Reference mockups

<!--
Optional. If static HTML/CSS mockups exist, list them: each embeds the D2
token block verbatim and uses D4 component names as kebab-case class names
so agents can map markup → component 1:1. Where a mockup exists it is the
styling source of truth; where none does, the D2–D5 text is.
-->

| File | Implements | Shows |
|---|---|---|
| | | |

---

## Change log

<!-- Kept by the orchestrator once the build is underway: one line per
amendment after the initial draft — date · what changed · why. This is how
the file stays in sync with the built product. -->

---

**Consistency rule.** D2 is the single source of truth: every visual value
in D3–D6 and in implementation references a D2 token by name — never a raw
value where a token exists. Genuinely new needs become new tokens, added to
D2 (+ Change log) as they land, so this file and the product never drift
more than one iteration apart.

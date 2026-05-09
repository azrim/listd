# 00 · Principles

## Design philosophy (applied)

NOVA's working principles, adapted to Listd's domain (single-user, local-first,
desktop-primary task manager):

1. **Reflex over thought.** Capture, complete, navigate — none of these
   should ever require deliberate UI scanning. Listd's two anchor
   keystrokes (`Ctrl+N`, `Ctrl+K`) are *the* product. The visual shell
   exists to teach users those keystrokes and stay out of the way after.
2. **Hierarchy is a system, not a paint job.** Surface depth, type weight,
   and spacing carry rank. Color is reserved for **state**, not
   **decoration**. The current implementation breaks this rule with the
   flame-orange "Today" pill, the flame underline on `mirzaspc@gmail.com`,
   and the warm cream brand wash — none of which encode state.
3. **Motion communicates causality.** Every animation answers
   "where did that come from?" or "where did that go?" — never "isn't
   this delightful?" Listd's single-spring rule from 2027 is correct;
   we keep it and add three named calibrations (`settle`, `flick`,
   `breathe`) so callers don't pick numbers.
4. **Reserve space for AI now.** Even if Listd has no AI features
   shipped, the 2027.x surfaces should leave a clean slot for streamed
   suggestions (date parsing preview, smart-list grouping, "this looks
   like a meeting" hint). The capture sheet is the obvious anchor.
5. **Adaptive, not animated.** The interface adjusts to time-of-day
   (already in `AppBackplate`), input modality (touch vs. mouse vs.
   keyboard), and density preference. It does not loop or breathe just
   to feel "alive."

## What we explicitly reject

- **Glassmorphism.** Already rejected in CLAUDE.md (one BackdropFilter
  total). We hold the line. The settings overlay moves from blurred
  modal → opaque side drawer (see §5 in `03_components.md`).
- **Hamburger menus.** Sidebar is persistent on desktop, drawer-style
  on Android only. No hamburger affordance in top bar.
- **Bottom navigation.** Listd is desktop-first; bottom nav is mobile
  cargo-culting.
- **Decorative icons.** Every icon must encode either an action or a
  semantic category. Stars on completed tasks earn their place
  (importance state). Sun-icon on "Today" earns its place (semantic
  category). The `lists` bookmark-icon next to user-created lists
  with literal names like "1" and "2" does not — see audit §3.
- **Multiple type families.** Inter + Newsreader is the lock. Two faces.
- **Multiple springs.** One spring, three calibrations.

## User-intent map per surface

What each surface is *hired to do* — phrased as a JTBD statement.

| Surface | Intent (verbatim) | Implication |
| --- | --- | --- |
| Today | "Show me what I said I'd do today, and let me knock it down." | Single column, dense, ranked by user-stars then due-time. Nothing else. |
| Inbox | "Park this thought now, sort it later." | Capture-first. The view itself is a queue, not a workspace. |
| Important | "Show me only what I marked as mattering." | Filtered view of all stars. Should never be empty if user actually stars things. |
| Planned | "Show me what's coming up so I can rebalance." | Time-grouped (Today / Tomorrow / This Week / Later). Currently broken — empty state ignores grouped scaffolding. |
| All Tasks | "Give me grep, with grouping by list." | Power-user view. Hide by default behind palette? See §6 in `03_components.md`. |
| List view | "This list, focused, with capture at the top." | Already correct in current implementation. We tighten density only. |
| Settings | "Change one thing about how Listd looks/syncs, then leave." | One-pane drawer, no nested modal. Auto-saves. Closes on Esc. |
| Capture sheet (Ctrl+N) | "Get this thought out of my head in <1 second." | Single field, parse-on-type, AI suggestion slot below. |
| Command palette (Ctrl+K) | "Get me to or do anything in two keystrokes." | Universal search + actions. Already correct in 2027 spec. |

## Interaction model

### Modalities, in priority order

1. **Keyboard.** First-class. Every action reachable in ≤ 2 keystrokes
   via palette. Hover-card affordances mirror keyboard equivalents.
2. **Mouse.** Right-click everywhere reveals the same actions as
   keyboard shortcut, in the same order, in the existing context menu
   (already shipped in PR #22 — keep that).
3. **Touch.** Android long-press == right-click. Swipe-right on a task
   = complete; swipe-left = star. Bottom sheet for context menu.

### State surfaces

The app has exactly five state surfaces a user might check:

1. **Sync.** Currently a pill. Currently *duplicated* (top right + sidebar bottom). We move to **one** location: bottom-left corner of the canvas, next to the page edge — out of foveal vision but always visible.
2. **Selection.** Current task is highlighted by a 2 px indigo focus ring, not a soft fill. Keyboard arrows move it.
3. **Hover.** A 1 px slate-200 border + slate-50 fill — never the accent. Accent fills are reserved for *selection*, not *hover*.
4. **Active list (in sidebar).** Soft indigo fill (8% alpha) on the row, indigo-600 text, no left rail.
5. **Pending writes.** Counted in the sync pill. Never blocks the UI.

### Choreography

Three rules, in order:

1. **Origin must be visible.** A new task slides in from the capture
   field. The capture field itself slides down from the top bar. The
   settings drawer enters from the right edge. Modals do not "fade in" —
   they have a direction.
2. **Collapse waits.** When closing the expanded task card or settings
   drawer, the closing motion waits 40 ms before unwinding so the
   collapse doesn't read as nervous. (Already in 2027 spec — keep.)
3. **Reduced motion is total.** With `MediaQuery.disableAnimations`,
   all springs become `Duration.zero`, all slides become opacity-only,
   and the calendar strip's "today pulse" stops entirely.

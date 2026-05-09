# Listd 2027 · Indigo Edition

A redesign plan for [azrim/listd](https://github.com/azrim/listd), authored by **NOVA**.
This package is a **design specification + image references**, not a code change.
A separate implementation PR is the next step once direction is approved.

> **TL;DR.** The current 2027 system (warm cream + flame/oat) is a stylistic
> dead-end for a productivity tool — it reads as a writing app, not a task
> system. We replace it with a cool **indigo + slate** palette anchored on
> perceptually-uniform OKLCH, retain the parts of 2027 that earned their
> place (single spring, layered surfaces, Inter + Newsreader, Phosphor
> icons, no glassmorphism), and rework five surfaces that the audit flags
> as friction: top bar, sidebar account block, calendar strip, expanded
> task editor, and settings overlay.

## Hero — the redesigned Today

![Today, light theme](mockups/png/01_today_light.png)

![Today, dark theme](mockups/png/02_today_dark.png)

## What's in this package

| Path | Purpose |
| --- | --- |
| `00_principles.md` | NOVA design philosophy applied to Listd. User-intent map per surface. Interaction model. |
| `01_audit.md` | Specific problems with the current implementation, citing the 12 screenshots you provided. |
| `02_tokens.md` | OKLCH-based color, type ramp, spacing/density, elevation, radius, focus, motion tokens. |
| `03_components.md` | Per-component redesign: shell, top bar, sidebar, calendar track, task card, inline editor, context menu, settings drawer, empty states, sync pill, command palette. |
| `04_motion.md` | Spring physics, named motion tokens, choreography rules, reduced-motion behavior. |
| `05_accessibility.md` | Contrast targets, focus order, keyboard map, reduced-motion, screen-reader semantics. |
| `06_migration.md` | Concrete file-by-file mapping from current `lib/theme/*` and widgets to the new system. The next implementation PR is mechanical. |
| `mockups/png/` | Rendered image references — light + dark, all major surfaces. |
| `mockups/raw/` | HTML/CSS source of the mockups (use to extract exact tokens). |

## Mockups — index

| # | Surface | File |
| --: | --- | --- |
| 01 | Today (light) | `mockups/png/01_today_light.png` |
| 02 | Today (dark) | `mockups/png/02_today_dark.png` |
| 03 | List view — Personal (light) | `mockups/png/03_list_view_light.png` |
| 04 | Task expanded · inline editor (light) | `mockups/png/04_task_expanded_light.png` |
| 05 | Settings drawer (light) | `mockups/png/05_settings_drawer_light.png` |
| 06 | Right-click context menu (light) | `mockups/png/06_context_menu_light.png` |
| 07 | Empty state · Inbox (light) | `mockups/png/07_empty_state_light.png` |
| 08 | Capture sheet · Ctrl+N (light) | `mockups/png/08_capture_sheet_light.png` |
| 09 | Token reference · color, type, space, radius, elevation, focus | `mockups/png/09_palette_reference.png` |
| 10 | Component states overview | `mockups/png/10_components_overview.png` |

## Quick navigation

- [Why we changed direction](./01_audit.md#summary)
- [The new color system](./02_tokens.md#color)
- [The redesigned task card](./03_components.md#5-list-view)
- [Migration plan](./06_migration.md)

## How to read the mockups

The mockups are HTML/CSS, not Figma — every visible color, radius, and
spacing value pulls directly from `_tokens.css` which is the literal
serialization of `02_tokens.md`. To extract a token, inspect any
mockup or open `mockups/raw/_tokens.css`.

## What the next session needs

The implementation PR will be mechanical given this package:

1. Run the migration in `06_migration.md`, PR-by-PR (Tokens → Surfaces → Editor).
2. Snapshot-diff each surface against the corresponding mockup PNG.
3. Run flutter analyze, dart format, and the existing test suite.
4. Verify reduced-motion, dark mode, and density toggle.

No additional design decisions remain. Push back on the spec — don't reinterpret it.

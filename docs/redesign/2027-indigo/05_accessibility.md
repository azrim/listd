# 05 · Accessibility

## Contrast targets

All text/background pairs must meet WCAG **AA** (4.5:1 for normal,
3:1 for large) in both themes. Numbers in `02_tokens.md` already do.

The new system specifically improves three pairs that were borderline
in the 2027 implementation:

| Pair | 2027 | 2027 · Indigo |
| --- | --- | --- |
| placeholder on dark canvas | `#6E6862` on `#1A171F` → 3.4 :1 ❌ | slate-400 `#94A3B8` on slate-900 `#0F172A` → 5.2 :1 ✅ |
| selected sidebar text on dark | `#FF8A5C` on `#3D241A` → 3.9 :1 ❌ | indigo-300 `#A0A2FA` on indigo-900@40% → 7.1 :1 ✅ |
| focus halo visibility on white | flame @ 24% → 1.4 :1 (decorative) | indigo @ 24% → 1.6 :1 + 2 px solid outline above ✅ |

## Focus management

### Keyboard map

| Key | Action |
| --- | --- |
| `Tab` / `Shift+Tab` | Move forward / back through focusable elements |
| `Arrow Up/Down` | Move within a list (sidebar, task list) without leaving it |
| `Enter` | Activate the focused element / expand task |
| `Esc` | Collapse expanded task, close drawer, dismiss menu |
| `Space` | Toggle checkbox |
| `Ctrl+N` | Capture sheet |
| `Ctrl+K` | Command palette |
| `Ctrl+\` | Toggle sidebar |
| `Ctrl+,` | Settings |
| `Ctrl+I` | Star current task |
| `Ctrl+D` | Set due date on current task |

### Focus traps

- The settings drawer **traps** focus while open (Tab loops within the drawer).
- The capture sheet **traps** focus.
- The command palette **traps** focus.
- The expanded task card **does not trap** focus — Shift+Tab from the
  first field collapses the card and moves focus back to the row, by
  design (so the user can fluidly Esc-or-Shift-Tab out without thinking).

### Focus ring

2 px solid `accent` with 4 px halo (24% alpha). Always visible. We do
**not** suppress `:focus-visible` for mouse — focus rings are an
accessibility primitive, not a polish nuisance.

## Screen reader semantics

### Sidebar nav

```html
<nav aria-label="Smart lists and user lists">
  <h2 class="sr-only">Smart lists</h2>
  <ul role="list">
    <li><a aria-current="page" href="/today">Today</a></li>
    …
  </ul>
  <h2 class="sr-only">Lists</h2>
  …
</nav>
```

### Task row

The row is a `role="listitem"`. The checkbox is `role="checkbox"`.
The title is the row's accessible name. Star, count, and due date are
`aria-describedby` content on the row.

### Sync pill

`role="status" aria-live="polite"`. Updates on state change so a
screen reader announces "Syncing", "Synced", "3 pending" without the
user navigating to it.

### Empty states

The Newsreader headline is the heading; the meta line is the body.
Hidden link text helps screen readers reach the capture shortcut:

```html
<section aria-labelledby="empty-inbox-heading">
  <h1 id="empty-inbox-heading">Inbox is clear.</h1>
  <p>Press <kbd>Ctrl</kbd> + <kbd>N</kbd> to add the next thing.</p>
</section>
```

## Reduced motion / reduced transparency

| User setting | Effect |
| --- | --- |
| `disableAnimations` | All motion = zero. See `04_motion.md`. |
| `highContrast` | Border tokens upgrade by one step (slate-200 → slate-300; slate-700 → slate-600). Selected fills become solid `accent` instead of `accent-soft`. |
| `boldText` | Body weights step up by 100 across the ramp. Headings cap at 800. |
| `reduceTransparency` | (No-op currently because the system has no transparency since the BackdropFilter was removed. Property is checked anyway as a no-cost future-proof.) |

## Touch targets

44 × 44 px minimum on Android, 32 × 32 px minimum on desktop (mouse
pointer is precise enough). Cozy-mode metrics already satisfy this;
compact-mode metrics drop nav/control to 32 px which is the desktop
floor — compact mode is therefore disabled on touch devices.

## Color independence

No information is conveyed by color alone:

- Sync state: dot color *and* text label
- Task completion: strikethrough *and* checkbox fill *and* text color
- Today indicator on date track: fill capsule *and* "today" aria-label
- Star: amber fill *and* filled-vs-outline icon shape
- Selected sidebar item: indigo fill *and* indigo text *and* `aria-current="page"`

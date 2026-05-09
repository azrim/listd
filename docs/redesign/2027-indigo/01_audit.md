# 01 · Audit of the current implementation

Source material: 12 screenshots provided 2026-05-09 + the live state of
`azrim/listd@main` (CLAUDE.md + `lib/theme/app_colors.dart` + recent PRs
#22, #23).

## Summary

The current 2027 system is a **stylistic mismatch** for a productivity
tool. Warm-cream surfaces and serif headlines belong on writing,
journalling, or reading apps (Bear, iA Writer, Stoic). Listd is a
*to-do list*. The dominant emotional read should be **clarity** and
**control**, not **calm coziness**.

Concrete problems below, indexed to the screenshots you sent.

## Findings

### 1. The brand colour does not encode state — it just decorates

**Screenshots 1, 2, 3, 5, 6, 7, 11**

Flame-orange `#FF6B35` appears on:

- "Today" sidebar row (selection)
- "Saturday 9" calendar cell (today indicator)
- The task starred-state icon
- The "Complete" pill button in the expanded task editor
- The user's email underline
- The "lists" sidebar item underline
- The "Listd" tab/breadcrumb underline
- The flame-soft fill on the active list pill in the sidebar

That is **eight different semantic uses** of one accent. A user cannot
tell at a glance whether orange means "selected", "today", "starred",
"primary action", "editable", or "you are signed in." The accent
silently degrades to wallpaper.

**Fix.** Indigo-600 = primary action + selection. Indigo-100 (light)
or indigo-900/40% (dark) = soft selection fill. **Stars** become
amber (semantic warm — single co-accent). Hyperlink underlines (email,
breadcrumb) get demoted to `text-secondary` or removed.

### 2. Sync state is duplicated

**Screenshots 1, 2, 3, 5, 6**

The "Synced ⟳" pill appears **twice** simultaneously: top-right of the
canvas header *and* bottom-left of the sidebar drawer. There is no
state difference between them — they show the same thing.

**Fix.** Single sync surface. Bottom-left corner, peripheral vision,
clickable for manual sync. Top right is freed for the user avatar
(already there) + a "..." More menu (currently absent and discoverability-broken).

### 3. The sidebar account block is overweight

**Screenshots 1–11**

The 64-px-tall account header (avatar + bold "Listd" + underlined
email) does three jobs poorly: workspace branding, account display,
and visual weight balance. The flame underline on `mirzaspc@gmail.com`
suggests the email is interactive — it isn't.

**Fix.** Avatar moves to the top-right corner of the canvas (already
present). The sidebar starts directly at "SMART" — no header. Workspace
branding is implicit (the OS window title already says `listd`).

### 4. The calendar strip reads as Excel cells

**Screenshot 1**

Seven sharp-cornered rectangles with a 1px border, equal weight, equal
size. Today is the orange-soft cell; the rest are white-on-cream. This
is a calendar grid pattern from 2014, not a 2027 productivity surface.

**Fix.** Replace with a **horizontal date track**: small dot + day
abbreviation, today is a single indigo capsule, future days fade
slightly using opacity (0.6). Total height drops from 88px to 56px.
See `mockups/png/02_today_light.png`.

### 5. Expanded task editor has unfocused field affordances

**Screenshots 3, 4**

When the card is collapsed, "besok" is a clean title. When expanded
(screenshot 3), the task body and steps look like static text
(`besok`, `erwf`, `123`) until you click — at which point underlines
appear (screenshot 4). The user has to *try* to discover whether a
field is editable.

**Fix.** Inline-editable fields show a 1-px slate-200 hairline
underneath at rest, which thickens to 2-px indigo-600 on focus.
Discoverability without modal state. (Reference: Things 3 task editor.)

### 6. The Steps subsection is structurally underbuilt

**Screenshot 3**

Steps render as: empty-circle + step text + (no edit affordance) +
"+ Add step" placeholder, with no count, no progress bar, no drag
handle, no completion ratio anywhere except the small `0/1` chip on
the collapsed card.

**Fix.** Steps render with: drag handle (left, hover-only), checkbox,
text, delete-on-hover (right). A **progress bar** sits between the
title and steps — 4 px tall, slate-200 track, indigo-600 fill — so the
user sees `2/5 done` without parsing the chip. See
`mockups/png/04_task_expanded_light.png`.

### 7. Settings overlay uses BackdropFilter blur

**Screenshots 8, 9**

The current settings overlay is the only allowed blur in the entire
app per CLAUDE.md. It works, but it's the most 2024-coded surface in
the app — frosted glass behind a centered card. The dark variant
(screenshot 9) is even more dated because the warm/cool tension of
the blur clashes with the neutral panel.

**Fix.** Settings becomes a **560 × full-height side drawer** anchored
to the right edge, opaque slate-100 panel, slide-in via `breathe`
spring (320 ms). The canvas behind dims to 40% slate-900. No
BackdropFilter. The CLAUDE.md "exactly 1 BackdropFilter" rule becomes
"exactly 0."

### 8. List headings render naked user content as H1

**Screenshots 7, 10, 11**

User-named lists "1", "2", "lists" appear as 24-px H1 headers. When
the user names a list `1`, their giant single digit is the page title.
This is a content-system problem masquerading as a design problem,
but design can mitigate.

**Fix.** Add a small all-caps `LIST` micro-label above the list name,
right-truncate the name at 32 chars with ellipsis, and render the
header at 22 px instead of 24 px. Empty list names fall back to "Untitled list."

### 9. Empty states are dead

**Screenshots 2, 5**

"Nothing in Inbox." and "Nothing in Planned." are dead-end strings.
Today's "A clear day. — Capture something with Ctrl + N — or just enjoy
it." is the **only** empty state in the entire app that knows what to
do with whitespace.

**Fix.** Every empty state gets:
1. A *Newsreader* declarative line ("Inbox is clear.")
2. A meta line that teaches the keystroke ("`Ctrl + N` to add the next thing.")
3. A subtle illustration slot (16-px Phosphor icon, slate-300, centered).

### 10. Dark mode contrast is uneven

**Screenshots 9, 10**

The settings overlay in dark mode (screenshot 9) is acceptable. The
list "2" view in dark mode (screenshot 10) has:
- "Add a task" placeholder almost invisible (text-tertiary on canvas)
- The single completed task `duaaa` strikethrough on a fill almost
  identical to the canvas
- The selected sidebar item "2" has a brown/red glow that looks like
  a CSS bug, not a design choice (`flame-soft-dark = #3D241A`)

**Fix.** New dark palette uses indigo-400 on slate-900. Selection fill
is indigo-900 at 40% alpha — produces a recognizable indigo wash, not
a brown smear. Placeholder text moves to slate-400 (was slate-500 / `_dTextTertiary`).

### 11. "Sign out" is one tap from the primary nav

**Screenshots 1–11**

The bottom of the sidebar shows `[Settings] [Sign out]` as equal-weight
buttons. Sign-out is a destructive action and does not deserve
primary-nav real estate. Accidental clicks happen.

**Fix.** Sign-out moves to a confirmation step inside Settings →
Account. The sidebar bottom contains only the sync status pill and a
discreet "..." overflow button.

### 12. Top bar doubles "Listd"

**Screenshots 1–11**

The OS window title says `listd` (lowercase, OS chrome). Below it the
in-app top bar shows `[sidebar-toggle] [crest icon] Listd` underlined.
That's two app names within 80 px.

**Fix.** Top bar reads `[sidebar-toggle] [crest] [page-title]` — page
title is the active route ("Today", "Inbox", list name). The brand
"Listd" only appears in the OS title and in the About dialog.

---
name: Listd
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#474651'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#777682'
  outline-variant: '#c8c5d3'
  surface-tint: '#5654a8'
  primary: '#1a146b'
  on-primary: '#ffffff'
  primary-container: '#312e81'
  on-primary-container: '#9c9af4'
  inverse-primary: '#c3c0ff'
  secondary: '#4648d4'
  on-secondary: '#ffffff'
  secondary-container: '#6063ee'
  on-secondary-container: '#fffbff'
  tertiary: '#172245'
  on-tertiary: '#ffffff'
  tertiary-container: '#2d385c'
  on-tertiary-container: '#97a2cc'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2dfff'
  primary-fixed-dim: '#c3c0ff'
  on-primary-fixed: '#100563'
  on-primary-fixed-variant: '#3e3c8f'
  secondary-fixed: '#e1e0ff'
  secondary-fixed-dim: '#c0c1ff'
  on-secondary-fixed: '#07006c'
  on-secondary-fixed-variant: '#2f2ebe'
  tertiary-fixed: '#dbe1ff'
  tertiary-fixed-dim: '#bac5f0'
  on-tertiary-fixed: '#0d1a3c'
  on-tertiary-fixed-variant: '#3a456a'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  display:
    fontFamily: Manrope
    fontSize: 48px
    fontWeight: '800'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  h1:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.3'
    letterSpacing: -0.01em
  h2:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: -0.01em
  h3:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  body-sm:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  label-md:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '600'
    lineHeight: '1'
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 8px
  container-max: 1200px
  gutter: 24px
  margin-page: 40px
  stack-sm: 4px
  stack-md: 12px
  stack-lg: 24px
  inset-squish: 8px 16px
  inset-stretch: 16px 24px
---

## Brand & Style

The design system for this productivity platform centers on the concept of "Structured Clarity." It is designed for high-performance professionals who require a tool that disappears into the background while maintaining a sense of reliable authority. 

The aesthetic is a refined blend of **Minimalism** and **Modern Corporate** styles. It prioritizes cognitive ease through the aggressive use of whitespace and a "content-first" architecture. Every element is intentional; there is no decoration for decoration's sake. The visual language conveys competence, calmness, and momentum, transforming the chaotic nature of task management into a serene, orderly experience.

## Colors

The palette is anchored by a sophisticated indigo spectrum. 
- **Deep Navy (#312E81):** Used for primary navigation, headings, and high-importance UI elements to establish trust and hierarchy.
- **Vibrant Accent (#6366F1):** Reserved for interactive states, call-to-action buttons, and progress indicators to draw the eye without fatigue.
- **Soft Grays:** A range of Slate and Blue-Gray tones are used for borders and backgrounds to prevent the harshness of pure black-on-white, maintaining a "paper-like" softness.
- **Crisp White:** The primary canvas color, maximizing contrast and perceived space.

Status colors (success, error, warning) should be slightly desaturated to align with the professional indigo base, avoiding neon or overly aggressive tones.

## Typography

This design system utilizes **Manrope** for all typographic needs. Its geometric yet humanist qualities provide the "technical-yet-friendly" balance required for a modern SaaS tool.

- **Headlines:** Use tighter letter-spacing and heavier weights to create a sense of importance and structure.
- **Body Text:** Standardized at 16px for optimal readability in data-heavy environments.
- **Labels:** Utilizes uppercase and tracking (letter-spacing) for micro-copy and metadata to distinguish it clearly from editable user content.
- **Hierarchy:** Established primarily through weight shifts (SemiBold to Regular) and indigo color tints rather than dramatic size changes.

## Layout & Spacing

The layout philosophy follows a **Fixed-Fluid Hybrid** model. While the main content containers have a maximum width of 1200px to maintain line-length readability on large monitors, the sidebars and navigation elements are fluid.

The spacing system is built on an **8px linear scale**. 
- **Margins:** Generous page margins (40px+) are encouraged to prevent the interface from feeling "cramped."
- **Grids:** Use a 12-column grid for dashboard views, but shift to a single-column centered layout for focused "Deep Work" task views.
- **Density:** Elements should have breathing room. Avoid dense clusters of data; use white space to separate groups of tasks rather than heavy lines.

## Elevation & Depth

Depth in this design system is achieved through **Tonal Layering** supplemented by ultra-soft ambient shadows.

1.  **Level 0 (Base):** The main application background (#FFFFFF or #F8FAFC).
2.  **Level 1 (Cards/Sidebar):** Raised slightly using a 1px border (#E2E8F0) and no shadow, or a 1px border and a very subtle Indigo-tinted shadow (5% opacity).
3.  **Level 2 (Popovers/Dropdowns):** Elevated using a more pronounced but diffused shadow: `0 10px 15px -3px rgba(49, 46, 129, 0.1)`.
4.  **Level 3 (Modals):** Maximum elevation with a dark backdrop overlay (40% opacity) to force focus.

Avoid heavy blacks in shadows. Shadows must always be tinted with the Primary Indigo to maintain color harmony and a clean, high-end feel.

## Shapes

The shape language is "Soft-Professional." By utilizing **Level 1 (Soft)** roundedness, the system avoids the childishness of fully rounded "pills" while moving away from the aggressive rigidity of sharp corners.

- **Standard Elements (Buttons, Inputs):** 4px (0.25rem) radius.
- **Large Elements (Cards, Modals):** 8px (0.5rem) radius.
- **Special Elements (Checkboxes):** 3px radius to keep them feeling precise yet accessible.

## Components

### Buttons
Primary buttons use the Deep Navy (#312E81) background with white text. Secondary buttons use a transparent background with an Indigo border and text. The "Ghost" button variant is used for low-priority actions, utilizing only text that turns Indigo on hover.

### Task Lists
Items in a list should be separated by whitespace and a very faint 1px bottom border (#F1F5F9). On hover, the entire row should transition to a subtle tint (#F8FAFC) to indicate interactivity.

### Checkboxes
A custom checkbox component is required. When unchecked, it is a thin indigo-gray outline. When checked, it fills with Vibrant Indigo (#6366F1) and displays a white checkmark, accompanied by a strike-through on the associated text in a muted gray tone.

### Input Fields
Inputs feature a 1px neutral border. Upon focus, the border shifts to the Vibrant Indigo with a 2px outer "glow" (a soft shadow with 0 blur and 10% opacity) to provide clear feedback.

### Chips/Tags
Tags for categorization use a "High-Light" style: a very pale indigo background (#EEF2FF) with deep indigo text. This keeps them legible but visually distinct from primary buttons.

### Progress Bars
Use a thin 4px height bar. The track is the light Neutral color, and the fill is the Vibrant Indigo accent. This maintains the "clean and focused" aesthetic without overwhelming the UI.
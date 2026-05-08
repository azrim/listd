---
name: Listd Dark
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#c8c5d3'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#918f9c'
  outline-variant: '#474651'
  surface-tint: '#c3c0ff'
  primary: '#c3c0ff'
  on-primary: '#272377'
  primary-container: '#312e81'
  on-primary-container: '#9c9af4'
  inverse-primary: '#5654a8'
  secondary: '#c0c1ff'
  on-secondary: '#1000a9'
  secondary-container: '#3131c0'
  on-secondary-container: '#b0b2ff'
  tertiary: '#ffb688'
  on-tertiary: '#512400'
  tertiary-container: '#5f2b00'
  on-tertiary-container: '#de915e'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e2dfff'
  primary-fixed-dim: '#c3c0ff'
  on-primary-fixed: '#100563'
  on-primary-fixed-variant: '#3e3c8f'
  secondary-fixed: '#e1e0ff'
  secondary-fixed-dim: '#c0c1ff'
  on-secondary-fixed: '#07006c'
  on-secondary-fixed-variant: '#2f2ebe'
  tertiary-fixed: '#ffdbc7'
  tertiary-fixed-dim: '#ffb688'
  on-tertiary-fixed: '#311300'
  on-tertiary-fixed-variant: '#70380b'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  h1:
    fontFamily: Manrope
    fontSize: 40px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  h2:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  h3:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
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
  label-md:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.4'
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
  container-margin: 24px
  gutter: 16px
---

## Brand & Style

This design system is a sophisticated, dark-mode evolution of a productivity-focused interface. It employs a **Modern Corporate** style with subtle **Tonal Layering** to create a focused environment for task management and list-making. The personality is professional, calm, and high-performance, designed to minimize eye strain during long periods of use while maintaining a premium, "night-owl" aesthetic.

The visual language emphasizes clarity and depth through the use of an "indigo-tinted charcoal" palette. By moving away from pure black and into deep blues, the interface feels more organic and less harsh, fostering a sense of "focused flow" for the user.

## Colors

The palette is anchored by a deep charcoal background with a distinct indigo undertone.

- **Primary Accent:** The signature indigo (#312E81) is reserved for high-priority actions and checkmarks, ensuring brand continuity.
- **Surface Strategy:** Depth is achieved through a "lighter-is-higher" approach. The base layer is #0F172A, while elevated containers use #1E293B and #334155.
- **Readability:** Text utilizes the Slate scale. High-emphasis text uses #F8FAFC (white-smoke) for maximum contrast without the vibration of pure #FFFFFF. Secondary text uses #94A3B8 to create a clear visual hierarchy.

## Typography

The design system exclusively uses **Manrope**, a modern geometric sans-serif that balances functional precision with a touch of warmth. 

Headlines use tighter letter spacing and heavier weights to command attention against the dark background. Body text is set with generous line heights to ensure long-form lists remain legible and scannable. Small labels use a medium weight to prevent the font from "thinning out" or disappearing against deep indigo backgrounds.

## Layout & Spacing

The design system follows a strict 4px/8px grid system. The layout model is a **Fluid Grid** with fixed maximum widths for desktop viewing to prevent line lengths from becoming unreadable.

- **Margins:** Standard screen padding is set to 24px (lg).
- **Stacking:** Vertical spacing between list items should be 8px (sm) to maintain a dense but organized feel.
- **Grouping:** Related sections are separated by 24px (lg) to 48px (xl) to create clear visual "islands" of content.

## Elevation & Depth

In this dark mode system, elevation is conveyed through **Tonal Layers** rather than traditional shadows. 

1. **Level 0 (Base):** #0F172A — The foundation of the application.
2. **Level 1 (Cards/Lists):** #1E293B — Used for the primary content containers.
3. **Level 2 (Modals/Popovers):** #334155 — The highest surface level for temporary UI elements.

To further define edges, a **Low-contrast outline** of 1px is applied to all Level 1 and Level 2 containers using a stroke of #334155 (or 10% opacity white). This provides a crisp "halo" effect that replaces the need for muddy shadows.

## Shapes

The shape language is defined as **Rounded**, providing a friendly and modern feel that softens the "technical" nature of dark charcoal interfaces.

- **Standard Elements:** Buttons, input fields, and small chips use a 0.5rem (8px) corner radius.
- **Large Containers:** Cards and main list areas use a 1rem (16px) radius to create a soft, enclosed feeling.
- **Selection Indicators:** Checkboxes and radio buttons maintain a slightly softer 4px radius or full circles respectively.

## Components

- **Buttons:** Primary buttons use the signature indigo (#312E81) with white text. Secondary buttons are "Ghost" style with a #334155 border.
- **Checkboxes:** When active, these should be filled with #312E81 and feature a crisp white check icon. When inactive, use a 2px stroke of #334155.
- **Input Fields:** Use the #1E293B surface color with a 1px border of #334155. Focus states should transition the border to #6366F1 (a brighter indigo variant).
- **Chips/Tags:** Small, rounded-pill containers with #334155 backgrounds and #94A3B8 text.
- **Lists:** Each list item should have a subtle separator line using #1E293B or be contained within a card. Hover states on list items should brighten the background slightly to #334155.
- **Progress Bars:** A background of #1E293B with a fill of the signature indigo (#312E81).
# Mockup index

All PNGs are rendered from the matching `.html` source in
`../raw/` via Playwright (Chromium, 2× device scale, 1448 × 952 viewport
unless full-page).

| # | File | Surface | Spec section |
| --: | --- | --- | --- |
| 01 | `01_today_light.png` | Today — light theme | `03_components.md` §4 |
| 02 | `02_today_dark.png` | Today — dark theme | `03_components.md` §4 |
| 03 | `03_list_view_light.png` | List view (Personal, light) | `03_components.md` §5 |
| 04 | `04_task_expanded_light.png` | Expanded task · inline editor | `03_components.md` §5–§6 |
| 05 | `05_settings_drawer_light.png` | Settings side drawer (no glass) | `03_components.md` §8 |
| 06 | `06_context_menu_light.png` | Right-click context menu | `03_components.md` §7 |
| 07 | `07_empty_state_light.png` | Empty state · Inbox | `03_components.md` §12 |
| 08 | `08_capture_sheet_light.png` | Capture sheet · Ctrl+N | `03_components.md` §9 |
| 09 | `09_palette_reference.png` | Token reference (full-page) | `02_tokens.md` |
| 10 | `10_components_overview.png` | Component states (full-page) | `03_components.md` |

## Re-rendering

```sh
cd mockups/raw
python3 render.py                # all files
python3 render.py 01_today_light.html  # one file
```

Requires `playwright` + `chromium` installed
(`pip install playwright && playwright install chromium`).

# Design QA

## Compared artifacts

- Source visual target: `C:\Users\86156\Documents\Codex\2026-09-01\new-chat\project-evolution-white-desktop.png`
- Rendered implementation: `C:\Users\86156\Documents\Codex\2026-09-01\new-chat\project-evolution-pages-zh-desktop.png`
- Side-by-side comparison: `C:\Users\86156\Documents\Codex\2026-09-01\new-chat\project-evolution-pages-qa-comparison.png`
- Viewport: 1440 x 1000, Chinese default home page
- Additional coverage: English desktop and Chinese mobile screenshots; full-page English scroll state

## Findings

- No actionable P0, P1, or P2 findings.
- Typography: the Chinese title is deliberately constrained to two lines and remained within its 563 px desktop column and 354 px mobile column. English uses the same hierarchy and wraps cleanly.
- Layout rhythm: the rendered page preserves the reference's white background, thin divider, two-column hero, loop diagram, summary strip, section sequence, and restrained 8 px visual radii.
- Colors: white, blue-gray, teal, and amber tokens match the approved preview direction with readable contrast.
- Assets: the interactive page preserves the approved layout and motion. README uses a high-resolution static SVG hero and dedicated bilingual loop PNG assets because GitHub does not run page CSS or JavaScript. The loop images use fixed safe positions, large text, and no non-clickable control appearance.
- Copy: Chinese is the default; the language control changes the full page copy to English. Both versions retain the all-project-types positioning.
- Interaction and responsive checks: the English switch updates document language, title, navigation, hero, loop labels, sections, and footer. Chinese mobile width has no horizontal overflow. All nine reveal blocks become visible after scrolling.

## Patches since the previous QA pass

- Replaced README Mermaid diagrams with stable raster loop diagrams.
- Replaced the README animated hero with a crisp static SVG to avoid misleading image-only controls.
- Restored the bilingual README loop diagrams using dedicated 2400 x 1280 GitHub-safe assets with all four nodes fully inside the canvas.
- Added the bilingual GitHub Pages home page and language switch.

## Final result

passed

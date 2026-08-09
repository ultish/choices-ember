# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.3] - 2026-08-09

### Fixed

- **daisyUI multi/text selected chips:** pair `--color-primary` (background) with `--color-primary-content` (label text) so light primaries (e.g. bumblebee, cupcake) keep readable contrast
- **Remove × icon** on multi/text chips: paint via CSS mask + `--color-primary-content` instead of the stock Choices SVG with hardcoded `#FFF` fill
- Disabled multi chips use base tokens so they no longer look “selected primary”

### Notes

- Token pairing is documented in `docs/design/THEMING.md` (`--choices-primary-color` / `--choices-item-color`)

## [0.1.2] - 2026-08-08

### Fixed

- npm Trusted Publishing (OIDC) release workflow: normalize `repository.url`, use a modern npm on the runner

## [0.1.1] - 2026-08-08

### Fixed

- Release packaging / CI auth path for Trusted Publishing

## [0.1.0] - 2026-08-08

### Added

- Initial **Embroider v2** monorepo (`choices-ember` + `test-app`) with TypeScript and `.gts`
- **`<Choices>`** reactive bridge for Choices.js `^11`
  - Modes: `@type="single" | "multiple" | "text"` (default `single`)
  - Controlled `@value` / `@onChange` with string coercion and `syncing` feedback-loop guard
  - Empty host element; options via `setChoices` (never dual-DOM + `refresh()`)
  - Nested tracked option fields read during mapping so labels update
  - `@disabled`, `@placeholder`, `@config`, `@syncKey`, `@class`
  - Escape hatches: `@onReady`, `@registerAPI`, `@onAdd` / `@onRemove` / `@onSearch` / dropdown events
  - Instance recreate on `@type`, `@theme`, and documented `RECREATE_KEYS` config changes
- **Themes:** `@theme="default" | "daisy" | "unstyled"`
  - Full daisyUI 5 `classNames` preset (`DAISY_CLASS_NAMES`)
  - Style exports: `choices-ember/styles/choices-default.css`, `choices-ember/styles/daisyui-theme.css`
- **`<ChoicesFieldset>`** daisyUI 5 fieldset chrome (composition only; optional Tailwind + daisyUI peers)
- Option **groups** (`InputChoice | InputGroup`), parent-owned **async** options pattern
- Design docs and phase checklists (`docs/`), agent guide (`AGENTS.md`)
- Guides: [REACTIVITY](./docs/design/REACTIVITY.md), [THEMING](./docs/design/THEMING.md), [COOKBOOK](./docs/COOKBOOK.md)
- Integration tests (single, multi, text, fieldset, groups, disabled, search, async, API, recreate)
- **test-app** demos: single/multi/text, groups, async refresh (keeps selection), nested tracked Person form, dependent selects + fieldset, daisyUI **theme selector**
- Glint **v2** (`@glint/ember-tsc`, `@glint/tsserver-plugin`); typecheck via `ember-tsc`

### Notes

- Peers: `ember-source >= 6`, `choices.js ^11`; optional `tailwindcss >= 4`, `daisyui >= 5`
- Out of scope: low-level `{{choices}}` modifier, function `@options` fetcher, structure-only CSS

[Unreleased]: https://github.com/ultish/choices-ember/compare/v0.1.3...HEAD
[0.1.3]: https://github.com/ultish/choices-ember/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/ultish/choices-ember/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/ultish/choices-ember/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/ultish/choices-ember/releases/tag/v0.1.0

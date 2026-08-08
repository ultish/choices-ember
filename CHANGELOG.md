# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

- Package version remains `0.0.0` until first publish
- Peers: `ember-source >= 6`, `choices.js ^11`; optional `tailwindcss >= 4`, `daisyui >= 5`
- Out of scope for this release: low-level `{{choices}}` modifier, function `@options` fetcher, structure-only CSS, npm publish

[Unreleased]: https://github.com/jxhui/choices-ember/compare/HEAD...HEAD

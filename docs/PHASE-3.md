# Phase 3 — daisyUI 5 theme + `<ChoicesFieldset>`

**Prerequisite:** Phase 2 complete ([PHASE-2.md](./PHASE-2.md)).  
**Goal:** opt-in daisyUI 5 look for Choices, plus a **separate** fieldset chrome component. Core `<Choices>` still works with stock CSS and **no** Tailwind/daisy installed.

Implementers: [DECISIONS.md](./DECISIONS.md); [ember-v2-addon-spec.md](./ember-v2-addon-spec.md) §§5.7–5.8, 9 (all), 12.

## Done when all boxes pass

### Dependency / packaging rules

- [x] `tailwindcss` and `daisyui` remain **optional peers** — **not** in addon `dependencies`
- [x] test-app installs real **Tailwind 4+** and **daisyUI 5** as normal deps
- [x] README documents: core works without daisy; Fieldset / `@theme="daisy"` require app pipeline
- [x] Tailwind `content` (or equivalent) includes addon dist/source so fieldset/preset classes are not purged — documented with example

### Theme presets on `<Choices>`

- [x] `@theme` arg: `'default' | 'daisy' | 'unstyled'`
- [x] **Default remains `'default'`** (stock Choices look)
- [x] `@theme="daisy"` merges daisy **classNames** preset ([spec §9.4](./ember-v2-addon-spec.md)) — keep BEM hooks Choices JS needs
- [x] `@theme="unstyled"` minimal hooks for apps that fully own utilities
- [x] `@class` merges into `classNames.containerOuter`
- [x] Changing `theme` / `classNames` → **recreate** instance (§6.3)
- [x] Ship `src/themes/daisy-class-names.ts` with **full** `ClassNames` keys filled (not a partial stub)

### CSS exports

- [x] Package `exports` for styles, e.g.:
  - `choices-ember/styles/choices-default.css` (or document import from `choices.js` CSS)
  - `choices-ember/styles/daisyui-theme.css` — **CSS variable map only** (`--choices-*` → daisy tokens); no daisy source
- [x] Document import order: Choices structure/skin → optional daisyui-theme → app Tailwind/daisy
- [x] Daisy theme CSS targets **daisyUI 5** token names (with fallbacks where reasonable)

### `<ChoicesFieldset>` component

- [x] New file: `src/components/choices-fieldset.gts`
- [x] Markup matches daisyUI 5 fieldset pattern:

  ```html
  <fieldset class="fieldset …">
    <legend class="fieldset-legend">…</legend>
    <!-- optional label class="label" -->
    <Choices @theme="daisy" … />
    <!-- optional p.label description -->
  </fieldset>
  ```

- [x] Args: `@legend`, `@label`, `@description`, `@fieldsetClass`, `@disabled`, plus **pass-through** of Choices args (`type`, `options`, `value`, `onChange`, …)
- [x] Named blocks optional: `legend`, `description`
- [x] Defaults `@theme="daisy"` on inner Choices; `@class="w-full"` (or equivalent)
- [x] Stable `id` for label `for` association when `@label` set
- [x] **No second bridge** — composition only
- [x] Exported from package entry + Glint registry
- [x] Works for single / multi / text via pass-through `@type`

### Theming gotchas (document + best-effort fix in preset)

- [x] Dropdown `z-index` high enough for daisy modals/drawers (document overflow-hidden trap)
- [x] Width: outer control fills form column (`w-full`)
- [x] Focus styles roughly align with daisy inputs (CSS var and/or classNames)
- [x] Multi tags usable with remove button under daisy preset

### Tests

- [x] **Fieldset renders** legend + description text in DOM
- [x] **Pass-through** — changing `@value` on Fieldset still updates selection (reuse bridge)
- [x] **Core without daisy** — `<Choices @theme="default">` still works in a context that doesn’t require daisy classes (existing Phase 1/2 tests)
- [x] Manual / optional: fieldset beside native `<input class="input">` in test-app (visual)

### Explicitly out of Phase 3

- Full Choices demo matrix (groups, remote, form reset) — Phase 4
- Perfect pixel match to native daisy `<select class="select">`
- Structure-only CSS extraction (nice-to-have later)
- ember-vitest

## Suggested files

```
src/components/choices-fieldset.gts
src/themes/daisy-class-names.ts
src/styles/daisyui-theme.css
src/index.ts                          # export ChoicesFieldset
test-app/                            # tailwind + daisyui 5
test-app/app/templates/…             # visual row: input + ChoicesFieldset
test-app/tests/.../choices-fieldset-test.gts
```

## Smoke manual check

```hbs
<ChoicesFieldset
  @legend="Charge code"
  @description="Search by name or id"
  @type="single"
  @options={{this.choiceOptions}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
  @fieldsetClass="bg-base-200 border-base-300 rounded-box border p-4 w-full"
/>
```

## Next

→ [PHASE-4.md](./PHASE-4.md) (demo parity + polish)

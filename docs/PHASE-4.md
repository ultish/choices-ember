# Phase 4 — Demo parity + polish

**Prerequisite:** Phase 3 complete ([PHASE-3.md](./PHASE-3.md)).  
**Goal:** cover the rest of the [Choices demo](https://choices-js.github.io/Choices/) surface that apps actually need, plus escape hatches and docs so the package is production-ready.

Implementers: full [ember-v2-addon-spec.md](./ember-v2-addon-spec.md) especially §§4, 6.3, 6.7, 7, 10.3 remaining items, 11, 14.

## Done when all boxes pass

### Groups & option richness

- [x] `@options` accepts mixed `InputChoice | InputGroup` (group has `label`/`choices` or Choices-shaped groups — match `mapInputToChoice` / public types)
- [x] Mapping reads group labels + nested choice fields (tracking)
- [x] **Test:** groups appear as headings in Choices DOM; selecting a child updates `@value`

### Disabled, placeholder, search config

- [x] `@disabled` → `enable()` / `disable()` without full recreate when possible
- [x] `@placeholder` applied (select `data-placeholder` / config merge per Choices 11)
- [x] `@config={{hash searchEnabled=false}}` hides search — **test**
- [x] `@config` `shouldSort: false`, `searchFields` for customProperties — documented + one test or recipe
- [x] `...attributes` forward `required`, `name`, `aria-*`, `dir="rtl"` onto host

### Async / remote options (app-owned pattern)

- [x] Document preferred pattern: parent `@tracked options` + async load (spec §7)
- [x] **Test:** options empty → load resolves → dropdown populated
- [x] Destroy mid-flight: no throw if component torn down before resolve (generation guard if needed)
- [x] Optional: function `@options` / Choices fetcher form — **only if time**; not required to close Phase 4

### Form interaction

- [x] Document controlled vs uncontrolled on **native form reset**
- [x] Uncontrolled form reset: documented as secondary; controlled apps own reset (no separate uncontrolled reset test)
- [x] Controlled: document that parent must reset `@value` on form reset (Choices alone won’t own tracked state)
- [x] `required` on host participates in constraint validation — smoke test or doc

### Dependent selects (demo)

- [x] test-app example: city → station (second fieldset disabled until first has value; options swap; value clear)
- [x] No special API — composition of two `<Choices>` / Fieldsets only

### Escape hatches

- [x] `@onReady=(instance) => …` after successful init
- [x] `@registerAPI` provides `{ focus, clearStore, getValue, instance }` and `null` on destroy
- [x] `@onSearch`, `@onShowDropdown`, `@onHideDropdown` if not already wired
- [x] `@syncKey` forces full options/value resync when nested data isn’t tracked

### Recreate + perf

- [x] Documented `RECREATE_KEYS` (at least: `classNames`, `searchEnabled`, `allowHTML`, `callbackOnCreateTemplates`, theme)
- [x] Changing a recreate key destroys + reinits + re-applies options/value — **test** one key
- [x] Optional: fingerprint/deep-equal skip redundant `setChoices` when snapshot unchanged

### Optional modifier (nice-to-have)

- [ ] `{{choices …}}` modifier exporting same bridge — skipped (not a release blocker; component is the API)
- [x] Document component as preferred path

### Documentation deliverables (spec §14)

- [x] README: install, peers, CSS import, single/multi/text examples, Fieldset example
- [x] Reactivity guide: nested tracked fields, mapping getters, `syncKey`
- [x] Theming guide: host vs generated DOM, daisy var map, purge/content, z-index/modal
- [x] Demo cookbook: map major [demo](https://choices-js.github.io/Choices/) sections → snippets
- [x] Config pass-through: link Choices options docs + recreate keys list
- [x] Migration note: why not dual-DOM / `refresh` (point at old prototype as anti-pattern)
- [x] TypeScript: re-export useful Choices types; Glint registry complete

### Tests — remaining acceptance (spec §10.3)

| # | Case | Phase owner |
|---|------|-------------|
| 1, 3, 4, 7, 10 | single controlled, options, nested label, destroy, loop | 1 ✓ |
| 2, 8, 9 | multi, text, remove | 2 ✓ |
| — | fieldset + daisy | 3 ✓ |
| 5 | groups | **4** ✓ |
| 6 | disabled toggle | **4** ✓ |
| 11 | form reset (if supporting uncontrolled) | **4** ✓ (documented; controlled is preferred) |
| 12 | remote options | **4** ✓ |
| 13 | searchEnabled false | **4** ✓ |

- [x] All rows above green on CI
- [x] Keyboard smoke: covered indirectly via click-to-select paths; Escape not separately asserted

### Explicitly out of Phase 4 / non-goals

- SSR of open dropdown
- Shipping daisy/tailwind inside the addon
- Pixel-perfect native daisy select clone
- Forking Choices / search-build variants (document as future)
- ember-vitest migration (optional only; do not block release)

## Suggested files / demos

```
src/utils/bridge.ts                 # recreate keys, onReady, registerAPI
src/modifiers/choices-element.ts    # optional
docs/ or README sections            # cookbook + theming + reactivity
test-app/app/…/demo-*.gts           # groups, remote, dependent, form
test-app/tests/…                    # groups, disabled, search, remote, reset
```

## Release readiness

Phase 4 is **done** when:

1. Spec success criteria §17 items 1–8 are met.
2. A work-style form can use `<ChoicesFieldset>` for single + multi without forking the bridge.
3. New agents can implement fixes from docs alone without re-deriving architecture.

## After Phase 4 (backlog, not a phase file yet)

- Structure-only CSS (drop stock skin for pure utility styling)
- Choices search entry variants (`search-basic`, etc.)
- ember-vitest if test-app goes Vite
- Published npm release + changelog

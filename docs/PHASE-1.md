# Phase 1 — Walking skeleton (acceptance checklist)

**Goal:** ship a minimal, correct reactive bridge for **controlled single select**. No fieldset, no multi/text, no daisy theme required.

Implementers: freeze [DECISIONS.md](./DECISIONS.md); follow [ember-v2-addon-spec.md](./ember-v2-addon-spec.md) §§2–3, 5.1–5.5, 6, 8, 10.3 items listed below.

## Done when all boxes pass

### Scaffold

- [x] pnpm monorepo from `@embroider/addon-blueprint` (TypeScript)
- [x] Package name `choices-ember`
- [x] `choices.js@^11` as peer (+ devDependency for tests)
- [x] `ember-source` peer `>= 6`
- [x] gts + Glint; export `<Choices>` from package entry
- [x] test-app can import and render the component

### Bridge / component

- [x] Host is **empty** `<select>` (no `{{#each}}` options)
- [x] Init: `new Choices(el, config)` once per element mount
- [x] Options: map snapshot (read `value`/`label`/…) → `setChoices(mapped, 'value', 'label', true)`
- [x] Value: controlled `@value` → `setChoiceByValue` with **syncing** guard
- [x] User change → `onChange` with string (or null) from `getValue(true)` when not syncing
- [x] Teardown: remove listeners + `instance.destroy()`
- [x] **Never** call `refresh()` for Ember option updates

### Tests (ember-qunit + @ember/test-helpers)

- [x] **Controlled value from outside** — change `@value` → UI selection updates; no spurious extra `onChange` loop
- [x] **Options replace** — new `@options` array → dropdown shows new labels
- [x] **Nested tracked label** — option object’s tracked display field changes → dropdown text updates (map must read the field)
- [x] **Destroy** — render then clear; no leftover `.choices` node errors; remount works
- [x] **Feedback loop** — parent sets `@value` inside `onChange` without infinite loop

### Explicitly out of Phase 1

- `<ChoicesFieldset>`, `@theme="daisy"`, multi, text, groups, remote fetch helper
- ember-vitest, structure-only CSS extraction
- Full demo parity

## Suggested first files

```
choices-ember/src/
  components/choices.gts
  utils/bridge.ts
  utils/map-options.ts
  utils/normalize-value.ts
  index.ts
  template-registry.ts
test-app/tests/integration/components/choices-test.gts
```

## Smoke manual check (test-app)

```hbs
<Choices
  @type="single"
  @options={{this.opts}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
  @placeholder="Pick one"
/>
```

With `this.opts = [{ value: '1', label: 'One' }, …]` and tracked `selected`.

## Next

→ [PHASE-2.md](./PHASE-2.md) (multi + text)

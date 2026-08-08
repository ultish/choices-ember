# Phase 2 — Multi-select + text mode

**Prerequisite:** Phase 1 complete ([PHASE-1.md](./PHASE-1.md)).  
**Goal:** extend the same bridge to **`@type="multiple"`** and **`@type="text"`** with correct controlled values and common Choices config (remove button, max items).

Implementers: [DECISIONS.md](./DECISIONS.md); [ember-v2-addon-spec.md](./ember-v2-addon-spec.md) §§4.1–4.2, 5.2–5.5, 6.4–6.5, 10.3 items 2, 8, 9.

## Done when all boxes pass

### Host element by type

- [x] `@type="single"` (Phase 1) — empty `<select>`
- [x] `@type="multiple"` — empty `<select multiple>`
- [x] `@type="text"` — empty `<input type="text">` (no `@options` list required)
- [x] Default remains **`single`** if `@type` omitted
- [x] Still **no** `{{#each}}` option children

### Value shape (controlled)

| `@type` | `@value` | `onChange` payload |
|---------|----------|--------------------|
| `single` | `string \| null` | `string \| null` |
| `multiple` | `string[]` | `string[]` |
| `text` | `string[]` (tags) | `string[]` |

- [x] Coerce all values to **string** at the boundary
- [x] Multi: programmatic update uses clear + `setChoiceByValue(values)` (or equivalent) under `syncing`
- [x] Text: programmatic update uses `setValue` / clear items APIs under `syncing` (verify against Choices 11 — do not invent)
- [x] User add/remove fires `onChange` only when not `syncing`
- [x] Wire `@onAdd` / `@onRemove` with `EventChoice` detail when provided (optional args, no-op if missing)

### Defaults (frozen)

- [x] `removeItemButton: true` for **multiple** and **text** unless overridden by `@config`
- [x] Single does **not** force remove button
- [x] `allowHTML: false` still default

### Config pass-through (smoke, not full matrix)

- [x] `@config={{hash maxItemCount=5}}` respected in text/multi
- [x] `@config={{hash removeItemButton=false}}` can disable remove UI
- [x] Other demo knobs (unique, paste, filter) work via `@config` without new args — document only

### Bridge / lifecycle

- [x] Same destroy path for all types
- [x] Switching `@type` on same component instance: **destroy + recreate** (type is init-level) — or document as unsupported and require remount; pick one and test it
- [x] `@options` ignored or no-op for `text` (no throw)
- [x] Nested tracked label mapping still works for multi options lists

### Tests (ember-qunit)

- [x] **Multi user select** — select two options → `onChange` with both string values
- [x] **Multi controlled from outside** — parent replaces `@value` array → chips/selection match; no loop
- [x] **Multi remove button** — remove one item → `onChange` with remaining values
- [x] **Text add tag** — type + enter (or Choices add path) → `onChange` includes new value
- [x] **Text maxItemCount** — config limit blocks further adds (or Choices notice; assert value length)
- [x] **Phase 1 tests still green**

### Explicitly out of Phase 2

- Groups, remote fetch helper, form reset policy, daisy theme, `<ChoicesFieldset>`
- `registerAPI` / `onReady` (Phase 4)
- Dependent selects demo page

## Suggested files to touch

```
src/components/choices.gts          # host element by type
src/utils/bridge.ts                 # multi + text value sync
src/utils/normalize-value.ts        # array vs scalar
test-app/tests/.../choices-multi-test.gts
test-app/tests/.../choices-text-test.gts
```

## Smoke manual check (test-app)

```hbs
{{! Multi }}
<Choices
  @type="multiple"
  @options={{this.opts}}
  @value={{this.selectedIds}}
  @onChange={{this.onMultiChange}}
  @config={{hash removeItemButton=true}}
/>

{{! Text / tags }}
<Choices
  @type="text"
  @value={{this.tags}}
  @onChange={{this.onTagsChange}}
  @config={{hash maxItemCount=5 removeItemButton=true}}
/>
```

## Next

→ [PHASE-3.md](./PHASE-3.md) (daisyUI theme + fieldset)

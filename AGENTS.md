# AGENTS.md — choices-ember

Instructions for coding agents (and humans) working in this repository.

## What this repo is

**`choices-ember`** is an Embroider **v2** Ember addon that wraps [Choices.js](https://github.com/Choices-js/Choices) with Ember autotracking, plus an optional daisyUI 5 fieldset wrapper.

- **npm package name:** `choices-ember`
- **Status:** design-first; implement against the docs below. Do not invent a different architecture.

## Read before you write code

In this order:

| Order | File | Purpose |
|------:|------|---------|
| 1 | [docs/DECISIONS.md](./docs/DECISIONS.md) | **Frozen** product/tech choices. Do not re-litigate. |
| 2 | [docs/ember-v2-addon-spec.md](./docs/ember-v2-addon-spec.md) | Full design: reactivity, API, bridge, theming, tests. |
| 3 | Phase checklist for the **active** phase (see below) | Concrete acceptance criteria |
| 4 | [README.md](./README.md) | Human-facing overview and local path references. |

### Phase checklists (all written)

| Phase | File | Scope |
|------:|------|--------|
| 1 | [docs/PHASE-1.md](./docs/PHASE-1.md) | Scaffold + controlled **single** select bridge + core reactivity tests |
| 2 | [docs/PHASE-2.md](./docs/PHASE-2.md) | **Multiple** + **text** modes, remove button / maxItemCount |
| 3 | [docs/PHASE-3.md](./docs/PHASE-3.md) | daisyUI 5 `@theme` + **`<ChoicesFieldset>`** (app owns Tailwind/daisy) |
| 4 | [docs/PHASE-4.md](./docs/PHASE-4.md) | Groups, disabled, remote pattern, forms, registerAPI, docs, release readiness |

If a task conflicts with `DECISIONS.md` or the **active** phase checklist, **stop and ask the human** — do not skip ahead or expand scope.

## Default task (unless told otherwise)

Implement **Phase 1 only** ([docs/PHASE-1.md](./docs/PHASE-1.md)):

- Controlled **single** select
- Empty host `<select>` + Choices owns option DOM
- `setChoices` / `setChoiceByValue` + events + `destroy()`
- ember-qunit integration tests listed in PHASE-1

Do **not** start Phase 2–4 until Phase 1 acceptance is green (or the human explicitly assigns a later phase).

## Hard rules (non-negotiable)

1. **No dual-DOM.** Never `{{#each}}` render `<option>`s and call Choices `refresh()`. That pattern is wrong.
2. **Data path:** Ember tracked data → plain snapshot → `setChoices` / `setChoiceByValue` / `setValue`. Events → `@onChange` / `@onAdd` / `@onRemove`.
3. **Nested tracked labels:** when mapping options, **read** `value`, `label`, `disabled`, group fields (etc.) so autotracking invalidates correctly.
4. **No side effects in getters** used for template data. Sync from modifier/resource/`modify` lifecycle.
5. **Always `destroy()`** the Choices instance on teardown; guard programmatic updates with a `syncing` flag.
6. **Do not package** `tailwindcss` or `daisyui` as addon dependencies. Optional peers; app (and test-app) own them.
7. **Peer `choices.js@^11`.** Prefer upstream types from the package; do not invent a full parallel typings tree.
8. **Value boundary:** coerce to **string** for selection APIs.
9. **gts + TypeScript + Glint.** Match modern v2 addon layout.

## Architecture snapshot

```
App tracked data
    │
    ▼
<Choices>  ── bridge ──►  Choices.js instance (owns DOM + store)
    ▲                         │
    └──── onChange / events ──┘

<ChoicesFieldset>  = daisyUI fieldset chrome + <Choices @theme="daisy">
                   (Phase 3+; not Phase 1)
```

## Local references (this machine)

| Path | Use |
|------|-----|
| `/Users/jxhui/Developer/Choices` | Upstream Choices source, public types, CSS vars, `classNames` |
| `/Users/jxhui/Developer/ember-choices` | Old prototype — **negative example only** (dual-DOM + `refresh` in getter). Do not copy the bridge. |

## How to work

### Scaffolding

If the monorepo is not scaffolded yet:

```bash
npx ember-cli@latest addon choices-ember \
  -b @embroider/addon-blueprint --pnpm --typescript
```

Then align package name, peers, and layout with the spec §5.1 and `DECISIONS.md`. Prefer implementing **inside this repo** rather than creating a sibling folder with a different name.

### Implementation order (Phase 1)

1. Scaffold / wire package exports.
2. `utils/map-options.ts` + `utils/normalize-value.ts` (pure; easy to unit-test).
3. `utils/bridge.ts` (init, sync options/value, events, destroy).
4. `components/choices.gts` (empty select + modifier/lifecycle attaching the bridge).
5. Integration tests in test-app per PHASE-1 checklist.
6. Stop. Summarize what passed / what’s left.

### Verification

- Run the test-app / addon test script after changes (`pnpm test` or workspace equivalent once scaffolded).
- Manually confirm: no `refresh(` for option updates; destroy path clean; controlled value does not loop.

### Commits

- Only commit when the human asks.
- Do not commit secrets; do not force-push.

## Package / peer facts (quick)

```json
{
  "name": "choices-ember",
  "peerDependencies": {
    "ember-source": ">= 6.0.0",
    "choices.js": "^11.0.0",
    "tailwindcss": ">= 4.0.0",
    "daisyui": ">= 5.0.0"
  },
  "peerDependenciesMeta": {
    "tailwindcss": { "optional": true },
    "daisyui": { "optional": true }
  }
}
```

- Default `@theme` on `<Choices>`: **`default`** (stock Choices CSS; no Tailwind required).
- daisyUI 5 + Tailwind: required only for `@theme="daisy"` and `<ChoicesFieldset>`.

## When unsure

1. Prefer **DECISIONS.md** over improvisation.
2. Prefer **smaller Phase 1** over building multi/fieldset “while you’re here.”
3. If the Choices API is ambiguous, inspect `/Users/jxhui/Developer/Choices` (types under `public/types`, implementation under `src/scripts/choices.ts`).
4. Ask the human before changing frozen decisions, public API shape, or peer ranges.

## Doc maintenance

If you change behavior that the docs describe, update the matching doc in the same change:

- New freeze → `docs/DECISIONS.md`
- API / bridge / theming → `docs/ember-v2-addon-spec.md`
- Phase scope / checklist → `docs/PHASE-1.md` (or a later `PHASE-N.md`)
- Agent workflow → this file

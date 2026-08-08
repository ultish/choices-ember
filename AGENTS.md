# AGENTS.md — choices-ember

Instructions for coding agents (and humans) working in this repository.

## What this repo is

**`choices-ember`** is an Embroider **v2** Ember addon that wraps [Choices.js](https://github.com/Choices-js/Choices) with Ember autotracking, plus an optional daisyUI 5 fieldset wrapper.

- **npm package name:** `choices-ember`
- **Status:** implement and maintain against the docs below. Do not invent a different architecture.

## Read before you write code

In this order:

| Order | File | Purpose |
|------:|------|---------|
| 1 | [docs/design/DECISIONS.md](./docs/design/DECISIONS.md) | **Frozen** product/tech choices. Do not re-litigate. (local; gitignored) |
| 2 | [docs/design/ember-v2-addon-spec.md](./docs/design/ember-v2-addon-spec.md) | Full design: reactivity, API, bridge, theming, tests. (local; gitignored) |
| 3 | [README.md](./README.md) | Human-facing overview and local path references. |

If a task conflicts with `DECISIONS.md`, **stop and ask the human** — do not expand scope or change frozen decisions.

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
```

## Local references (this machine)

| Path | Use |
|------|-----|
| `/Users/jxhui/Developer/Choices` | Upstream Choices source, public types, CSS vars, `classNames` |
| `/Users/jxhui/Developer/ember-choices` | Old prototype — **negative example only** (dual-DOM + `refresh` in getter). Do not copy the bridge. |

## How to work

### Verification

- Run the test-app / addon test script after changes (`pnpm test` or workspace equivalent).
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
2. Prefer the smallest change that matches existing API and architecture.
3. If the Choices API is ambiguous, inspect `/Users/jxhui/Developer/Choices` (types under `public/types`, implementation under `src/scripts/choices.ts`).
4. Ask the human before changing frozen decisions, public API shape, or peer ranges.

## Doc maintenance

If you change behavior that the docs describe, update the matching doc in the same change:

- New freeze → `docs/design/DECISIONS.md`
- API / bridge / theming → `docs/design/ember-v2-addon-spec.md`
- Agent workflow → this file

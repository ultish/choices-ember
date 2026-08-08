# Frozen decisions

**Do not re-open these unless the human explicitly changes them.**  
Recorded: 2026-08-08.

## Product / package

| Decision | Value | Notes |
|---|---|---|
| Repository | `choices-ember` | `/Users/jxhui/Developer/choices-ember` |
| npm package name | **`choices-ember`** | Not `ember-choices` |
| Language | TypeScript + **gts** | Glint for templates |
| Addon format | Embroider **v2** | `@embroider/addon-blueprint` |
| Package manager | **pnpm** | Workspace monorepo (addon + test-app) |
| Upstream widget | `choices.js` **^11** | Peer dependency; types ship with Choices |
| Package Tailwind/daisyUI? | **No** | Optional peers only; app pipeline owns CSS generation |

## Ember / tooling

| Decision | Value | Notes |
|---|---|---|
| Min `ember-source` peer | **`>= 6.0.0`** | |
| Component tests | **ember-qunit + @ember/test-helpers** | Blueprint-default path |
| Pure unit tests (map/normalize) | **Vitest (node)** optional | No ember-vitest required for Phase 1 |
| ember-vitest | **Out of scope for Phase 1** | Revisit only if test-app moves to Vite |

## Public components

| Decision | Value | Notes |
|---|---|---|
| Core API | **`<Choices>`** | All modes via `@type`: `single` \| `multiple` \| `text` |
| daisyUI chrome | **`<ChoicesFieldset>`** | Separate component; wraps `<Choices @theme="daisy">` |
| Low-level modifier | Optional later | Not Phase 1 |
| Default `@theme` on `<Choices>` | **`default`** | Stock Choices look; no Tailwind required |
| daisy theme | Opt-in `@theme="daisy"` or use Fieldset | Requires app Tailwind + **daisyUI 5** |
| daisyUI target | **v5** | `fieldset`, `fieldset-legend`, `label` per current docs |

## Reactivity / bridge

| Decision | Value | Notes |
|---|---|---|
| Option DOM ownership | **Choices only** | Empty host element; no `{{#each option}}` |
| Options API | `setChoices(..., replaceChoices: true)` | Not `refresh()` |
| Selection API | Controlled `@value` + `@onChange` preferred | |
| Value boundary | **Coerce to string** | Stable `setChoiceByValue` |
| Nested tracked fields | Bridge **must read** value/label/disabled/group when mapping | |
| Side effects in getters | **Forbidden** | Use modifier/resource sync |
| Feedback loops | `syncing` flag around programmatic set | |
| Async options Phase 1–2 | **Parent loads data** only | No function `@options` yet |

## Defaults

| Decision | Value | Notes |
|---|---|---|
| `allowHTML` | `false` | XSS |
| `removeItemButton` | `true` for multiple + text; single false unless config | |
| Fieldset chrome | Bare `class="fieldset"` | Card look via `@fieldsetClass` |
| CSS v1 | Full stock `choices.css` + optional daisy var bridge | Structure-only CSS later |

## Related code (do not copy blindly)

| Path | Use |
|---|---|
| `/Users/jxhui/Developer/Choices` | API, types, CSS variables, classNames |
| `/Users/jxhui/Developer/ember-choices` | Prototype only; dual-DOM + `refresh` in getter is **wrong** |

## Still flexible (implementer may choose)

- Exact class-based modifier vs resource for the bridge lifecycle (must re-run on arg invalidation and destroy cleanly).
- Fingerprint/deep-equal optimization (optional until perf hurts).
- Full `RECREATE_KEYS` list (start small: `classNames`, `searchEnabled`, `allowHTML`, `callbackOnCreateTemplates`).
- License / author metadata at publish time.

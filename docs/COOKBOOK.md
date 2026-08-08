# Demo cookbook

**Canonical cookbook is the live test-app**, not a separate gallery of black-box widgets.

```bash
pnpm start   # open the test-app
# or GitHub Pages: https://ultish.github.io/choices-ember/
```

Every section on that page has:

1. **Live** control (working Ember state)
2. **How to build this** — the recipe to copy (`test-app/app/templates/application.gts`)

## Sections

| Id | Recipe |
|----|--------|
| `#single` | Controlled single select |
| `#multiple` | Multiple + `@onAdd` / `@onRemove` / `@onChange` (live event log) |
| `#text` | Text / tags + same event wiring |
| `#events` | Event model + **live multi** log (`onChange` vs add/remove) |
| `#domain` | Domain / GQL models implementing `InputChoice` |
| `#groups` | Option groups (`InputGroup`) |
| `#no-search` | `searchEnabled: false` |
| `#async` | Entity-page async preselect (value-first or options-first; keep `@value` on refresh) |
| `#tracked` | Nested `@tracked` labels + edit form |
| `#dependent` | Dependent selects (clear child on parent change) |
| `#fieldset` | `<ChoicesFieldset>` daisy chrome |
| `#classnames` | Override `DAISY_CLASS_NAMES` via `@config.classNames` |
| `#escape` | `registerAPI` / `onReady` / recreate keys |

## Mental model (all recipes)

```
App tracked data  ──snapshot──►  setChoices / setChoiceByValue / setValue
App callbacks     ◄──events──  change / addItem / removeItem / …
```

- Empty host element — **no** `{{#each}}` options + `refresh()`
- Values coerced to **string** at the boundary
- Daisy CSS: import Choices + `daisyui-theme.css` in **`layer(components)`** (see README)
- Domain classes may `implements InputChoice` (`value` + `label`); or map GQL → plain choices in a getter

## Full Choices options

Pass any Choices 11 constructor option via `@config`.  
See [Choices setup](https://github.com/Choices-js/Choices#setup). Changing recreate keys rebuilds the instance: `searchEnabled`, `classNames`, `allowHTML`, `callbackOnCreateTemplates`, plus `@theme` / `@type`.

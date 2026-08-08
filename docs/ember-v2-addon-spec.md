# Spec: Ember v2 Addon for Choices.js

**Status:** draft — decisions frozen in [DECISIONS.md](./DECISIONS.md)  
**Repo / npm package:** `choices-ember`  
**Audience:** implementers (human or LLM) of an Embroider v2 / Glimmer addon that wraps [Choices.js](https://github.com/Choices-js/Choices)  
**Demo reference:** https://choices-js.github.io/Choices/  
**Choices version target:** `^11` (types + API as of 11.2.x)  
**Phase checklists:** [PHASE-1.md](./PHASE-1.md) · [PHASE-2.md](./PHASE-2.md) · [PHASE-3.md](./PHASE-3.md) · [PHASE-4.md](./PHASE-4.md)  
**Start order:** `AGENTS.md` / `README.md` → `DECISIONS.md` → this spec → active `PHASE-N.md`

---

## 1. Goal

Ship a modern **Ember v2 addon** that:

1. Exposes Choices as idiomatic Glimmer components (`.gts` + TypeScript).
2. Is **reactive** with Ember autotracking (array identity **and** nested tracked display fields).
3. Covers **all input modes shown on the Choices demo**:
   - Text / tags input
   - Single select (`select-one`)
   - Multiple select (`select-multiple`)
   - Option groups
   - Remote / async options
   - Remove buttons, max item count, uniqueness, filters, i18n labels, RTL, no-search, custom properties search, custom templates, form reset, form validation, dependent selects
4. Treats Choices as an **imperative widget**, not as something that shares option-DOM ownership with Glimmer.
5. Is **themeable** next to Tailwind + daisyUI without fighting Choices’ default BEM skin (see §9).

Non-goal: reimplementing Choices in Glimmer templates. The addon is a **reactive bridge**, not a fork.

---

## 2. Problem statement (why a careful bridge)

Choices is a vanilla library that:

- Wraps a native `<select>` or `<input>`
- Owns its own DOM (containers, lists, search input)
- Owns an internal store (choices / groups / items) with `setChoices`, `setChoiceByValue`, `setValue`, `getValue`, `refresh`, `destroy`, etc.
- Emits CustomEvents (`addItem`, `removeItem`, `change`, `search`, …)

Ember/Glimmer:

- Owns **tracked data** and re-renders based on **what was read** during a tracking context
- Must not fight Choices for option list DOM

### 2.1 Anti-pattern (do not do this)

```hbs
{{! ❌ Dual ownership }}
<select {{attachChoices}}>
  {{#each @options as |o|}}
    <option value={{o.value}}>{{o.label}}</option>
  {{/each}}
</select>
```

Then calling `instance.refresh()` from a getter / after render.

This appears to “wire tracking for free” because `{{#each}}` reads labels, but it creates:

- Two sources of truth (Glimmer option nodes vs Choices store)
- Side effects during render
- Broken destroy / re-render cycles
- Selection drift

### 2.2 Correct pattern

```
Ember tracked data  ──snapshot──►  setChoices / setChoiceByValue / setValue
Ember callbacks     ◄──events──  addItem / removeItem / change / …
```

Template hosts an **empty** element; Choices owns all choice UI after init.

---

## 3. Reactivity contract (required behavior)

### 3.1 Principles

1. **Choices never participates in autotracking.** It only receives plain snapshots.
2. **Something in Ember must read every field that should affect the widget** (value, label, disabled, group label, customProperties used for search, etc.) inside a tracking context.
3. When those reads invalidate, the bridge **re-snapshots** and calls Choices APIs.
4. **No side effects in getters** that also compute UI data for templates. Prefer: class-based modifier `modify()`, resource, or explicit sync method invoked from a lifecycle that re-runs on arg invalidation.
5. **Always `destroy()`** the Choices instance on element teardown.

### 3.2 Nested tracked properties

If options are domain objects with `@tracked` fields used as labels:

```ts
// ✅ Reads create the subscription
get choiceOptions(): InputChoice[] {
  return this.items.map((item) => ({
    value: String(item.id),
    label: item.name,       // tracked read
    disabled: item.disabled,
    customProperties: item.meta,
  }));
}
```

```hbs
<Choices @options={{this.choiceOptions}} @value={{this.selected}} @onChange={{this.onChange}} />
```

When `item.name` changes → getter re-runs → new array of plain objects → bridge `setChoices(..., replaceChoices: true)`.

**Naive bridge failure mode:**

```ts
// ❌ Only depends on array identity; nested label edits may not sync
modify(_el, _pos, { options }) {
  this.instance.setChoices(options, 'value', 'label', true);
}
```

**Required:** either document that callers must pass a mapping getter, **or** the addon maps/reads `value`/`label`/… inside the bridge so nested tracked fields are consumed.

### 3.3 Sync rules

| Ember change | Bridge action |
|---|---|
| First insert of host element | `new Choices(el, config)` → wire events → initial options + value |
| `@options` invalidates | Map → `setChoices(mapped, 'value', 'label', true /* replace */)` → re-apply controlled value |
| `@value` invalidates (controlled) | Suppress event echo → `setChoiceByValue` / clear → unsuppress |
| User selects / removes | If not syncing → `@onChange` / `@onAdd` / `@onRemove` with normalized value(s) |
| `@disabled` | `enable()` / `disable()` |
| Init-only config keys change | Destroy + recreate instance (see §6.3) |
| Element destroyed | Remove listeners → `destroy()` → drop refs |

### 3.4 Feedback loop guard

`setChoiceByValue` / `setValue` can emit events. Bridge must set a `syncing` (or equivalent) flag so outbound `@onChange` does not re-enter and thrash.

### 3.5 Array mutation semantics

Document clearly:

- Replacing the array / using tracked collections: supported.
- In-place `push` on a plain array: **not** observed (same as rest of Ember).
- Nested field updates: only if fields are tracked **and** read during snapshot (see §3.2).
- Escape hatch: `@syncKey={{this.version}}` increments force a full resync.

---

## 4. Demo parity matrix

Modes from https://choices-js.github.io/Choices/ mapped to addon surface.

### 4.1 Text inputs (`type="text"` host)

| Demo behavior | Choices config / API | Addon support |
|---|---|---|
| Limited to N values + remove button | `maxItemCount`, `removeItemButton` | `@config` + multi value |
| Unique values, no paste | `duplicateItemsAllowed: false`, `paste: false` | `@config` |
| Email (or custom) filter | `addItemFilter` | `@config` |
| Disabled | `disable()` / host `disabled` | `@disabled` |
| Prepend / append | `prefixValue` / `prependValue` / `appendValue` (per Choices defaults) | `@config` |
| Preset values | `items` or `@value` initial | controlled / uncontrolled |
| i18n labels | notice / item text fns | `@config` |
| RTL | `dir="rtl"` on host + CSS | `...attributes` |

### 4.2 Multiple select

| Demo behavior | Support |
|---|---|
| Default multi | `@mode="multiple"` or host `<select multiple>` |
| Remove button | `@config={{hash removeItemButton=true}}` |
| Option groups | `@options` as `InputGroup[]` mixed with choices |
| Remote fetch (limit N) | Parent loads **or** `@options` fetcher helper (see §7) |
| RTL | attributes |
| Use label in add/remove events | Bridge passes through `EventChoice`; document `label` vs `value` |

### 4.3 Single select

| Demo behavior | Support |
|---|---|
| Default + placeholder | `@placeholder`, config `placeholder` / `placeholderValue` |
| Remote fetch | §7 |
| Remote + remove button | config |
| Option groups | groups in `@options` |
| RTL | attributes |
| Options via config, no search | `@options` + `searchEnabled: false` |
| Groups via config | groups |
| Selected via config + customProperties | initial `@value` + options with `customProperties` |
| Search custom properties | `searchFields: ['label','value','customProperties.…']` via `@config` |
| No sorting | `shouldSort: false` via `@config` |
| Custom templates | `callbackOnCreateTemplates` via `@config` |
| Dependent selects | two components; parent disables / swaps `@options` / clears `@value` |

### 4.4 Form interaction & validation

| Demo behavior | Support |
|---|---|
| Native form reset | Choices listens for form reset; bridge must not fight — after reset, re-read value or re-apply `@value` policy (document controlled vs uncontrolled) |
| Required / validation | Keep native `required` on host element via `...attributes`; Choices keeps underlying control in form |

**Acceptance:** every demo scenario can be reproduced in the addon's test-app / docs with no direct `new Choices()` in app code (except advanced escape hatches).

---

## 5. Public API design

### 5.1 Package layout (Embroider v2)

Suggested monorepo (separate from Choices core unless you later monorepo it):

```
choices-ember/                 # npm package name: choices-ember
  src/
    index.ts
    components/
      choices.gts              # headless/core: Choices bridge only
      choices-fieldset.gts     # daisyUI 5 fieldset chrome around <Choices>
    themes/
      daisy-class-names.ts     # classNames preset (scanned by consumer Tailwind)
    utils/
      bridge.ts                # init / sync / destroy / event wiring
      map-options.ts           # domain → InputChoice | InputGroup snapshot
      normalize-value.ts
    modifiers/
      choices-element.ts       # optional low-level modifier
    styles/
      choices-default.css      # optional re-export / structure
      daisyui-theme.css        # CSS var bridge only (no daisy/tailwind source)
    template-registry.ts
  unpublished-development-types/
test-app/                      # has tailwind + daisyUI 5 as real deps for demos/tests
```

Scaffold with:

```bash
npx ember-cli@latest addon choices-ember \
  -b @embroider/addon-blueprint --pnpm --typescript
```

Use **gts**, Glint, `ember-modifier` (or resources). Peer **`ember-source` `>= 6.0.0`** (frozen).

### 5.2 Primary component: `<Choices />`

One component covering all host types, driven by `@type` (or inferred).

```ts
import type {
  Options as ChoicesConfig,
  InputChoice,
  InputGroup,
  EventChoice,
} from 'choices.js';
import type ChoicesInstance from 'choices.js';

export type ChoicesMode = 'text' | 'single' | 'multiple';

export type ChoicesOption = InputChoice | InputGroup;

export interface ChoicesSignature {
  Element: HTMLSelectElement | HTMLInputElement;
  Args: {
    /**
     * Host mode. Default: 'single'.
     * - text → <input type="text">
     * - single → <select>
     * - multiple → <select multiple>
     */
    type?: ChoicesMode;

    /**
     * Dropdown / selectable options (select modes).
     * Prefer plain snapshots; if passing tracked domain objects,
     * the bridge must read value/label/disabled/group fields.
     */
    options?: ChoicesOption[];

    /**
     * Controlled selection.
     * - single: string | null
     * - multiple / text: string[]
     */
    value?: string | string[] | null;

    /**
     * Called when selection changes due to user action (not bridge sync).
     */
    onChange?: (value: string | string[] | null) => void;

    onAdd?: (detail: EventChoice) => void;
    onRemove?: (detail: EventChoice) => void;
    onSearch?: (detail: { value: string; resultCount: number }) => void;
    onShowDropdown?: () => void;
    onHideDropdown?: () => void;

    disabled?: boolean;
    placeholder?: string;
    name?: string; // form field name on host element

    /**
     * Visual preset (see §9). Default: **'default'** (stock Choices look; no Tailwind required).
     * Does not replace CSS imports — pairs with them.
     * - 'default'  — stock Choices classNames; use choices.css / choices-default.css
     * - 'daisy'    — classNames tuned for daisyUI 5; use daisyui-theme.css (app must have daisy+tailwind)
     * - 'unstyled' — minimal hooks; app supplies utilities via @config.classNames
     */
    theme?: 'default' | 'daisy' | 'unstyled';

    /**
     * Extra classes merged into classNames.containerOuter
     * (useful for w-full, max-w-*, etc. without replacing the whole classNames map).
     */
    class?: string;

    /**
     * Pass-through Choices constructor options (merged over addon defaults).
     * Escape hatch for the full demo surface without re-typing every knob.
     * Includes classNames for full Tailwind control.
     */
    config?: Partial<ChoicesConfig>;

    /**
     * Force resync when nested data is not autotracked.
     */
    syncKey?: string | number;

    /**
     * Called once after successful init. Escape hatch for imperative APIs.
     */
    onReady?: (instance: ChoicesInstance) => void;

    /**
     * Register a small stable API for focus/clear without holding the raw instance.
     */
    registerAPI?: (api: ChoicesPublicAPI | null) => void;
  };
}

export interface ChoicesPublicAPI {
  focus: () => void;
  clearStore: () => void;
  getValue: (valueOnly?: boolean) => unknown;
  /** Advanced: raw instance; prefer not to use in app code */
  instance: ChoicesInstance | null;
}
```

### 5.3 Template shape

```hbs
{{#if (eq this.type "text")}}
  <input
    type="text"
    name={{@name}}
    disabled={{@disabled}}
    placeholder={{@placeholder}}
    {{this.attach}}
    ...attributes
  />
{{else}}
  <select
    name={{@name}}
    multiple={{if (eq this.type "multiple") true}}
    disabled={{@disabled}}
    data-placeholder={{@placeholder}}
    {{this.attach}}
    ...attributes
  ></select>
{{/if}}
```

**No** `{{#each @options}}` children. Empty host only.

### 5.4 Defaults

Addon-level defaults should be minimal and safe:

- `allowHTML: false` (Choices default; keep for XSS)
- `removeItemButton: true` for multiple/text (ergonomic; override via `@config`)
- `shouldSort: true` (Choices default; demos that need off pass config)
- `silent: false` in dev; optional

Merge order: `DEFAULTS ← @config ← derived from args` (`placeholder`, etc.).

### 5.5 Controlled vs uncontrolled

| Mode | Behavior |
|---|---|
| **Controlled** (recommended) | `@value` + `@onChange` always. Parent is source of truth. |
| **Uncontrolled** | Omit `@value` after mount; initial selection from options' `selected` / first paint. `onChange` still fires. |

Document that mixed “sometimes pass value” is undefined; pick one.

### 5.6 Low-level modifier (optional phase 2)

```hbs
<select {{choices options=this.opts value=this.val onChange=this.update}}></select>
```

Same bridge as the component. Component is the documented path; modifier for power users.

### 5.7 Component split: core vs fieldset (daisyUI)

Two public components — different jobs:

| Component | Responsibility | Depends on app having daisyUI? |
|---|---|---|
| `<Choices>` | Reactive Choices bridge only | No |
| `<ChoicesFieldset>` | daisyUI [fieldset](https://daisyui.com/components/fieldset/) chrome + legend/label + `<Choices @theme="daisy">` | **Yes** (and Tailwind) |

Do **not** bake fieldset markup into the core component. Apps that do not use daisyUI still get a clean primitive.

#### Markup target (daisyUI 5)

```html
<fieldset class="fieldset">
  <legend class="fieldset-legend">Page title</legend>
  <!-- Choices host lands here -->
  <p class="label">Helper / description</p>
</fieldset>
```

Optional bordered card variant from docs:

```html
<fieldset class="fieldset bg-base-200 border-base-300 rounded-box w-full border p-4">
  …
</fieldset>
```

#### `<ChoicesFieldset>` API

```ts
export interface ChoicesFieldsetSignature {
  Element: HTMLFieldSetElement;
  Args: {
    /** legend text (fieldset-legend) */
    legend?: string;
    /** description under the control (daisyUI .label paragraph) */
    description?: string;
    /** label above the control (daisyUI .label), when not using legend-only */
    label?: string;
    /** extra classes on <fieldset> (e.g. bg-base-200 border …) */
    fieldsetClass?: string;
    /** when true, set disabled on fieldset + forward to Choices */
    disabled?: boolean;

    // ── pass-through to <Choices> (same as §5.2) ──
    type?: ChoicesMode;
    options?: ChoicesOption[];
    value?: string | string[] | null;
    onChange?: (value: string | string[] | null) => void;
    onAdd?: (detail: EventChoice) => void;
    onRemove?: (detail: EventChoice) => void;
    placeholder?: string;
    name?: string;
    config?: Partial<ChoicesConfig>;
    syncKey?: string | number;
    onReady?: (instance: ChoicesInstance) => void;
    registerAPI?: (api: ChoicesPublicAPI | null) => void;
    // theme defaults to 'daisy' for this component
  };
  Blocks: {
    /** optional: custom legend / description slots if args are not enough */
    legend?: [];
    description?: [];
  };
}
```

#### Template sketch

```hbs
<fieldset
  class="fieldset {{@fieldsetClass}}"
  disabled={{@disabled}}
  ...attributes
>
  {{#if (has-block "legend")}}
    <legend class="fieldset-legend">{{yield to="legend"}}</legend>
  {{else if @legend}}
    <legend class="fieldset-legend">{{@legend}}</legend>
  {{/if}}

  {{#if @label}}
    <label class="label" for={{this.inputId}}>{{@label}}</label>
  {{/if}}

  <Choices
    @type={{@type}}
    @options={{@options}}
    @value={{@value}}
    @onChange={{@onChange}}
    @onAdd={{@onAdd}}
    @onRemove={{@onRemove}}
    @placeholder={{@placeholder}}
    @name={{@name}}
    @config={{@config}}
    @syncKey={{@syncKey}}
    @onReady={{@onReady}}
    @registerAPI={{@registerAPI}}
    @disabled={{@disabled}}
    @theme="daisy"
    @class="w-full"
    id={{this.inputId}}
  />

  {{#if (has-block "description")}}
    <p class="label">{{yield to="description"}}</p>
  {{else if @description}}
    <p class="label">{{@description}}</p>
  {{/if}}
</fieldset>
```

**This component is mostly styling/composition** — no second bridge. All reactivity lives in `<Choices>`.

Usage:

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

#### Accessibility notes for fieldset wrapper

- Prefer unique `id` on the host control + `@label` with `for` when using the label pattern (daisyUI multi-input fieldset pattern).
- `legend` is the group title; for a single control, either legend **or** label is fine — don’t force both.
- `disabled` on `<fieldset>` disables native descendants; still pass `@disabled` into Choices because the painted UI is Choices’ DOM, not the native select alone.

---

### 5.8 Styling dependencies: app-owned (not packaged)

**Yes — the correct choice is: the client app provides Tailwind + daisyUI. The addon does not package them.**

| Dependency | Who owns it | Why |
|---|---|---|
| `choices.js` | Addon **peerDependency** | Runtime widget; version must match types/API |
| `choices.css` (or structure CSS) | App imports (or optional addon re-export of **Choices** CSS only) | Needed for layout; not Tailwind |
| `daisyui-theme.css` (var map) | Optional addon stylesheet | Only maps `--choices-*` → existing CSS variables; zero daisy source |
| **Tailwind CSS** | **App** | Build pipeline, content globs, version |
| **daisyUI** | **App** | Theme tokens, `fieldset` / `label` / `input` classes |
| Class strings in `<ChoicesFieldset>` / daisy presets | Addon source | Harmless strings; **styles only appear if app’s Tailwind+daisy generate those utilities** |

#### Declare optional peers (document + package.json)

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

- **Optional peers:** installing the addon without daisy/tailwind still works for `<Choices @theme="default">`.
- **Required for `<ChoicesFieldset>` / `@theme="daisy"`:** app must have daisyUI + Tailwind configured; otherwise you get unstyled class names (no runtime crash).
- **Do not** `dependencies`-install `daisyui` or `tailwindcss` into the addon — that duplicates versions, breaks theme config, and cannot see the app’s `tailwind.config` / `@theme` / `content` paths.

#### Why packaging them would be wrong

1. daisyUI is a **Tailwind plugin** (or v4 CSS plugin), not a closed component runtime — it must run in the **app’s** CSS build.
2. Themes (`data-theme`, custom colors) live in the app; a bundled daisy copy would not use them.
3. Class purge/content scanning is app-level; bundled CSS either over-ships or misses utilities.
4. You already standardize on daisy in product apps — the addon should **compose** that system, not vendor a second one.

#### Consumer setup checklist (README)

1. App has Tailwind + daisyUI working (any existing daisy form control looks right).
2. Add addon package; peer `choices.js`.
3. Import Choices structure/skin CSS + optional `choices-ember/styles/daisyui-theme.css`.
4. Ensure Tailwind `content` includes the addon’s compiled gjs/gts (or source) so classes like `fieldset`, `fieldset-legend`, `label`, and daisy preset utilities are not purged:

   ```js
   // tailwind content (illustrative)
   content: [
     './app/**/*.{gjs,gts,hbs,js,ts}',
     './node_modules/choices-ember/dist/**/*.js',
     // or a dedicated safelist file the addon documents
   ],
   ```

5. Use `<ChoicesFieldset>` for form rows; use bare `<Choices>` when you bring your own chrome.

#### Layer diagram

```
┌─────────────────────────────────────────────┐
│  App: Tailwind + daisyUI theme pipeline     │
│  (generates .fieldset, .input, tokens, …)   │
└─────────────────────────────────────────────┘
          ▲ classes resolve at build time
┌─────────────────────────────────────────────┐
│  <ChoicesFieldset>  — markup + class names  │
│  <Choices @theme="daisy"> — bridge + preset │
│  optional daisyui-theme.css — var bridge    │
└─────────────────────────────────────────────┘
          ▲ peer
┌─────────────────────────────────────────────┐
│  choices.js + choices structure/skin CSS    │
└─────────────────────────────────────────────┘
```

---

## 6. Bridge implementation sketch

### 6.1 Module responsibilities

`utils/bridge.ts`:

- `createBridge(element, hooks) → { sync(args), destroy() }`
- Owns: `instance`, `syncing`, last options fingerprint, last value fingerprint, listener aborts

`utils/map-options.ts`:

- Walk options/groups
- **Read** `value`, `label`, `disabled`, `selected`, `placeholder`, `customProperties`, group `label`/`choices`
- Coerce `value` to string for stable `setChoiceByValue`
- Return pure JSON-safe structures

### 6.2 Init

```ts
const instance = new Choices(element, mergedConfig);
// Listen on the underlying element Choices wraps:
// addItem, removeItem, change, search, showDropdown, hideDropdown
// On user change → if (!syncing) onChange(normalize(instance.getValue(true)))
```

### 6.3 Config that requires recreate

Most demo flags are constructor-time. Practical policy:

- **Live-update without recreate:** options, value, disabled, placeholder (best-effort).
- **Recreate when these change:** `searchEnabled`, classNames, allowHTML, callbackOnCreateTemplates, position, item/choice limits that Choices doesn’t re-apply, and any key in a documented `RECREATE_KEYS` list.
- Implementation: hash recreate keys; if changed, `destroy()` + init again, then re-apply options/value.

### 6.4 Options update

```ts
if (type !== 'text') {
  // replaceChoices + replaceItems so selected-item labels update when nested
  // option fields change; re-apply controlled @value immediately after.
  instance.setChoices(mapped, 'value', 'label', true, true, true);
}
```

For text mode, options list is N/A; use `setValue` / items APIs for tags.

### 6.5 Value update

```ts
syncing = true;
try {
  if (multipleOrText) {
    instance.removeActiveItems();
    if (values.length) instance.setChoiceByValue(values); // or setValue for text
  } else {
    if (value == null || value === '') instance.setChoiceByValue([]);
    else instance.setChoiceByValue(String(value));
  }
} finally {
  syncing = false;
}
```

Exact APIs differ slightly for text vs select — implement with tests against Choices 11; prefer `getValue(true)` for normalized string(s).

### 6.6 Destroy

```ts
element.removeEventListener(...);
instance.destroy();
instance = undefined;
registerAPI?.(null);
```

### 6.7 Fingerprinting (optional perf)

Avoid redundant `setChoices` when snapshot deep-equals previous (value+label+disabled+group structure). Nested tracked updates that change labels will fail deep-equal and resync — good.

Do **not** use object identity alone as “unchanged.”

---

## 7. Async / remote options

Demo uses Fetch + `setChoices(async () => …)`.

**Preferred Ember pattern (explicit):**

```ts
@tracked options: InputChoice[] = [];
@tracked loading = false;

async load() {
  this.loading = true;
  try {
    this.options = await fetch(...).then(r => r.json());
  } finally {
    this.loading = false;
  }
}
```

```hbs
<Choices @type="single" @options={{this.options}} @value={{this.v}} @onChange={{this.onChange}} />
```

**Optional helper:** `@options={{this.loadOptions}}` where loadOptions is `() => Promise<InputChoice[]>` — bridge detects function, calls `setChoices(fn)`, handles loading state via Choices’ `_handleLoadingState` path. Cancel/ignore on destroy (generation counter).

Document rate-limiting / error UI as app concerns.

---

## 8. TypeScript & types

### 8.1 Choices.js already ships types

As of Choices 11.x, the package declares:

```json
"types": "./public/types/src/index.d.ts"
```

Exports include default `Choices`, `InputChoice`, `InputGroup`, `Options`, `EventChoice`, event name constants, etc.

**You should not invent a full parallel typings package** unless:

- Module resolution fails under the addon's TS/Glint config (path / `moduleResolution` / `exports`), or
- Published types are incomplete for a method you need.

### 8.2 Addon-owned types

Own only the **Ember surface**:

- `ChoicesSignature`, `ChoicesMode`, `ChoicesPublicAPI`
- Narrower `onChange` value types
- Maybe a `ChoicesConfig` alias of `Partial<Options>` with JSDoc for recreate keys

If consumers hit “no types found,” fix via:

1. `import type Choices from 'choices.js'` with `"moduleResolution": "bundler"` / `"node16"`
2. Thin re-export module in the addon: `export type { InputChoice, Options } from 'choices.js'`
3. Only as last resort: `types/choices.js.d.ts` ambient module in the addon

### 8.3 Glint

- Register component in `template-registry.ts`
- Strict signature on the gts component
- Test-app uses the same Glint env as modern v2 addons

---

## 9. CSS packaging & theming (Tailwind + daisyUI)

This is a first-class concern, not an afterthought. Past pain usually comes from misunderstanding **what Choices owns**.

### 9.1 Why CSS feels hard

Choices does **not** enhance the host control in place the way daisyUI’s `<select class="select">` does.

| What you style | What you get |
|---|---|
| Host `<select class="select select-bordered">` | Host is hidden / replaced in the a11y tree; daisyUI classes on the host often **do nothing visible** |
| Choices-generated DOM | Outer `.choices`, inner `.choices__inner`, dropdown `.choices__list--dropdown`, items, remove buttons, search input — all BEM, built at runtime |
| Stock `choices.css` | Full visual skin (colors, radii, chevron, tag pills) that **ignores** your Tailwind theme / daisyUI semantic colors |

So “wire in CSS” fails when you only import `choices.css` **or** only put Tailwind classes on the Ember host. You need a strategy for the **generated** tree.

Choices gives three styling levers:

1. **`classNames` config** — every structural slot accepts `string | string[]` (see `ClassNames` in Choices types). You can **append** daisyUI/Tailwind utilities next to BEM hooks.
2. **CSS custom properties** on stock CSS — Choices 11 ships vars like `--choices-primary-color`, `--choices-bg-color`, `--choices-bg-color-dropdown`, `--choices-text-color`, `--choices-keyline-color`, `--choices-highlight-color`, `--choices-border-radius`, etc.
3. **`callbackOnCreateTemplates`** — full DOM control (heavy; last resort).

### 9.2 Recommended layering (do this in the addon)

Think of **three CSS layers**:

```
[A] Structure   — layout, positioning, open/overflow, z-index, [hidden] host
[B] Theme bridge — map daisyUI / CSS variables → Choices tokens (or utility classes)
[C] App overrides — one-off tweaks
```

**Do not** force the full stock visual skin as the only path.

#### Layer A — structure (required)

Always need *some* CSS so dropdown positioning / open state works. Options:

| Approach | Pros | Cons |
|---|---|---|
| **A1. Import full `choices.css`** | Zero layout work | Looks like default Choices; fights daisyUI until overridden |
| **A2. Structure-only stylesheet** (addon ships `choices-structure.css`) | Clean slate for Tailwind | Must extract/maintain position/overflow/z-index rules |
| **A3. Full CSS + aggressive reset** of colors/borders on `.choices *` | Fast to start | Specificity thrash with stock rules |

**Recommendation for a Tailwind/daisyUI shop:**

- **v1 default:** A1 (import full CSS) + **§9.3 theme bridge** so it doesn’t look alien.
- **v1.1 / preferred long-term:** A2 structure-only + utility/`classNames` skin (see §9.4).

Never rely on classic Ember `vendor` trees. Use Embroider-friendly imports.

### 9.3 Theme bridge via CSS variables (lowest effort daisyUI fit)

Choices already reads vars, e.g.:

```css
/* from choices.css — colors are var(--choices-*, fallback) */
.choices { /* … */ }
```

Ship an optional addon stylesheet (or document a consumer snippet) that maps **daisyUI theme tokens** onto Choices tokens:

```css
/* choices-ember/styles/daisyui-theme.css (illustrative; target daisyUI 5) */
.choices {
  /* daisyUI 5 semantic tokens — adjust if token names differ in app setup */
  --choices-bg-color: var(--color-base-200, var(--b2, #f9f9f9));
  --choices-bg-color-dropdown: var(--color-base-100, var(--b1, #fff));
  --choices-bg-color-disabled: var(--color-base-200, var(--b2, #eaeaea));
  --choices-text-color: var(--color-base-content, var(--bc, #333));
  --choices-keyline-color: var(--color-base-300, var(--b3, #ddd));
  --choices-primary-color: var(--color-primary, var(--p, #005f75));
  --choices-highlight-color: var(--color-primary, var(--p, #005f75));
  --choices-highlighted-color: var(--color-base-200, var(--b2, #f2f2f2));
  --choices-item-color: var(--color-primary-content, var(--pc, #fff));
  --choices-invalid-color: var(--color-error, var(--er, #d33141));
  --choices-border-radius: var(--radius-field, 0.5rem);
  --choices-font-size-lg: 0.875rem; /* match daisy input text-sm-ish */
  --choices-guttering: 0; /* forms usually control spacing */
}

/* Dark / theme switches: daisyUI sets tokens on :root / [data-theme]; Choices inherits */
```

**Import order (consumer app):**

```ts
// app.css or app entry
import 'choices.js/public/assets/styles/choices.css'; // or addon structure CSS
import 'choices-ember/styles/daisyui-theme.css';      // optional preset (daisyUI 5 apps)
// tailwind + daisy already loaded in the app pipeline
```

Embroider: document exact import path; use package `exports` for `./styles/*`.

**Why this helps:** you stop hand-overriding every `.choices__inner` rule. Theme flips (`data-theme="dark"`) update Choices with the rest of the app.

### 9.4 Theme bridge via `classNames` + Tailwind utilities

`classNames` accepts arrays — keep BEM hooks for JS selectors **and** add utilities:

```ts
const daisyClassNames = {
  containerOuter: ['choices', 'w-full', 'relative'],
  containerInner: [
    'choices__inner',
    // approximate daisyUI select/input chrome
    'select', 'select-bordered', 'w-full', 'min-h-12', 'h-auto',
    'flex', 'flex-wrap', 'items-center', 'gap-1',
  ],
  listDropdown: [
    'choices__list--dropdown',
    'menu', 'bg-base-100', 'rounded-box', 'shadow-lg',
    'border', 'border-base-300', 'z-50', 'p-1',
  ],
  item: ['choices__item'],
  itemChoice: ['choices__item--choice'],
  itemSelectable: ['choices__item--selectable', 'rounded-lg'],
  highlightedState: ['is-highlighted', 'bg-primary', 'text-primary-content'],
  selectedState: ['is-selected'],
  button: ['choices__button', 'btn', 'btn-ghost', 'btn-xs'],
  inputCloned: ['choices__input--cloned', 'input', 'input-ghost', 'input-sm', 'grow'],
  // …fill remaining ClassNames keys; omit only if you accept defaults
};
```

Pass as:

```hbs
<Choices @config={{hash classNames=this.daisyClassNames}} … />
```

Or ship **`@theme="daisy"`** on the component that merges a maintained preset into config (recreate instance if classNames change — init-only for practical purposes).

**Caveats (document honestly):**

- daisyUI `select` assumes a native `<select>`; on `.choices__inner` (a `div`) some pseudo-elements / heights will be imperfect. Prefer **input-like** utilities (`input input-bordered`) for the inner shell if `select` fights you.
- Stock `choices.css` still sets backgrounds/borders — you may need `@layer` overrides or structure-only CSS so utilities win.
- Tailwind **content detection**: class strings built in TS may be purged. Use a full class string safelist, a source file Tailwind scans, or always write complete literal class strings in a scanned module (e.g. `themes/daisy.ts` under `app/` or addon `src/` listed in `content`).

### 9.5 What not to do

| Anti-pattern | Why it fails |
|---|---|
| `class="select"` only on host `<select>` | Host is not the painted control |
| Import nothing | Broken layout / invisible dropdown |
| Only override `.choices` with one Tailwind class on the component wrapper | Generated children keep stock colors |
| Put dropdown styles on a Glimmer wrapper around `<Choices>` | Dropdown is often portaled only within `.choices`; wrapper doesn’t style inner list |
| `allowHTML` + unsanitized labels to “inject badge HTML” | XSS footgun; use templates API carefully |

### 9.6 Structural gotchas with daisyUI layouts

1. **z-index / overflow**  
   daisyUI modals, drawers, and `overflow-hidden` cards clip or bury the dropdown. Stock Choices uses low z-index. Addon theme must set a high dropdown z-index (e.g. `z-50` / `z-[100]`) and document “don’t put Choices inside `overflow-hidden` without a plan.”

2. **Width**  
   Force `.choices { width: 100% }` / `w-full` so it fills form grid columns like other daisy inputs.

3. **Multi-select tags**  
   Stock pills are Choices-styled. Map item + button classes to `badge` / `btn-xs` or keep Choices pills but recolor via CSS vars (`--choices-primary-color`).

4. **Focus rings**  
   daisyUI focus uses theme rings; Choices uses its own outline/box-shadow. Override focus styles on `.choices.is-focused .choices__inner` to match `input-bordered` focus.

5. **Form control height**  
   Align min-height with `select-md` / `input-md` so mixed forms don’t jump.

6. **Remove button icons**  
   Stock uses background SVG. daisyUI buttons may need `background-image: none` + a visible `×` via template callback or CSS.

### 9.7 Packaging options for the addon

Expose **named style entry points** (package `exports`):

```json
{
  "exports": {
    ".": { "…": "…" },
    "./styles/structure.css": "./dist/styles/structure.css",
    "./styles/choices-default.css": "./dist/styles/choices-default.css",
    "./styles/daisyui-theme.css": "./dist/styles/daisyui-theme.css"
  }
}
```

| Export | Purpose |
|---|---|
| `choices-default.css` | Re-export or copy of upstream full skin |
| `structure.css` | Layout-only (long-term Tailwind path) |
| `daisyui-theme.css` | Variable mapping + a few specificity fixes |

**Component policy:** do **not** hard side-effect-import the full skin inside the component if the app uses Tailwind theming — that forces double styling. Prefer:

```ts
// Documented consumer choice
import 'choices-ember/styles/choices-default.css';
import 'choices-ember/styles/daisyui-theme.css';
```

Optional `@importStyles={{false}}` is overkill; documentation is enough for v1.

### 9.8 API surface for theming

Add to component args (§5.2):

```ts
/**
 * Visual preset merged into config.classNames + documented CSS import.
 * - 'default' — stock Choices look (needs choices-default.css)
 * - 'daisy'   — classNames + expects daisyui-theme.css (and daisyUI in the app)
 * - 'unstyled'— minimal classNames; app owns all utilities
 */
theme?: 'default' | 'daisy' | 'unstyled';

/** Extra classes on the outer Choices container (merged into classNames.containerOuter) */
class?: string; // or outerClass
```

Merge order: `preset classNames ← @config.classNames ← @class on containerOuter`.

Changing `theme` / `classNames` → treat as **recreate** (§6.3).

### 9.9 Tailwind content / Embroider checklist

- [ ] `choices.js` CSS import path works under Embroider (no missing vendor tree)
- [ ] Theme preset file is in Tailwind `content` globs **or** uses only CSS variables (safer)
- [ ] daisyUI major version documented (v3 `bg-base-100` vs v4 `@plugin` / token names differ — ship one target, note the other)
- [ ] Dropdown visible above daisyUI modal (`z-index` recipe in docs)
- [ ] Dark theme: visual smoke test with `data-theme`
- [ ] Multi-select badge contrast on primary color

### 9.10 Search builds

Search builds (`choices.js/search-basic`, `search-prefix`, `search-kmp`) are advanced; v1 depends on default `choices.js` only. CSS theming is independent of search entry.

### 9.11 Theming success criteria

1. With daisyUI + Tailwind app, a form row of `<input class="input">` + `<Choices @theme="daisy">` looks **cohesive** (radius, border, height, colors) without one-off app CSS beyond the preset import.
2. Theme switch updates Choices colors without re-init when using the CSS variable bridge.
3. Docs show the three-layer model and the “don’t style only the host” warning in the first screen of the README.

---

## 10. Testing strategy

### 10.1 Recommendation

| Layer | Tool | What |
|---|---|---|
| Pure helpers | **Vitest (node)** | `map-options`, normalize value, deep equal fingerprint, recreate-key hash — no DOM |
| Component / bridge | **Browser tests** | init, setChoices, controlled value, nested tracked labels, destroy |
| Manual | test-app pages mirroring demo sections | visual parity |
| Theming | Manual / screenshot optional | daisy preset beside daisy `input` / `select`; dark theme; modal z-index |

## 10. Testing strategy

### 10.1 Recommendation

| Layer | Tool | What |
|---|---|---|
| Pure helpers | **Vitest (node)** | `map-options`, normalize value, deep equal fingerprint, recreate-key hash — no DOM |
| Component / bridge | **Browser tests** | init, setChoices, controlled value, nested tracked labels, destroy |
| Manual | test-app pages mirroring demo sections | visual parity |

### 10.2 On `ember-vitest`

[ember-vitest](https://github.com/NullVoxPopuli/ember-vitest) is a good fit **if** the test-app is already (or will be) **Vite + Embroider** based:

- `setupRenderingContext` / `renderingTest` with gts
- Vitest browser mode
- Familiar settle/helpers story evolving toward Testing Library

**You do not need it** if:

- You keep the default **ember-qunit + @ember/test-helpers** test-app from the addon blueprint — that is still the path of least resistance for many v2 addons today.

**Pragmatic plan:**

1. **Phase 0:** unit-test pure TS with Vitest in the addon package (no Ember).
2. **Phase 1:** rendering tests with whatever the blueprint gives you (qunit is fine).
3. **Phase 2 (optional):** adopt ember-vitest when/if the test-app moves to Vite.

Do not block the addon on ember-vitest maturity; block on **reactivity correctness tests**.

### 10.3 Required test cases (acceptance)

1. **Single select controlled:** change `@value` from outside → UI selection updates; no extra `onChange`.
2. **Multi select user action:** select two options → `onChange` with both values.
3. **Options replace:** new `@options` array → dropdown lists new labels.
4. **Nested tracked label:** object field used as label changes → dropdown text updates (the critical tracking case).
5. **Groups:** grouped options render group headings (Choices DOM).
6. **Disabled toggle:** `@disabled` true/false → cannot/can open.
7. **Destroy:** render → clear → no leftover `.choices` DOM / no throw on second mount.
8. **Text mode:** add tag → `onChange`; maxItemCount respected via config.
9. **Remove button:** remove item → value updates.
10. **Feedback loop:** controlled parent that sets value in `onChange` does not infinite loop.
11. **Form reset (uncontrolled):** reset restores initial Choices state.
12. **Remote options:** async resolve → options appear; destroy mid-flight does not throw.
13. **Custom config pass-through:** `searchEnabled: false` hides search.

### 10.4 How to assert Choices UI

Prefer stable hooks:

- Underlying select’s selected options / `instance.getValue(true)` via `registerAPI`
- Choices DOM classes (`.choices__item`, `[data-value="…"]`) as used in Choices’ own e2e tests
- Avoid brittle full HTML snapshots

---

## 11. Accessibility & forms

- Forward `...attributes` (`aria-*`, `id`, `required`, `form`, etc.) onto the **host** element before/while Choices wraps it.
- Support `@name` for FormData participation.
- Preserve `label[for]` association via host `id`.
- Do not set `allowHTML: true` by default.
- Document that Choices manages ARIA on its chrome; test keyboard open/select/escape smoke cases.

---

## 12. Dependencies

| Package | Role |
|---|---|
| `choices.js` | **peerDependency** `^11` (+ optional peer) + devDep for tests |
| `ember-modifier` or resource lib | lifecycle / arg sync |
| `@glimmer/component` | component base |
| `@embroider/addon-shim` | v2 runtime |
| `ember-source` | peer |
| `tailwindcss` | **optional peer** — app pipeline only; never bundle |
| `daisyui` | **optional peer** — app theme only; never bundle |

Avoid coupling to `ember-lifeline` unless needed; prefer `registerDestructor` + modifier cleanup.

**test-app** (and your work app) install real `tailwindcss` + `daisyui` as normal dependencies so fieldset demos and visual checks work.

---

## 13. Implementation phases

Canonical acceptance checklists (use these when implementing — not this summary alone):

| Phase | Checklist | Summary |
|------:|-----------|---------|
| 1 | **[PHASE-1.md](./PHASE-1.md)** | Scaffold + controlled single select + core reactivity tests |
| 2 | **[PHASE-2.md](./PHASE-2.md)** | Multiple + text modes; remove button / maxItemCount |
| 3 | **[PHASE-3.md](./PHASE-3.md)** | daisyUI 5 theme preset + `<ChoicesFieldset>` |
| 4 | **[PHASE-4.md](./PHASE-4.md)** | Groups, forms, remote pattern, escape hatches, docs, release |

Default agent work starts at Phase 1 and does not skip ahead.

---

## 14. Documentation deliverables (addon repo)

1. **README:** install, CSS import, controlled single/multi/text examples.
2. **Reactivity guide:** nested tracked fields, mapping getters, `syncKey`.
3. **Demo cookbook:** one snippet per demo section.
4. **Config pass-through:** link to Choices options docs; list recreate keys.
5. **TypeScript:** re-exports, Glint registry.
6. **Migration note** from dual-DOM prototypes (`refresh` + `<option>` each).
7. **Theming guide (Tailwind + daisyUI):** host vs generated DOM, CSS variable map, `classNames` preset, purge/safelist, overflow/z-index, dark theme.

---

## 15. Explicit non-goals / out of scope (v1)

- Server-side rendering of open dropdown (Choices is DOM-only; render host only on client).
- Pixel-perfect reimplementation of Choices templates in Glimmer.
- Supporting Ember Classic components / two-way `mut` as primary API.
- Bundling a forked Choices build (use upstream peers).
- Making Choices’ internal store tracked.
- Shipping daisyUI or Tailwind as addon **dependencies** (they are **optional app peers**; addon only ships optional Choices CSS bridge / className **string** presets / fieldset **markup**).
- Perfect pixel match to native daisyUI `<select class="select">` (Choices DOM will always differ slightly).
- Requiring daisyUI to use the core `<Choices>` component.

---

## 16. Decisions (frozen)

Canonical table: **[DECISIONS.md](./DECISIONS.md)**. Summary:

| Decision | Frozen value |
|---|---|
| Package name | `choices-ember` |
| Min Ember | `>= 6.0.0` |
| Component tests | ember-qunit + `@ember/test-helpers` |
| Components | `<Choices>` + `<ChoicesFieldset>` |
| Default `@theme` | `default` (stock Choices CSS) |
| daisyUI | **v5** opt-in (`@theme="daisy"` / Fieldset) |
| Tailwind / daisyUI packaging | **Not** in addon deps; optional peers |
| `removeItemButton` | true for multi/text; not forced on single |
| Function `@options` | parent-only async in Phase 1–2 |
| Value type | coerce to **string** at boundary |
| Default CSS | full stock Choices CSS + optional daisy var bridge |
| Fieldset chrome | bare `fieldset` + `@fieldsetClass` for card |

Still flexible: modifier vs resource for bridge lifecycle; fingerprinting; exact `RECREATE_KEYS`.

---

## 17. Success criteria

The addon is “done” for production use when:

1. All §10.3 tests pass on CI.
2. Nested tracked label updates work without `<option>` rendering.
3. Demo modes in §4 are either supported or explicitly documented as `@config` recipes in the test-app.
4. No dual-DOM ownership; destroy is leak-free under rapid re-render.
5. Types work via `choices.js` published `.d.ts` + Glint component signature for app authors using gts.
6. §9.11 theming criteria met for a Tailwind + daisyUI consumer app (cohesive form controls, theme switch, documented z-index).
7. `<ChoicesFieldset>` matches daisyUI fieldset patterns (legend / label / description) and is documented as requiring app-provided Tailwind + daisyUI.
8. Addon package does **not** nest `tailwindcss` or `daisyui` in `dependencies`.

---

## 18. Appendix A — Choices APIs the bridge relies on

| API | Use |
|---|---|
| `new Choices(element, config)` | init |
| `setChoices(list, valueKey, labelKey, replaceChoices)` | options sync (select) |
| `setChoiceByValue(value \| value[])` | selection sync (select) |
| `setValue(items)` | text / tag items |
| `getValue(valueOnly?)` | read selection for onChange |
| `removeActiveItems()` / `clearStore()` / `clearChoices()` | reset paths |
| `enable()` / `disable()` | disabled |
| `destroy()` | teardown |
| Events: `addItem`, `removeItem`, `change`, `search`, `showDropdown`, `hideDropdown` | outward callbacks |
| `refresh()` | **do not use** for Ember option updates |

## 19. Appendix B — Why not `refresh()`?

`refresh()` re-reads the native `<select>` via `optionsAsChoices()`. That only works if Ember owns option elements. This spec forbids that ownership. Use `setChoices` so Choices remains the sole owner of choice data and DOM after init.

---

## 20. Appendix C — Related prior art

- Prototype dual-DOM approach (`TooManyChoices` + `refresh` in getter): useful as a negative lesson, not a base.
- React/Vue Choices wrappers: generally API-sync (setChoices), same model.
- Ember power-select: data-down / actions-up mental model to mirror for controlled mode — different renderer, same app-facing ergonomics.
- daisyUI / Tailwind select plugins: style the **visible** control; Choices requires styling the **generated** BEM tree (or CSS variables), not only the host element.

## 21. Appendix D — Theming quick reference

| Goal | Mechanism |
|---|---|
| Match daisyUI colors / dark mode | Map `--choices-*` → daisy semantic tokens (`daisyui-theme.css`) |
| Match daisyUI “shape” (radius, borders) | Same vars + optional utility classes on `containerInner` |
| Menu-like dropdown | `classNames.listDropdown` + `menu bg-base-100 shadow …` **or** CSS |
| Avoid stock look entirely | `structure.css` + `@theme="unstyled"` + full utility `classNames` |
| Survive Tailwind purge | Put class presets in a scanned file; prefer CSS vars for colors |
| Modal / drawer stacking | Raise dropdown z-index; avoid `overflow-hidden` ancestors |

---

*This document is the design spec for the **choices-ember** package (this repository). It peers on upstream [Choices.js](https://github.com/Choices-js/Choices) (`choices.js`); it is not part of the Choices.js core repo.*

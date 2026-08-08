# choices-ember

Ember addon that wraps [Choices.js](https://github.com/Choices-js/Choices) with **autotracking-friendly** data flow.

- **`<Choices>`** — reactive bridge for single select, multi-select, and text/tags
- **`<ChoicesFieldset>`** — optional daisyUI 5 fieldset chrome around `<Choices>`

Choices owns the widget DOM. Ember owns your tracked data. The addon snapshots options/values into Choices APIs (`setChoices`, `setChoiceByValue`, `setValue`) and relays user events back via `@onChange` (and friends).

**Requirements:** Ember 6+, Choices.js 11+, TypeScript / `.gts` recommended.

---

## Install

```bash
pnpm add choices-ember choices.js
# or: npm / yarn
```

### Peer dependencies

| Package | Required | Notes |
|---------|----------|--------|
| `ember-source` | `>= 6` | Ember **6** and **7** (release/beta/canary) covered by ember-try CI |
| `choices.js` | `^11` | Widget runtime + stock CSS |
| `tailwindcss` | optional `>= 4` | Only for `@theme="daisy"` / `<ChoicesFieldset>` |
| `daisyui` | optional `>= 5` | Same — **not** bundled by the addon |

Core `<Choices @theme="default">` works with **no** Tailwind or daisyUI.

---

## CSS setup

### Stock Choices look (default)

```css
/* app.css (or equivalent) */
@import 'choices.js/public/assets/styles/choices.css';
/* or: @import 'choices-ember/styles/choices-default.css'; */
```

### daisyUI look

The app owns the Tailwind + daisyUI pipeline. The addon only ships a **CSS variable bridge** and a `classNames` preset.

**Cascade layering (required):** import Choices skin (and optional `daisyui-theme.css`) with `layer(components)` so they sit **below** Tailwind’s `@layer utilities`. Unlayered Choices CSS always wins over utilities, so daisy `classNames` (`input-bordered`, `rounded-2xl`, `bg-primary`, …) look like they do nothing even when the classes are on the DOM.

```css
@import 'tailwindcss';
@plugin 'daisyui';

/* layer(components) — below utilities; do not drop this */
@import 'choices.js/public/assets/styles/choices.css' layer(components);
@import 'choices-ember/styles/daisyui-theme.css' layer(components);

/* so daisy/Tailwind classes in the addon preset are not purged */
@source "../node_modules/choices-ember/dist/**/*.js";
/* monorepo source alternative: */
/* @source "../../choices-ember/src/**/*.{gts,ts}"; */
```

| Import | Layer |
|--------|--------|
| `tailwindcss` / daisyUI | theme / base / utilities (as Tailwind defines) |
| Choices skin + `daisyui-theme.css` | **`layer(components)`** (must be lower than utilities) |

---

## Quick start

```ts
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class Example extends Component {
  @tracked options = [
    { value: '1', label: 'One' },
    { value: '2', label: 'Two' },
  ];
  @tracked selected: string | null = null;

  onChange = (value: string | string[] | null) => {
    this.selected = value as string | null;
  };
}
```

```hbs
<Choices
  @type="single"
  @options={{this.options}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
  @placeholder="Pick one"
/>
```

Prefer **controlled** usage: always pass `@value` + `@onChange`. Parent state is the source of truth.

---

## Modes

| `@type` | Host | `@value` / `onChange` |
|---------|------|------------------------|
| `single` (default) | `<select>` | `string \| null` |
| `multiple` | `<select multiple>` | `string[]` |
| `text` | `<input type="text">` | `string[]` (tags) |

```hbs
{{! Multi — remove buttons on by default }}
<Choices
  @type="multiple"
  @options={{this.options}}
  @value={{this.ids}}
  @onChange={{this.onMulti}}
/>

{{! Text / tags }}
<Choices
  @type="text"
  @value={{this.tags}}
  @onChange={{this.onTags}}
  @config={{hash maxItemCount=5}}
/>
```

Values are **coerced to strings** at the Choices boundary.

---

## Options

### Flat list

```ts
options = [
  { value: 'a', label: 'Alpha', disabled: false },
  { value: 'b', label: 'Beta' },
];
```

### Groups

```ts
options = [
  {
    label: 'Fruit',
    value: 'fruit',
    choices: [
      { value: 'apple', label: 'Apple' },
      { value: 'pear', label: 'Pear' },
    ],
  },
];
```

Pass either shape as `@options`. Do **not** render `<option>` children yourself — the host element stays empty; Choices owns the list DOM.

### Nested tracked labels

If options come from domain objects with `@tracked` fields used as labels, map them in a getter that **reads** those fields (the addon also reads `value` / `label` / etc. when mapping):

```ts
class Person {
  id: string;
  @tracked name: string;
  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
  }
}

@tracked people = [new Person('1', 'Ada'), new Person('2', 'Grace')];
@tracked selectedId: string | null = null;

get choiceOptions() {
  return this.people.map((p) => ({
    value: p.id,
    label: p.name, // tracked read → dropdown updates when name changes
  }));
}

// After form submit:
// person.name = this.draftName;  // selection id stays; label updates
```

```hbs
<Choices
  @options={{this.choiceOptions}}
  @value={{this.selectedId}}
  @onChange={{this.onPersonChange}}
/>
```

If data is not autotracked, bump `@syncKey` to force a resync.

### Async / remote options (app-owned)

Load in the parent; pass the array when ready. Keep `@value` across reloads if the id still exists:

```ts
@tracked options: { value: string; label: string }[] = [];
@tracked value: string | null = null;

async load() {
  const previous = this.value;
  this.options = await fetch('/api/items').then((r) => r.json());
  if (previous != null && !this.options.some((o) => o.value === previous)) {
    this.value = null;
  }
  // else leave value — bridge re-applies selection after setChoices
}
```

There is no built-in fetcher `@options` function; loading UI is the app’s job.

---

## Themes and styling

| `@theme` | Meaning |
|----------|---------|
| `default` | Stock Choices classes (default). Needs Choices CSS. |
| `daisy` | daisyUI-oriented `classNames` preset + `choices-ember--daisy` hook. Needs app Tailwind/daisy + optional `daisyui-theme.css`. |
| `unstyled` | Minimal BEM hooks only; you supply utilities via `@config.classNames`. |

```hbs
<Choices @theme="daisy" @class="w-full" … />
```

- **`@class`** — extra classes **appended** to `classNames.containerOuter`
- **CSS variables** — `daisyui-theme.css` maps daisy tokens → `--choices-*` (colors follow `data-theme`)

### Overriding daisy `classNames`

Merge order:

```
theme preset  →  @config.classNames (per-key replace)  →  @class (on containerOuter)
```

Keys you pass in `@config.classNames` **replace** that slot entirely (include BEM hooks Choices still needs):

```ts
import { DAISY_CLASS_NAMES } from 'choices-ember';

customClassNames = {
  ...DAISY_CLASS_NAMES,
  containerInner: [
    'choices__inner',
    'input',
    'input-bordered',
    'input-secondary',
    'w-full',
    'min-h-12',
  ],
  highlightedState: ['is-highlighted', 'bg-accent', 'text-accent-content'],
};

config = { classNames: this.customClassNames };
```

```hbs
<Choices
  @theme="daisy"
  @config={{this.config}}
  @options={{this.options}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
/>
```

Or start from `@theme="unstyled"` and pass a full custom map. Changing `classNames` / theme recreates the Choices instance.

---

## `<ChoicesFieldset>`

Composition-only wrapper: daisyUI 5 `fieldset` + legend/label/description + inner `<Choices @theme="daisy">`. No second bridge.

```hbs
<ChoicesFieldset
  @legend="Charge code"
  @description="Search by name or id"
  @type="single"
  @options={{this.options}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
  @fieldsetClass="bg-base-200 border-base-300 rounded-box border p-4 w-full"
/>
```

Also supports `@label`, `@disabled`, named blocks `<:legend>` / `<:description>`, and the same Choices pass-through args (`@type`, `@config`, `@registerAPI`, …).

Requires Tailwind + daisyUI in the app (see CSS setup above).

---

## Config pass-through

Any [Choices constructor option](https://github.com/Choices-js/Choices#setup) can go through `@config`:

```hbs
<Choices
  @config={{hash
    searchEnabled=false
    shouldSort=false
    removeItemButton=false
    maxItemCount=5
  }}
  …
/>
```

Addon defaults (unless overridden):

- `allowHTML: false`
- `removeItemButton: true` for **multiple** and **text** only

Some keys are **init-only** and recreate the instance when changed: `searchEnabled`, `classNames`, `allowHTML`, `callbackOnCreateTemplates`, plus `@theme` and `@type`. See the `RECREATE_KEYS` export.

---

## API summary

### `<Choices>`

| Arg | Description |
|-----|-------------|
| `@type` | `'single' \| 'multiple' \| 'text'` (default `'single'`) |
| `@options` | `InputChoice[]` and/or groups (select modes) |
| `@value` | Controlled selection |
| `@onChange` | User-driven change (not bridge sync) |
| `@onAdd` / `@onRemove` | Item events (`EventChoice` detail) |
| `@onSearch` / `@onShowDropdown` / `@onHideDropdown` | Optional UI events |
| `@disabled` | `enable()` / `disable()` without full recreate when possible |
| `@placeholder` | Placeholder text / config merge |
| `@name` | Native `name` on host |
| `@theme` | `'default' \| 'daisy' \| 'unstyled'` |
| `@class` | Extra outer classes |
| `@config` | `Partial<Choices options>` |
| `@syncKey` | Force options/value resync |
| `@onReady` | `(instance) => void` after init |
| `@registerAPI` | `(api \| null) => void` — `null` on destroy |

`...attributes` (e.g. `required`, `aria-*`, `dir`) forward to the host element.

### `registerAPI` shape

```ts
{
  focus: () => void;
  clearStore: () => void;
  getValue: (valueOnly?: boolean) => unknown;
  instance: Choices | null; // prefer not to use in app code
}
```

### Package exports

```ts
import {
  Choices,
  ChoicesFieldset,
  DAISY_CLASS_NAMES,
  UNSTYLED_CLASS_NAMES,
  RECREATE_KEYS,
  mapOptions,
  // types: ChoicesMode, ChoicesOption, ChoicesPublicAPI, InputChoice, …
} from 'choices-ember';
```

```css
@import 'choices-ember/styles/choices-default.css';
@import 'choices-ember/styles/daisyui-theme.css';
```

---

## Mental model (do / don’t)

**Do**

- Keep an empty host; pass data via `@options` / `@value`
- Use controlled `@value` + `@onChange` in Ember apps
- Read nested tracked fields when building option snapshots

**Don’t**

- `{{#each}}` render `<option>`s and call Choices `refresh()` (dual DOM — broken)
- Expect daisy/Tailwind to ship inside the addon
- Style only the host `<select class="select">` and expect the painted UI to match (Choices replaces the host)

---

## Local development

This monorepo: `choices-ember/` (addon) + `test-app/` (demos + tests).

```bash
pnpm install
pnpm start          # addon watch + test-app
pnpm test:ember
```

The **test-app is the cookbook**: each demo is a live control plus a **How to build this** recipe (not a Choices.js-style mystery gallery). See [docs/COOKBOOK.md](./docs/COOKBOOK.md) for the section index.

### Demo (GitHub Pages)

On push to `main`, [`.github/workflows/pages.yml`](./.github/workflows/pages.yml) builds the test-app and deploys it to GitHub Pages.

1. Repo **Settings → Pages → Source: GitHub Actions**
2. After the first successful run: `https://ultish.github.io/choices-ember/`

Local production build with the same base path:

```bash
ROOT_URL=/choices-ember/ pnpm --filter test-app build
```

### Publishing to npm

Releases run on **version tags** via [`.github/workflows/release.yml`](./.github/workflows/release.yml) (not on every `main` push).

**Important:** CI cannot enter an authenticator OTP. A normal “2FA publish” token will fail with `EOTP`.

#### Auth option A — Granular token with Bypass 2FA (simplest first publish)

1. [npmjs.com → Access Tokens](https://www.npmjs.com/settings/~/tokens) → **Generate New Token** → **Granular Access Token**
2. Permissions: **Read and write** for package `choices-ember` (or permission to **create** packages if it does not exist yet)
3. Check **Bypass two-factor authentication** (required for GitHub Actions)
4. GitHub → **Settings → Secrets and variables → Actions** → `NPM_TOKEN` = that token
5. Re-run **Actions → Release → v0.1.0 → Re-run failed jobs**

#### Auth option B — Trusted Publishing / OIDC (no long-lived token)

After the package exists on npm once:

1. npmjs.com → **choices-ember** → **Settings → Trusted Publisher** → GitHub Actions  
   - User/org: `ultish`  
   - Repo: `choices-ember`  
   - Workflow filename: `release.yml` (filename only)  
   - Allow: `npm publish`
2. You can remove `NPM_TOKEN` — the workflow uses OIDC (`id-token: write`)

#### Cut a release

```bash
# 1. Bump version in choices-ember/package.json (e.g. 0.1.0)
# 2. Commit on main
git tag v0.1.0          # must match package.json without the "v"
git push origin v0.1.0  # triggers Release workflow → npm publish
```

The workflow: install → tag ≡ version check → lint → test → pack → `npm publish` from `choices-ember/`.

Dry-run without publishing: **Actions → Release → Run workflow** (dry_run checked).

---

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).

## License

MIT (see [LICENSE.md](./LICENSE.md)); align with Choices / project preference when publishing.

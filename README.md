# choices-ember

Ember v2 / Glimmer addon that wraps [Choices.js](https://github.com/Choices-js/Choices) with Ember autotracking, plus an optional daisyUI 5 fieldset chrome component.

**Status:** Phase 1–4 complete (single, multiple, text, daisy fieldset, groups, demos).

## Install

```bash
pnpm add choices-ember choices.js
# optional for Fieldset / @theme="daisy":
pnpm add -D tailwindcss daisyui
```

**Peers:** `ember-source >= 6`, `choices.js ^11`.  
**Optional peers:** `tailwindcss >= 4`, `daisyui >= 5` (not bundled).

## Quick start

```css
/* app.css */
@import 'choices.js/public/assets/styles/choices.css';
/* or: @import 'choices-ember/styles/choices-default.css'; */
```

```hbs
<Choices
  @type="single"
  @options={{this.opts}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
  @placeholder="Pick one"
/>
```

```ts
@tracked opts = [
  { value: '1', label: 'One' },
  { value: '2', label: 'Two' },
];
@tracked selected: string | null = null;
onChange = (v: string | string[] | null) => {
  this.selected = v as string | null;
};
```

### Multiple / text

```hbs
<Choices @type="multiple" @options={{this.opts}} @value={{this.ids}} @onChange={{this.onMulti}} />
<Choices @type="text" @value={{this.tags}} @onChange={{this.onTags}} @config={{hash maxItemCount=5}} />
```

### daisyUI fieldset

```css
@import 'tailwindcss';
@plugin 'daisyui';
@import 'choices.js/public/assets/styles/choices.css';
@import 'choices-ember/styles/daisyui-theme.css';

/* ensure preset classes are not purged */
@source "../node_modules/choices-ember/dist/**/*.js";
```

```hbs
<ChoicesFieldset
  @legend="Charge code"
  @description="Search by name or id"
  @type="single"
  @options={{this.opts}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
  @fieldsetClass="bg-base-200 border-base-300 rounded-box border p-4 w-full"
/>
```

Core `<Choices @theme="default">` works **without** Tailwind/daisy. Fieldset / `@theme="daisy"` need the app pipeline.

## Non-negotiables

- **Do not** render `<option>`s with `{{#each}}` and call `refresh()`.
- Sync via `setChoices` / `setChoiceByValue` / `setValue` + events; always `destroy()` on teardown.
- Nested tracked labels update only if those fields are **read** while mapping (addon does this).
- Do not package Tailwind/daisy inside the addon.

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).

## Docs

| Doc | Topic |
|-----|--------|
| [AGENTS.md](./AGENTS.md) | Agent workflow |
| [docs/DECISIONS.md](./docs/DECISIONS.md) | Frozen product decisions |
| [docs/ember-v2-addon-spec.md](./docs/ember-v2-addon-spec.md) | Full design |
| [docs/REACTIVITY.md](./docs/REACTIVITY.md) | Autotracking, async, forms |
| [docs/THEMING.md](./docs/THEMING.md) | CSS layers, daisy, purge |
| [docs/COOKBOOK.md](./docs/COOKBOOK.md) | Demo recipes |
| [docs/PHASE-1.md](./docs/PHASE-1.md) … [PHASE-4.md](./docs/PHASE-4.md) | Phase checklists |

## Local development

```bash
pnpm install
pnpm start          # addon watch + test-app
pnpm test:ember
```

## Migration note

Older prototypes that dual-own option DOM and call `refresh()` from getters are **wrong**. This package is a reactive bridge only.

## License

TBD (align with Choices / author preference when publishing).

# Theming guide

## Mental model

Choices **replaces** the host control with its own DOM (`.choices`, `.choices__inner`, dropdown list, …). Styling only the host `<select class="select">` does almost nothing visible.

Three layers:

1. **Structure / skin** — `choices.css` (layout + default look)
2. **Theme bridge** — map design tokens → Choices CSS variables (`daisyui-theme.css`)
3. **classNames utilities** — `@theme="daisy"` merges Tailwind/daisyUI class strings onto generated nodes

## Core without daisy

```ts
import 'choices.js/public/assets/styles/choices.css';
// or: import 'choices-ember/styles/choices-default.css';
```

```hbs
<Choices @type="single" @options={{this.opts}} @value={{this.v}} @onChange={{this.onChange}} />
{{! @theme defaults to "default" }}
```

No Tailwind or daisyUI required.

## daisyUI 5

1. App has Tailwind 4 + daisyUI 5 working.
2. Peers: optional `tailwindcss`, `daisyui` on the addon (not bundled).
3. CSS import order:

```css
@import 'tailwindcss';
@plugin 'daisyui';
@import 'choices.js/public/assets/styles/choices.css';
@import 'choices-ember/styles/daisyui-theme.css';
```

4. Tailwind content / `@source` must include the addon so preset class strings are not purged:

```css
@source "../node_modules/choices-ember/dist/**/*.js";
/* monorepo: */
@source "../../choices-ember/src/**/*.{gts,ts}";
```

5. Use the preset:

```hbs
<Choices @theme="daisy" @options={{…}} @value={{…}} @onChange={{…}} />

{{! or fieldset chrome }}
<ChoicesFieldset @legend="Code" @type="single" @options={{…}} @value={{…}} @onChange={{…}} />
```

`ChoicesFieldset` defaults to `@theme="daisy"` and `@class="w-full"`.

### Themes

| `@theme` | Meaning |
|----------|---------|
| `default` | Stock Choices classNames (default) |
| `daisy` | Full `DAISY_CLASS_NAMES` preset + `choices-ember--daisy` hook |
| `unstyled` | Minimal BEM hooks only; you own utilities via `@config.classNames` |

`@class` merges into `classNames.containerOuter`. Changing theme / classNames recreates the Choices instance.

## Gotchas

| Issue | Mitigation |
|-------|------------|
| Dropdown clipped | Avoid `overflow-hidden` ancestors; daisy preset uses `z-[100]` |
| Width not filling column | `@class="w-full"` / fieldset default |
| Focus ring alien | `daisyui-theme.css` focus rules on `.choices-ember--daisy` |
| Multi remove button | Default `removeItemButton: true` for multi/text; daisy maps button to `btn btn-xs` |
| Host `class="select"` only | Does not style painted UI — use `@theme` / CSS vars |

## Escape hatch

```hbs
<Choices
  @theme="unstyled"
  @config={{hash classNames=this.myClassNames}}
  …
/>
```

Or export `DAISY_CLASS_NAMES` / `UNSTYLED_CLASS_NAMES` from `choices-ember` and tweak a copy.

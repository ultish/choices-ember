# Reactivity guide

How `choices-ember` connects Ember autotracking to Choices.js.

## Model

```
App tracked data  ──snapshot──►  setChoices / setChoiceByValue / setValue
App callbacks     ◄──events──  change / addItem / removeItem / …
```

Choices never participates in autotracking. The bridge **reads** fields while mapping, then pushes **plain** snapshots into Choices APIs.

## Nested tracked labels

If options are domain objects with `@tracked` display fields, those fields must be **read** while building the snapshot (the addon does this in `mapOptions`):

```ts
class Row {
  @tracked name = 'Ada';
  id = '1';
}

// ✅ Pass domain objects; mapOptions reads .label/.value (or map yourself)
@tracked rows = [new Row()];

get choiceOptions() {
  return this.rows.map((r) => ({
    value: String(r.id),
    label: r.name, // tracked read
  }));
}
```

```hbs
<Choices @options={{this.choiceOptions}} @value={{this.selected}} @onChange={{this.onChange}} />
```

When `row.name` changes → getter re-runs → new array → bridge `setChoices(..., replace)`.

## Array semantics

| Change | Observed? |
|--------|-----------|
| Replace `@tracked` array | Yes |
| Nested `@tracked` field read during map | Yes |
| In-place `plainArray.push(...)` | **No** (same as rest of Ember) |
| Untracked nested field mutate | **No** — use `@syncKey` or reassign array |

## `@syncKey`

Force a full options/value resync when data is not autotracked:

```hbs
<Choices @options={{this.opts}} @value={{this.v}} @syncKey={{this.version}} … />
```

Increment `version` after external mutations.

## Controlled vs uncontrolled

| Mode | Pattern |
|------|---------|
| **Controlled (recommended)** | Always pass `@value` + `@onChange`. Parent is source of truth. |
| **Uncontrolled** | Omit `@value` after mount; initial selection from options / first paint. |

Do not mix “sometimes pass value.”

### Form reset

- **Controlled:** listen for form `reset` and clear/reset your tracked `@value` yourself. Choices will not update Ember state.
- **Uncontrolled:** native reset + Choices internal handling may restore the underlying control; prefer controlled in Ember apps.

## Async options (parent-owned)

```ts
@tracked options: InputChoice[] = [];

async load() {
  this.options = await fetch('/api/items').then((r) => r.json());
}
```

```hbs
<Choices @type="single" @options={{this.options}} @value={{this.v}} @onChange={{this.onChange}} />
```

Empty → filled works. Loading UI is the parent’s job. Destroy mid-flight is safe if you only write to tracked state after resolve (ignore if component is gone).

## Feedback loops

Programmatic `setChoiceByValue` / `setValue` can emit DOM events. The bridge sets a `syncing` flag so `@onChange` does not re-enter.

## Anti-pattern

Do **not** render `<option>`s with `{{#each}}` and call `refresh()`. That dual-DOM pattern is wrong (see old `ember-choices` prototype).

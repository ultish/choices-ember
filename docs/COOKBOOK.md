# Demo cookbook

Map major [Choices demo](https://choices-js.github.io/Choices/) scenarios to `choices-ember`.

## Single select

```hbs
<Choices
  @type="single"
  @options={{this.opts}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
  @placeholder="Pick one"
/>
```

## Multiple + remove

```hbs
<Choices
  @type="multiple"
  @options={{this.opts}}
  @value={{this.ids}}
  @onChange={{this.onMulti}}
/>
```

`removeItemButton` defaults **true** for multiple. Disable with `@config={{hash removeItemButton=false}}`.

## Text / tags

```hbs
<Choices
  @type="text"
  @value={{this.tags}}
  @onChange={{this.onTags}}
  @config={{hash maxItemCount=5}}
/>
```

## Option groups

```ts
opts = [
  {
    label: 'Group A',
    value: 'a',
    choices: [
      { value: '1', label: 'One' },
      { value: '2', label: 'Two' },
    ],
  },
];
```

## No search

```hbs
<Choices @config={{hash searchEnabled=false}} … />
```

## Custom property search / no sort

```hbs
<Choices
  @config={{hash
    shouldSort=false
    searchFields=(array "label" "value" "customProperties.description")
  }}
  …
/>
```

## Remote / async (parent load)

```ts
@tracked options = [];
@tracked value: string | null = null;

async load() {
  const previous = this.value;
  // Do not clear `value` while loading — selection stays put.
  this.options = await fetch('/api').then((r) => r.json());
  // Only drop selection if the id vanished from the new list.
  if (previous != null && !this.options.some((o) => o.value === previous)) {
    this.value = null;
  }
}
```

```hbs
<Choices @options={{this.options}} @value={{this.v}} @onChange={{this.onChange}} />
```

The bridge re-applies controlled `@value` after every `setChoices` replace, so a surviving id keeps its selection (label may update if the server renamed it).

## Nested tracked domain labels + edit form

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
    label: p.name, // tracked read — invalidates when name changes
  }));
}

save() {
  const person = this.people.find((p) => p.id === this.selectedId);
  if (person) person.name = this.draftName; // dropdown label updates; id stays
}
```

See test-app application demo for the full form flow.

## Dependent selects

Two components; parent clears child `@value` and swaps `@options` when parent changes. See test-app application demo.

## daisyUI fieldset row

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

## Escape hatches

```hbs
<Choices
  @onReady={{this.onReady}}
  @registerAPI={{this.registerAPI}}
  @onSearch={{this.onSearch}}
  @onShowDropdown={{this.onShow}}
  @onHideDropdown={{this.onHide}}
  @syncKey={{this.version}}
  …
/>
```

`registerAPI` receives `{ focus, clearStore, getValue, instance }` and `null` on destroy.

## Recreate keys

Changing these rebuilds the Choices instance: `searchEnabled`, `classNames`, `allowHTML`, `callbackOnCreateTemplates`, plus `@theme` and `@type`. See `RECREATE_KEYS` export.

## Full Choices options

Pass any Choices 11 constructor option via `@config`. See [Choices docs](https://github.com/Choices-js/Choices#setup).

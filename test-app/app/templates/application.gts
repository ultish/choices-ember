import { pageTitle } from 'ember-page-title';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import type Owner from '@ember/owner';
import Choices from 'choices-ember/components/choices';
import ChoicesFieldset from 'choices-ember/components/choices-fieldset';
import { DAISY_CLASS_NAMES, type InputChoice } from 'choices-ember';
import type { EventChoice } from 'choices.js';
import CookbookSection from 'test-app/components/cookbook-section';

/** Live event feed line for onChange / onAdd / onRemove demos */
interface EventLogLine {
  id: number;
  kind: 'change' | 'add' | 'remove';
  /** daisy badge class for the kind chip */
  badgeClass: string;
  summary: string;
}

const KIND_BADGE: Record<EventLogLine['kind'], string> = {
  change: 'badge-info',
  add: 'badge-success',
  remove: 'badge-error',
};

const CITIES = [
  { value: 'nyc', label: 'New York' },
  { value: 'sf', label: 'San Francisco' },
];

const STATIONS: Record<string, { value: string; label: string }[]> = {
  nyc: [
    { value: 'gct', label: 'Grand Central' },
    { value: 'penn', label: 'Penn Station' },
  ],
  sf: [
    { value: 'caltrain', label: 'Caltrain' },
    { value: 'bart', label: 'BART' },
  ],
};

const GROUPED = [
  {
    label: 'Fruit',
    value: 'fruit',
    choices: [
      { value: 'apple', label: 'Apple' },
      { value: 'pear', label: 'Pear' },
    ],
  },
  {
    label: 'Veg',
    value: 'veg',
    choices: [{ value: 'kale', label: 'Kale' }],
  },
];

/** Domain model with nested @tracked display field (used as Choices label). */
class Person {
  id: string;
  @tracked name: string;
  @tracked email: string;

  constructor(id: string, name: string, email: string) {
    this.id = id;
    this.name = name;
    this.email = email;
  }
}

/**
 * GQL/domain-style class that *is* Choices-compatible via InputChoice.
 * mapOptions reads value/label getters (and nested tracked fields).
 *
 * Note: InputChoice.id is optional **number** (Choices internal). Keep your
 * string primary key on another field (e.g. cityId) and expose it as `value`.
 */
class CityModel implements InputChoice {
  cityId: string;
  @tracked name: string;
  @tracked active = true;

  constructor(cityId: string, name: string) {
    this.cityId = cityId;
    this.name = name;
  }

  /** Choices selection id (string boundary). */
  get value(): string {
    return this.cityId;
  }

  /** Display text — reading @tracked name keeps the dropdown in sync. */
  get label(): string {
    return this.name;
  }

  get disabled(): boolean {
    return !this.active;
  }
}

/** Keep in sync with themes listed in app/styles/app.css @plugin daisyui. */
const DAISY_THEMES = [
  'light',
  'dark',
  'cupcake',
  'bumblebee',
  'emerald',
  'corporate',
  'synthwave',
  'retro',
  'cyberpunk',
  'valentine',
  'halloween',
  'garden',
  'forest',
  'aqua',
  'lofi',
  'pastel',
  'fantasy',
  'wireframe',
  'black',
  'luxury',
  'dracula',
  'cmyk',
  'autumn',
  'business',
  'acid',
  'lemonade',
  'night',
  'coffee',
  'winter',
  'dim',
  'nord',
  'sunset',
] as const;

type DaisyTheme = (typeof DAISY_THEMES)[number];

const THEME_STORAGE_KEY = 'choices-ember-demo-theme';

const TOC = [
  { id: 'single', label: 'Single select' },
  { id: 'multiple', label: 'Multiple + events' },
  { id: 'text', label: 'Text / tags + events' },
  { id: 'events', label: 'Event model' },
  { id: 'domain', label: 'Domain / GQL models' },
  { id: 'groups', label: 'Option groups' },
  { id: 'no-search', label: 'No search' },
  { id: 'async', label: 'Async preselect' },
  { id: 'tracked', label: 'Nested tracked labels' },
  { id: 'dependent', label: 'Dependent selects' },
  { id: 'fieldset', label: 'daisyUI fieldset' },
  { id: 'classnames', label: 'Override classNames' },
  { id: 'escape', label: 'Escape hatches' },
] as const;

let eventLogSeq = 0;

/** Safe display string for EventChoice fields (label may be non-string). */
function choiceFieldText(value: unknown): string {
  if (value == null) {
    return '';
  }
  if (
    typeof value === 'string' ||
    typeof value === 'number' ||
    typeof value === 'boolean'
  ) {
    return String(value);
  }
  return '';
}

function readStoredTheme(): DaisyTheme {
  if (typeof localStorage === 'undefined') {
    return 'light';
  }
  const stored = localStorage.getItem(THEME_STORAGE_KEY);
  if (stored && (DAISY_THEMES as readonly string[]).includes(stored)) {
    return stored as DaisyTheme;
  }
  return 'light';
}

function applyTheme(theme: DaisyTheme) {
  if (typeof document === 'undefined') {
    return;
  }
  document.documentElement.setAttribute('data-theme', theme);
  try {
    localStorage.setItem(THEME_STORAGE_KEY, theme);
  } catch {
    // ignore quota / private mode
  }
}

export default class ApplicationTemplate extends Component {
  toc = TOC;

  @tracked daisyTheme: DaisyTheme = readStoredTheme();

  constructor(owner: Owner, args: object) {
    super(owner, args);
    applyTheme(this.daisyTheme);
  }

  get daisyThemeOptions() {
    return DAISY_THEMES.map((name) => ({ value: name, label: name }));
  }

  /** Stable config object so Choices does not recreate on every re-render. */
  themeSelectConfig = { searchEnabled: true, shouldSort: false };
  noSearchConfig = { searchEnabled: false };
  textConfig = { maxItemCount: 5 };

  /**
   * Client override of the daisy classNames preset.
   * Merge order: DAISY_CLASS_NAMES ← @config.classNames (per-key replace).
   */
  customDaisyClassNames = {
    ...DAISY_CLASS_NAMES,
    containerOuter: [
      'choices',
      'w-full',
      'relative',
      'choices-ember--daisy',
      'ring-2',
      'ring-success/50',
      'rounded-full',
    ],
    containerInner: [
      'choices__inner',
      'input',
      'input-bordered',
      'input-success',
      'w-full',
      'min-h-14',
      'h-auto',
      'flex',
      'flex-wrap',
      'items-center',
      'gap-1.5',
      'py-2.5',
      'px-4',
      'rounded-full',
      'shadow-md',
    ],
    listDropdown: [
      'choices__list--dropdown',
      'menu',
      'w-full',
      'min-w-full',
      'bg-base-100',
      'text-base-content',
      'rounded-2xl',
      'shadow-2xl',
      'border-2',
      'border-success',
      'z-[100]',
      'p-2',
      'mt-2',
    ],
    itemChoice: ['choices__item--choice', 'rounded-xl', 'px-2'],
    highlightedState: [
      'is-highlighted',
      'bg-success',
      'text-success-content',
      'font-medium',
    ],
    button: [
      'choices__button',
      'btn',
      'btn-circle',
      'btn-success',
      'btn-xs',
      'min-h-0',
      'h-6',
      'w-6',
      'p-0',
    ],
  };

  customDaisyConfig = {
    classNames: this.customDaisyClassNames,
    searchEnabled: true,
  };

  // ── Recipes (shown under each live demo) ───────────────────────────

  recipeSingle = `<Choices
  @type="single"
  @options={{this.opts}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
  @placeholder="Pick one"
/>

// this.opts = [{ value: 'nyc', label: 'New York' }, …]
// this.selected: string | null
// onChange = (v) => { this.selected = v as string | null; }`;

  recipeMultiple = `import type { EventChoice } from 'choices.js';

@tracked ids: string[] = [];

// Source of truth for controlled selection — full array every time
onMulti = (v: string | string[] | null) => {
  this.ids = Array.isArray(v) ? v : [];
};

// Per-item user actions (Choices addItem / removeItem). Detail is EventChoice.
onMultiAdd = (detail: EventChoice) => {
  console.log('added', detail.value, detail.label);
  // side effects: analytics, toast — do NOT rebuild this.ids here if controlled
};

onMultiRemove = (detail: EventChoice) => {
  console.log('removed', detail.value, detail.label);
};

<Choices
  @type="multiple"
  @options={{this.opts}}
  @value={{this.ids}}
  @onChange={{this.onMulti}}
  @onAdd={{this.onMultiAdd}}
  @onRemove={{this.onMultiRemove}}
/>

// removeItemButton defaults true for multiple
// Disable: @config={{hash removeItemButton=false}}`;

  recipeText = `import type { EventChoice } from 'choices.js';

@tracked tags: string[] = [];

onTags = (v: string | string[] | null) => {
  this.tags = Array.isArray(v) ? v : [];
};

onTagAdd = (detail: EventChoice) => {
  // Enter / blur created a tag — detail.value is the tag string
};

onTagRemove = (detail: EventChoice) => {
  // remove button / backspace — detail.value is the removed tag
};

<Choices
  @type="text"
  @value={{this.tags}}
  @onChange={{this.onTags}}
  @onAdd={{this.onTagAdd}}
  @onRemove={{this.onTagRemove}}
  @placeholder="Add tag + Enter"
  @config={{hash maxItemCount=5}}
/>

// host is <input>; @options ignored in text mode`;

  recipeEvents = `// Callback roles
// ─────────────
// @onChange(value)  → full selection after a user edit.
//                     Use this to set controlled @value (string | string[] | null).
// @onAdd(detail)    → one item added by the user (Choices "addItem").
// @onRemove(detail) → one item removed by the user (Choices "removeItem").
// detail: EventChoice { value, label, groupValue?, … }

// Typical order on multi select: addItem/removeItem, then change.
// You may hear both; prefer @onChange for state, add/remove for side effects.

// Programmatic sync is silent
// ───────────────────────────
// Bridge sets syncing=true around setChoices / setChoiceByValue / setValue /
// removeActiveItems. During that window add/remove/change handlers no-op.
// So external @value / @options updates do NOT fire onAdd/onRemove.
// (Old dual-DOM + refresh() prototypes often did — false add/remove storms.)

// Anti-patterns
// ─────────────
// ✗ Derive this.ids only from onAdd/onRemove (missed events, races with onChange)
// ✗ set @value inside onAdd and also in onChange without care (double work / loops)
// ✓ this.ids = value from onChange; onAdd/onRemove for toasts / logging only

// Live multi below: interact and watch the event log.`;

  recipeDomain = `import type { InputChoice } from 'choices-ember';
// (re-exported from choices.js)

// Domain / GQL model that implements InputChoice
// Caution: InputChoice.id is number|undefined (Choices internal) —
// use cityId (or similar) for your string PK, expose it as value.
class City implements InputChoice {
  cityId: string;
  @tracked name: string;
  constructor(cityId: string, name: string) {
    this.cityId = cityId;
    this.name = name;
  }
  get value() {
    return this.cityId; // controlled @value is this string
  }
  get label() {
    return this.name; // tracked read → dropdown stays in sync
  }
}

@tracked cities = [
  new City('nyc', 'New York'),
  new City('sf', 'San Francisco'),
];
@tracked cityId: string | null = null;

// Pass class instances directly — mapOptions snapshots value/label
<Choices
  @options={{this.cities}}
  @value={{this.cityId}}
  @onChange={{this.onCity}}
/>

// Alternative: keep GraphQL types pure; map in a getter
get cityChoices(): InputChoice[] {
  return this.query.cities.map((c) => ({
    value: String(c.id),
    label: c.name,
  }));
}

// Extra fields (population, …) are fine on the class; Choices only sees
// the snapshot. Prefer customProperties if Choices search needs them.
// Do not dual-render <option>s — empty host + @options only.`;

  recipeGroups = `// options shape (InputGroup)
opts = [
  {
    label: 'Fruit',
    value: 'fruit',
    choices: [
      { value: 'apple', label: 'Apple' },
      { value: 'pear', label: 'Pear' },
    ],
  },
  {
    label: 'Veg',
    value: 'veg',
    choices: [{ value: 'kale', label: 'Kale' }],
  },
];

<Choices
  @type="single"
  @options={{this.opts}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
/>`;

  recipeNoSearch = `<Choices
  @type="single"
  @options={{this.opts}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
  @config={{hash searchEnabled=false}}
/>

// searchEnabled is a RECREATE_KEY — keep @config identity stable
// (class field / getter), or the instance rebuilds every render.`;

  recipeAsync = `// Entity page + async GQL (preselect)
// ─────────────────────────────────
// Problem: route/query returns entity.cityId before the cities list is ready
// (or the reverse). Old dual-DOM + refresh() often lost selection or painted blank.
//
// Pattern: ALWAYS hold the id on tracked @value from the entity. Feed @options
// when the list arrives. Order does not matter — the bridge re-applies @value
// after every setChoices.

@tracked cityOptions: { value: string; label: string }[] = [];
@tracked cityId: string | null = null; // from entity query
@tracked status = 'idle';

// Typical GraphQL / ember-data style load
async loadEntityPage() {
  this.status = 'loading entity…';
  this.cityOptions = [];           // list not ready yet
  // 1) Entity resolves first — preselect id immediately
  const entity = await this.store.queryRecord('place', { id: this.modelId });
  this.cityId = entity.cityId;     // e.g. 'sf' — even if options still []
  this.status = 'entity ready; loading cities…';

  // 2) Options resolve later — bridge setChoices then setChoiceByValue(@value)
  this.cityOptions = await this.store.query('city', { /* … */ });
  this.status = 'ready';
  // Do NOT clear cityId while options load.
  // Only clear if the id is missing from the final list:
  if (
    this.cityId != null &&
    !this.cityOptions.some((o) => o.value === this.cityId)
  ) {
    this.cityId = null;
  }
}

// Options-first is fine too:
async loadOptionsThenEntity() {
  this.cityOptions = await fetchCities();
  const entity = await fetchEntity();
  this.cityId = entity.cityId; // applyValue alone — options already present
}

<Choices
  @type="single"
  @options={{this.cityOptions}}
  @value={{this.cityId}}
  @onChange={{this.onCity}}
  @placeholder={{if this.cityOptions.length "Pick city" "Loading…"}}
  @disabled={{not this.cityOptions.length}}
/>

// Rules
// • Controlled: parent owns cityId; never rely on Choices internal store alone
// • Value may arrive before options (placeholder until list lands, then label)
// • Refreshing options: keep cityId; bridge re-selects after setChoices
// • String boundary: coerce ids to String(entity.cityId) if GQL returns numbers`;

  recipeTracked = `class Person {
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
  if (person) person.name = this.draftName; // label updates; id stays
}

<Choices
  @options={{this.choiceOptions}}
  @value={{this.selectedId}}
  @onChange={{this.onPersonChange}}
/>`;

  recipeDependent = `// Parent clears child value and swaps child options on change.
onCity = (v) => {
  this.city = v as string | null;
  this.station = null; // clear dependent
};

get stations() {
  return this.city ? STATIONS[this.city] ?? [] : [];
}

<ChoicesFieldset
  @legend="City"
  @options={{this.cities}}
  @value={{this.city}}
  @onChange={{this.onCity}}
/>
<ChoicesFieldset
  @legend="Station"
  @options={{this.stations}}
  @value={{this.station}}
  @onChange={{this.onStation}}
  @disabled={{not this.city}}
/>`;

  recipeFieldset = `<ChoicesFieldset
  @legend="Charge code"
  @description="Search by name or id"
  @type="single"
  @options={{this.choiceOptions}}
  @value={{this.selected}}
  @onChange={{this.onChange}}
  @fieldsetClass="bg-base-200 border-base-300 rounded-box border p-4 w-full"
/>

// Defaults: @theme="daisy", @class="w-full" on the inner <Choices>
// App must own Tailwind 4 + daisyUI 5 + layered Choices CSS imports.`;

  recipeClassNames = `import { DAISY_CLASS_NAMES } from 'choices-ember';

// Stable bag — classNames is a RECREATE_KEY
customConfig = {
  searchEnabled: true,
  classNames: {
    ...DAISY_CLASS_NAMES,
    containerInner: [
      'choices__inner', 'input', 'input-bordered', 'input-success',
      'w-full', 'min-h-14', 'rounded-full', /* … */
    ],
    listDropdown: [
      'choices__list--dropdown', 'menu', 'w-full', 'min-w-full',
      'border-2', 'border-success', /* … */
    ],
    // keep BEM hooks Choices JS needs (choices__*, is-*)
  },
};

<Choices
  @theme="daisy"
  @options={{this.opts}}
  @value={{this.v}}
  @onChange={{this.onChange}}
  @config={{this.customConfig}}
/>

// CSS: import Choices + daisyui-theme in layer(components)
// so Tailwind utilities can paint over stock Choices skin.`;

  recipeEscape = `<Choices
  @options={{this.opts}}
  @value={{this.v}}
  @onChange={{this.onChange}}
  @onReady={{this.onReady}}
  @registerAPI={{this.registerAPI}}
  @onSearch={{this.onSearch}}
  @onShowDropdown={{this.onShow}}
  @onHideDropdown={{this.onHide}}
  @syncKey={{this.version}}
/>

// registerAPI({ focus, clearStore, getValue, instance }) — null on destroy
// RECREATE_KEYS: searchEnabled, classNames, allowHTML,
//   callbackOnCreateTemplates, plus @theme and @type
// Full Choices 11 options: pass via @config`;

  @tracked stockDaisyValue: string | null = null;
  @tracked customDaisyValue: string | null = null;
  @tracked customDaisyMulti: string[] = [];
  @tracked noSearchValue: string | null = null;

  onStockDaisy = (v: string | string[] | null) => {
    this.stockDaisyValue = v as string | null;
  };
  onCustomDaisy = (v: string | string[] | null) => {
    this.customDaisyValue = v as string | null;
  };
  onCustomDaisyMulti = (v: string | string[] | null) => {
    this.customDaisyMulti = Array.isArray(v) ? v : [];
  };
  onNoSearch = (v: string | string[] | null) => {
    this.noSearchValue = v as string | null;
  };

  onDaisyThemeChange = (v: string | string[] | null) => {
    const next = (typeof v === 'string' ? v : null) as DaisyTheme | null;
    if (!next || !(DAISY_THEMES as readonly string[]).includes(next)) {
      return;
    }
    this.daisyTheme = next;
    applyTheme(next);
  };

  @tracked single: string | null = null;
  @tracked multi: string[] = [];
  @tracked tags: string[] = [];
  /** Newest-first feeds for multi / text / events demos */
  @tracked multiLog: EventLogLine[] = [];
  @tracked tagsLog: EventLogLine[] = [];
  @tracked eventsLog: EventLogLine[] = [];
  @tracked eventsMulti: string[] = [];
  /** Domain models implementing InputChoice (GQL-style) */
  @tracked domainCities: CityModel[] = [
    new CityModel('nyc', 'New York'),
    new CityModel('sf', 'San Francisco'),
    new CityModel('ldn', 'London'),
  ];
  @tracked domainCityId: string | null = null;
  @tracked city: string | null = null;
  @tracked station: string | null = null;
  @tracked remote: { value: string; label: string }[] = [];
  @tracked remoteValue: string | null = null;
  @tracked remoteLoading = false;
  @tracked remoteLoadCount = 0;
  /** Human timeline for the async preselect demo */
  @tracked remoteStatus = 'Idle — run a load scenario below';
  @tracked groupValue: string | null = null;

  // ── Nested tracked domain objects ─────────────────────────────────
  @tracked people: Person[] = [
    new Person('1', 'Ada Lovelace', 'ada@example.com'),
    new Person('2', 'Grace Hopper', 'grace@example.com'),
    new Person('3', 'Alan Turing', 'alan@example.com'),
  ];
  @tracked selectedPersonId: string | null = null;
  @tracked draftName = '';
  @tracked draftEmail = '';
  @tracked personSavedMessage: string | null = null;

  // Escape-hatch demo state
  @tracked apiLog = '';
  escapeApi: {
    focus: () => void;
    clearStore: () => void;
    getValue: (valueOnly?: boolean) => unknown;
  } | null = null;

  get personOptions() {
    return this.people.map((person) => ({
      value: person.id,
      label: person.name,
    }));
  }

  get selectedPerson(): Person | null {
    if (!this.selectedPersonId) {
      return null;
    }
    return this.people.find((p) => p.id === this.selectedPersonId) ?? null;
  }

  get stations() {
    if (!this.city) {
      return [];
    }
    return STATIONS[this.city] ?? [];
  }

  get stationDisabled() {
    return !this.city;
  }

  /** Template-safe string dumps for array values */
  get multiLabel(): string {
    return this.multi.length ? this.multi.join(', ') : '—';
  }

  get tagsLabel(): string {
    return this.tags.length ? this.tags.join(', ') : '—';
  }

  pushEventLog(
    target: 'multi' | 'tags' | 'events',
    kind: EventLogLine['kind'],
    summary: string,
  ) {
    const line: EventLogLine = {
      id: ++eventLogSeq,
      kind,
      badgeClass: KIND_BADGE[kind],
      summary,
    };
    if (target === 'multi') {
      this.multiLog = [line, ...this.multiLog].slice(0, 14);
    } else if (target === 'tags') {
      this.tagsLog = [line, ...this.tagsLog].slice(0, 14);
    } else {
      this.eventsLog = [line, ...this.eventsLog].slice(0, 14);
    }
  }

  clearMultiLog = () => {
    this.multiLog = [];
  };

  clearTagsLog = () => {
    this.tagsLog = [];
  };

  clearEventsLog = () => {
    this.eventsLog = [];
  };

  onSingle = (v: string | string[] | null) => {
    this.single = v as string | null;
  };

  onDomainCity = (v: string | string[] | null) => {
    this.domainCityId = v as string | null;
  };

  renameDomainCity = () => {
    const city = this.domainCities.find((c) => c.cityId === this.domainCityId);
    if (city) {
      city.name = `${city.name.replace(/ \(renamed.*\)/, '')} (renamed)`;
    }
  };

  get eventsMultiLabel(): string {
    return this.eventsMulti.length ? this.eventsMulti.join(', ') : '—';
  }

  get domainCityLabel(): string {
    const city = this.domainCities.find((c) => c.cityId === this.domainCityId);
    return city ? `${city.label} [${city.value}]` : '—';
  }

  get domainRenameDisabled(): boolean {
    return this.domainCityId == null;
  }

  onMulti = (v: string | string[] | null) => {
    this.multi = Array.isArray(v) ? v : [];
    this.pushEventLog(
      'multi',
      'change',
      `onChange → [${this.multi.join(', ') || '∅'}]`,
    );
  };

  onMultiAdd = (detail: EventChoice) => {
    this.pushEventLog(
      'multi',
      'add',
      `onAdd → value=${choiceFieldText(detail.value)} label=${choiceFieldText(detail.label)}`,
    );
  };

  onMultiRemove = (detail: EventChoice) => {
    this.pushEventLog(
      'multi',
      'remove',
      `onRemove → value=${choiceFieldText(detail.value)} label=${choiceFieldText(detail.label)}`,
    );
  };

  onTags = (v: string | string[] | null) => {
    this.tags = Array.isArray(v) ? v : [];
    this.pushEventLog(
      'tags',
      'change',
      `onChange → [${this.tags.join(', ') || '∅'}]`,
    );
  };

  onTagAdd = (detail: EventChoice) => {
    this.pushEventLog(
      'tags',
      'add',
      `onAdd → value=${choiceFieldText(detail.value)}`,
    );
  };

  onTagRemove = (detail: EventChoice) => {
    this.pushEventLog(
      'tags',
      'remove',
      `onRemove → value=${choiceFieldText(detail.value)}`,
    );
  };

  pushEventsDemoLog(kind: EventLogLine['kind'], summary: string) {
    const line: EventLogLine = {
      id: ++eventLogSeq,
      kind,
      badgeClass: KIND_BADGE[kind],
      summary,
    };
    this.eventsLog = [line, ...this.eventsLog].slice(0, 14);
  }

  onEventsMulti = (v: string | string[] | null) => {
    this.eventsMulti = Array.isArray(v) ? v : [];
    this.pushEventsDemoLog(
      'change',
      `onChange → [${this.eventsMulti.join(', ') || '∅'}]  ← set @value from this`,
    );
  };

  onEventsAdd = (detail: EventChoice) => {
    this.pushEventsDemoLog(
      'add',
      `onAdd → value=${choiceFieldText(detail.value)} label=${choiceFieldText(detail.label)}  ← side effects only`,
    );
  };

  onEventsRemove = (detail: EventChoice) => {
    this.pushEventsDemoLog(
      'remove',
      `onRemove → value=${choiceFieldText(detail.value)} label=${choiceFieldText(detail.label)}  ← side effects only`,
    );
  };

  onCity = (v: string | string[] | null) => {
    this.city = v as string | null;
    this.station = null;
  };
  onStation = (v: string | string[] | null) => {
    this.station = v as string | null;
  };
  onGroup = (v: string | string[] | null) => {
    this.groupValue = v as string | null;
  };
  onRemote = (v: string | string[] | null) => {
    this.remoteValue = v as string | null;
  };

  delay = (ms: number) => new Promise((r) => setTimeout(r, ms));

  /**
   * Entity-first: GQL entity returns selected id, then the options list arrives.
   * Mirrors “open entity page → preselect city from model → cities query settles”.
   */
  loadEntityThenOptions = async () => {
    this.remoteLoading = true;
    this.remote = [];
    this.remoteValue = null;
    this.remoteStatus = '1) Loading entity… (options still empty)';

    await this.delay(350);
    // Entity payload includes the foreign key to preselect
    this.remoteValue = 'b';
    this.remoteStatus =
      '2) Entity ready — @value="b" set while @options still []. Waiting on list…';

    await this.delay(450);
    this.remoteLoadCount += 1;
    const n = this.remoteLoadCount;
    this.remote = [
      { value: 'a', label: `Alpha (load #${n})` },
      { value: 'b', label: `Beta (load #${n})` },
      { value: 'c', label: `Charlie (load #${n})` },
    ];
    this.remoteStatus =
      '3) Options arrived — bridge re-applied @value; UI should show Beta';
    this.remoteLoading = false;
  };

  /**
   * Options-first: list loads, then entity id is assigned (still controlled).
   */
  loadOptionsThenEntity = async () => {
    this.remoteLoading = true;
    this.remote = [];
    this.remoteValue = null;
    this.remoteStatus = '1) Loading options… (no @value yet)';

    await this.delay(400);
    this.remoteLoadCount += 1;
    const n = this.remoteLoadCount;
    this.remote = [
      { value: 'a', label: `Alpha (load #${n})` },
      { value: 'b', label: `Beta (load #${n})` },
      { value: 'c', label: `Charlie (load #${n})` },
    ];
    this.remoteStatus = '2) Options ready — loading entity for preselect…';

    await this.delay(300);
    this.remoteValue = 'c';
    this.remoteStatus =
      '3) Entity set @value="c" — bridge applyValue; UI should show Charlie';
    this.remoteLoading = false;
  };

  /** Refresh list without clearing selection when id still exists. */
  loadRemote = async () => {
    this.remoteLoading = true;
    this.personSavedMessage = null;
    const previousValue = this.remoteValue;
    this.remoteStatus = 'Refreshing options — keeping @value if still present…';

    await this.delay(400);
    this.remoteLoadCount += 1;
    const n = this.remoteLoadCount;

    this.remote = [
      { value: 'a', label: `Alpha (load #${n})` },
      { value: 'b', label: `Beta (load #${n})` },
      ...(n > 1 ? [{ value: 'c', label: `Charlie (load #${n})` }] : []),
    ];

    if (
      previousValue != null &&
      !this.remote.some((o) => o.value === previousValue)
    ) {
      this.remoteValue = null;
      this.remoteStatus = 'Refresh done — previous id gone; cleared @value';
    } else {
      this.remoteStatus = previousValue
        ? `Refresh done — kept @value="${previousValue}" (label may update)`
        : 'Refresh done — no prior selection';
    }

    this.remoteLoading = false;
  };

  resetRemote = () => {
    this.remote = [];
    this.remoteValue = null;
    this.remoteStatus = 'Reset — idle';
    this.remoteLoading = false;
  };

  onPersonChange = (v: string | string[] | null) => {
    this.selectedPersonId = v as string | null;
    this.personSavedMessage = null;
    const person = this.selectedPerson;
    if (person) {
      this.draftName = person.name;
      this.draftEmail = person.email;
    } else {
      this.draftName = '';
      this.draftEmail = '';
    }
  };

  onDraftNameInput = (event: Event) => {
    this.draftName = (event.target as HTMLInputElement).value;
  };

  onDraftEmailInput = (event: Event) => {
    this.draftEmail = (event.target as HTMLInputElement).value;
  };

  savePerson = (event: Event) => {
    event.preventDefault();
    const person = this.selectedPerson;
    if (!person) {
      return;
    }
    person.name = this.draftName.trim() || person.name;
    person.email = this.draftEmail.trim() || person.email;
    this.personSavedMessage = `Saved “${person.name}” — dropdown label updates without changing selection (${person.id}).`;
  };

  registerEscapeAPI = (
    api: {
      focus: () => void;
      clearStore: () => void;
      getValue: (valueOnly?: boolean) => unknown;
    } | null,
  ) => {
    this.escapeApi = api;
    this.apiLog = api ? 'API registered' : 'API cleared (destroyed)';
  };

  onEscapeReady = () => {
    this.apiLog = 'onReady fired';
  };

  focusEscape = () => {
    this.escapeApi?.focus();
    this.apiLog = 'focus()';
  };

  clearEscape = () => {
    this.escapeApi?.clearStore();
    this.single = null;
    this.apiLog = `clearStore(); getValue → ${JSON.stringify(this.escapeApi?.getValue(true))}`;
  };

  <template>
    {{pageTitle "choices-ember cookbook"}}

    <header
      class="sticky top-0 z-[200] border-b border-base-300 bg-base-100/95 backdrop-blur px-4 py-3"
      data-cookbook-header
    >
      <div
        class="max-w-3xl mx-auto flex flex-wrap items-center gap-3 justify-between"
      >
        <div class="min-w-0">
          <p class="font-semibold leading-tight">choices-ember cookbook</p>
          <p class="text-xs opacity-60">Live demos + recipes — not a mystery
            gallery</p>
        </div>
        <label
          class="flex items-center gap-2 min-w-[12rem] grow sm:grow-0 sm:w-56"
        >
          <span class="text-sm whitespace-nowrap opacity-80">Theme</span>
          <div class="grow">
            <Choices
              @type="single"
              @theme="daisy"
              @options={{this.daisyThemeOptions}}
              @value={{this.daisyTheme}}
              @onChange={{this.onDaisyThemeChange}}
              @config={{this.themeSelectConfig}}
              @placeholder="Theme"
            />
          </div>
        </label>
      </div>
    </header>

    <main class="p-6 max-w-3xl mx-auto space-y-10">
      <div class="space-y-3">
        <h1 class="text-3xl font-bold tracking-tight">Cookbook</h1>
        <p class="opacity-80 leading-relaxed">
          Each section is a
          <strong>working recipe</strong>: live control first, then the exact
          Ember pattern to copy. Choices owns the widget DOM; you own tracked
          data and
          <code class="text-sm">@onChange</code>.
        </p>
        <p class="text-sm opacity-60">
          CSS for
          <code>@theme="daisy"</code>: load Choices +
          <code>daisyui-theme.css</code>
          in
          <code>layer(components)</code>
          so Tailwind utilities can win. See README.
        </p>
      </div>

      <nav
        class="rounded-box border border-base-300 bg-base-200/50 p-4"
        aria-label="Cookbook sections"
      >
        <p class="text-xs font-medium uppercase tracking-wide opacity-50 mb-2">
          Jump to
        </p>
        <ul class="flex flex-wrap gap-2">
          {{#each this.toc as |item|}}
            <li>
              <a
                href="#{{item.id}}"
                class="btn btn-xs btn-ghost border border-base-300"
              >{{item.label}}</a>
            </li>
          {{/each}}
        </ul>
      </nav>

      <CookbookSection
        @id="single"
        @title="Single select"
        @blurb="Controlled string | null. Empty host &lt;select&gt; — no dual-DOM options."
        @code={{this.recipeSingle}}
      >
        <Choices
          @type="single"
          @options={{CITIES}}
          @value={{this.single}}
          @onChange={{this.onSingle}}
          @placeholder="Pick a city"
        />
        <p class="text-sm opacity-70">value:
          <code>{{this.single}}</code></p>
      </CookbookSection>

      <CookbookSection
        @id="multiple"
        @title="Multiple + onAdd / onRemove"
        @blurb="Controlled string[] via @onChange. Wire @onAdd / @onRemove for per-item user actions (EventChoice detail). removeItemButton defaults true. Watch the log: add/remove fire first, then onChange with the full array."
        @code={{this.recipeMultiple}}
      >
        <Choices
          @type="multiple"
          @options={{CITIES}}
          @value={{this.multi}}
          @onChange={{this.onMulti}}
          @onAdd={{this.onMultiAdd}}
          @onRemove={{this.onMultiRemove}}
        />
        <p class="text-sm opacity-70">@value:
          <code>{{this.multiLabel}}</code></p>
        <div class="space-y-2">
          <div class="flex items-center justify-between gap-2">
            <p class="text-xs font-medium uppercase tracking-wide opacity-50">
              Event log
            </p>
            <button
              type="button"
              class="btn btn-ghost btn-xs"
              {{on "click" this.clearMultiLog}}
            >Clear</button>
          </div>
          {{#if this.multiLog.length}}
            <ul
              class="font-mono text-xs space-y-1 max-h-40 overflow-y-auto rounded-box bg-base-200 p-2"
            >
              {{#each this.multiLog as |line|}}
                <li>
                  <span
                    class="badge badge-xs mr-1 {{line.badgeClass}}"
                  >{{line.kind}}</span>
                  {{line.summary}}
                </li>
              {{/each}}
            </ul>
          {{else}}
            <p class="text-xs opacity-50">Select or remove cities — events
              appear here.</p>
          {{/if}}
        </div>
      </CookbookSection>

      <CookbookSection
        @id="text"
        @title="Text / tags + onAdd / onRemove"
        @blurb="Host is an &lt;input&gt;. Tags are string[]. Enter adds (onAdd + onChange); remove button / backspace fires onRemove + onChange. maxItemCount via @config."
        @code={{this.recipeText}}
      >
        <Choices
          @type="text"
          @value={{this.tags}}
          @onChange={{this.onTags}}
          @onAdd={{this.onTagAdd}}
          @onRemove={{this.onTagRemove}}
          @placeholder="Add tag + Enter"
          @config={{this.textConfig}}
        />
        <p class="text-sm opacity-70">@value:
          <code>{{this.tagsLabel}}</code></p>
        <div class="space-y-2">
          <div class="flex items-center justify-between gap-2">
            <p class="text-xs font-medium uppercase tracking-wide opacity-50">
              Event log
            </p>
            <button
              type="button"
              class="btn btn-ghost btn-xs"
              {{on "click" this.clearTagsLog}}
            >Clear</button>
          </div>
          {{#if this.tagsLog.length}}
            <ul
              class="font-mono text-xs space-y-1 max-h-40 overflow-y-auto rounded-box bg-base-200 p-2"
            >
              {{#each this.tagsLog as |line|}}
                <li>
                  <span
                    class="badge badge-xs mr-1 {{line.badgeClass}}"
                  >{{line.kind}}</span>
                  {{line.summary}}
                </li>
              {{/each}}
            </ul>
          {{else}}
            <p class="text-xs opacity-50">Add or remove tags — events appear
              here.</p>
          {{/if}}
        </div>
      </CookbookSection>

      <CookbookSection
        @id="events"
        @title="Event model (onChange vs onAdd / onRemove)"
        @blurb="Use @onChange for controlled @value. Use @onAdd / @onRemove for per-item side effects. Programmatic sync is silent (no false add/remove). Interact with the multi below and watch order: add/remove, then change."
        @code={{this.recipeEvents}}
      >
        <Choices
          @type="multiple"
          @options={{CITIES}}
          @value={{this.eventsMulti}}
          @onChange={{this.onEventsMulti}}
          @onAdd={{this.onEventsAdd}}
          @onRemove={{this.onEventsRemove}}
          @placeholder="Select cities — watch the log"
        />
        <p class="text-sm opacity-70">@value:
          <code>{{this.eventsMultiLabel}}</code></p>
        <ul class="text-sm space-y-1 list-disc pl-5 opacity-80">
          <li>
            <strong>@onChange</strong>
            → set controlled
            <code>@value</code>
            (full array / string)
          </li>
          <li>
            <strong>@onAdd / @onRemove</strong>
            →
            <code>EventChoice</code>
            detail; toasts / analytics — not the only state path
          </li>
          <li>
            Bridge
            <code>syncing</code>
            suppresses events during
            <code>setChoices</code>
            /
            <code>setChoiceByValue</code>
          </li>
        </ul>
        <div class="space-y-2">
          <div class="flex items-center justify-between gap-2">
            <p class="text-xs font-medium uppercase tracking-wide opacity-50">
              Event log
            </p>
            <button
              type="button"
              class="btn btn-ghost btn-xs"
              {{on "click" this.clearEventsLog}}
            >Clear</button>
          </div>
          {{#if this.eventsLog.length}}
            <ul
              class="font-mono text-xs space-y-1 max-h-40 overflow-y-auto rounded-box bg-base-200 p-2"
            >
              {{#each this.eventsLog as |line|}}
                <li>
                  <span
                    class="badge badge-xs mr-1 {{line.badgeClass}}"
                  >{{line.kind}}</span>
                  {{line.summary}}
                </li>
              {{/each}}
            </ul>
          {{else}}
            <p class="text-xs opacity-50">Add or remove cities — events appear
              here.</p>
          {{/if}}
        </div>
      </CookbookSection>

      <CookbookSection
        @id="domain"
        @title="Domain / GQL models (InputChoice)"
        @blurb="Class instances from GraphQL can implement InputChoice (value + label getters). Pass them as @options; mapOptions snapshots fields. Controlled @value stays the string id. Rename mutates @tracked name — label updates without changing selection."
        @code={{this.recipeDomain}}
      >
        <Choices
          @type="single"
          @options={{this.domainCities}}
          @value={{this.domainCityId}}
          @onChange={{this.onDomainCity}}
          @placeholder="Pick a CityModel instance"
        />
        <p class="text-sm opacity-70">
          selected:
          <code>{{this.domainCityLabel}}</code>
        </p>
        <button
          type="button"
          class="btn btn-sm"
          disabled={{this.domainRenameDisabled}}
          {{on "click" this.renameDomainCity}}
        >
          Rename selected model’s name
        </button>
        <p class="text-xs opacity-60">
          Extra domain fields on the class are fine. Prefer a mapping getter if
          you want GraphQL types to stay free of Choices shapes.
        </p>
      </CookbookSection>

      <CookbookSection
        @id="groups"
        @title="Option groups"
        @blurb="Pass InputGroup objects: { label, value, choices: InputChoice[] }. Bridge maps them into Choices setChoices."
        @code={{this.recipeGroups}}
      >
        <Choices
          @type="single"
          @options={{GROUPED}}
          @value={{this.groupValue}}
          @onChange={{this.onGroup}}
          @placeholder="Pick fruit or veg"
        />
        <p class="text-sm opacity-70">value:
          <code>{{this.groupValue}}</code></p>
      </CookbookSection>

      <CookbookSection
        @id="no-search"
        @title="No search"
        @blurb="Pass searchEnabled: false in a stable @config object (recreate key)."
        @code={{this.recipeNoSearch}}
      >
        <Choices
          @type="single"
          @options={{CITIES}}
          @value={{this.noSearchValue}}
          @onChange={{this.onNoSearch}}
          @config={{this.noSearchConfig}}
          @placeholder="No search field"
        />
      </CookbookSection>

      <CookbookSection
        @id="async"
        @title="Async preselect (entity page / GQL)"
        @blurb="Hold the foreign key on controlled @value as soon as the entity query returns. Feed @options when the list query returns. Order does not matter — after setChoices the bridge re-applies @value (no dual-DOM race)."
        @code={{this.recipeAsync}}
      >
        <p
          class="text-sm rounded-box bg-base-200 px-3 py-2 font-mono leading-relaxed"
        >
          {{this.remoteStatus}}
        </p>
        <div class="flex gap-2 items-center flex-wrap">
          <button
            type="button"
            class="btn btn-sm btn-primary"
            disabled={{this.remoteLoading}}
            {{on "click" this.loadEntityThenOptions}}
          >
            Entity first → options
          </button>
          <button
            type="button"
            class="btn btn-sm btn-secondary"
            disabled={{this.remoteLoading}}
            {{on "click" this.loadOptionsThenEntity}}
          >
            Options first → entity
          </button>
          <button
            type="button"
            class="btn btn-sm"
            disabled={{this.remoteLoading}}
            {{on "click" this.loadRemote}}
          >
            Refresh options
          </button>
          <button
            type="button"
            class="btn btn-sm btn-ghost"
            disabled={{this.remoteLoading}}
            {{on "click" this.resetRemote}}
          >
            Reset
          </button>
        </div>
        <p class="text-sm opacity-70">
          @value:
          <code>{{this.remoteValue}}</code>
          · options:
          <code>{{this.remote.length}}</code>
        </p>
        <Choices
          @type="single"
          @options={{this.remote}}
          @value={{this.remoteValue}}
          @onChange={{this.onRemote}}
          @placeholder={{if
            this.remote.length
            "Pick — or re-run a load scenario"
            "Waiting for options…"
          }}
          @disabled={{this.remoteLoading}}
        />
      </CookbookSection>

      <CookbookSection
        @id="tracked"
        @title="Nested tracked labels + edit form"
        @blurb="Map domain objects in a getter that reads @tracked fields (e.g. name). Mutating the domain updates the dropdown label without changing the selected id."
        @code={{this.recipeTracked}}
      >
        <Choices
          @type="single"
          @options={{this.personOptions}}
          @value={{this.selectedPersonId}}
          @onChange={{this.onPersonChange}}
          @placeholder="Select a person"
        />
        <p class="text-sm opacity-70">selected id:
          <code>{{this.selectedPersonId}}</code></p>

        {{#if this.selectedPerson}}
          <form
            class="space-y-3 p-4 border border-base-300 rounded-box bg-base-200"
            {{on "submit" this.savePerson}}
          >
            <p class="text-sm font-medium">Edit person #{{this.selectedPerson.id}}</p>
            <label class="form-control w-full">
              <span class="label-text">Name</span>
              <input
                class="input input-bordered w-full"
                value={{this.draftName}}
                {{on "input" this.onDraftNameInput}}
              />
            </label>
            <label class="form-control w-full">
              <span class="label-text">Email</span>
              <input
                class="input input-bordered w-full"
                type="email"
                value={{this.draftEmail}}
                {{on "input" this.onDraftEmailInput}}
              />
            </label>
            <button type="submit" class="btn btn-primary btn-sm">
              Save (updates dropdown label)
            </button>
            {{#if this.personSavedMessage}}
              <p class="text-sm text-success">{{this.personSavedMessage}}</p>
            {{/if}}
          </form>
        {{else}}
          <p class="text-sm opacity-60">Select someone to open the form.</p>
        {{/if}}
      </CookbookSection>

      <CookbookSection
        @id="dependent"
        @title="Dependent selects"
        @blurb="Two components. Parent onChange clears the child value and swaps child @options. Disable the child until parent is set."
        @code={{this.recipeDependent}}
      >
        <div class="space-y-4">
          <ChoicesFieldset
            @legend="City"
            @description="Pick first"
            @type="single"
            @options={{CITIES}}
            @value={{this.city}}
            @onChange={{this.onCity}}
            @fieldsetClass="bg-base-200 border-base-300 rounded-box border p-4 w-full"
          />
          <ChoicesFieldset
            @legend="Station"
            @description="Depends on city"
            @type="single"
            @options={{this.stations}}
            @value={{this.station}}
            @onChange={{this.onStation}}
            @disabled={{this.stationDisabled}}
            @fieldsetClass="bg-base-200 border-base-300 rounded-box border p-4 w-full"
          />
        </div>
        <p class="text-sm opacity-70">city:
          <code>{{this.city}}</code>
          · station:
          <code>{{this.station}}</code></p>
      </CookbookSection>

      <CookbookSection
        @id="fieldset"
        @title="daisyUI fieldset chrome"
        @blurb='ChoicesFieldset is composition only: legend / description + inner Choices @theme="daisy". Compare with a native daisy input below.'
        @code={{this.recipeFieldset}}
      >
        <ChoicesFieldset
          @legend="Charge code"
          @description="Same chrome as dependent selects above"
          @type="single"
          @options={{CITIES}}
          @value={{this.single}}
          @onChange={{this.onSingle}}
          @fieldsetClass="bg-base-200 border-base-300 rounded-box border p-4 w-full"
        />
        <div class="space-y-1">
          <p class="text-xs font-medium uppercase tracking-wide opacity-50">
            Native daisy (compare)
          </p>
          <input
            class="input input-bordered w-full"
            placeholder="Native daisy input"
            aria-label="Native daisy input comparison"
          />
        </div>
      </CookbookSection>

      <CookbookSection
        @id="classnames"
        @title="Override daisy classNames"
        @blurb='Spread DAISY_CLASS_NAMES, replace slots, pass via @config.classNames. Keep @theme="daisy" for CSS vars. Dropdown should stay full width of the control (w-full on listDropdown + theme CSS).'
        @code={{this.recipeClassNames}}
      >
        <div class="grid gap-4 sm:grid-cols-2">
          <div class="space-y-2">
            <p class="text-sm font-medium">Stock
              <code>@theme="daisy"</code></p>
            <Choices
              @type="single"
              @theme="daisy"
              @options={{CITIES}}
              @value={{this.stockDaisyValue}}
              @onChange={{this.onStockDaisy}}
              @placeholder="Default daisy preset"
              @class="w-full"
            />
          </div>
          <div class="space-y-2">
            <p class="text-sm font-medium">Custom
              <code>classNames</code>
              (pill + success)</p>
            <Choices
              @type="single"
              @theme="daisy"
              @options={{CITIES}}
              @value={{this.customDaisyValue}}
              @onChange={{this.onCustomDaisy}}
              @config={{this.customDaisyConfig}}
              @placeholder="Overridden classNames"
              @class="w-full"
            />
          </div>
        </div>
        <div class="space-y-2">
          <p class="text-sm font-medium">Multi + custom remove (<code
            >btn-circle</code>)</p>
          <Choices
            @type="multiple"
            @theme="daisy"
            @options={{CITIES}}
            @value={{this.customDaisyMulti}}
            @onChange={{this.onCustomDaisyMulti}}
            @config={{this.customDaisyConfig}}
            @class="w-full"
          />
        </div>
      </CookbookSection>

      <CookbookSection
        @id="escape"
        @title="Escape hatches"
        @blurb="registerAPI / onReady for imperative focus & clear. Prefer controlled @value for app state. Pass any Choices 11 option through @config."
        @code={{this.recipeEscape}}
      >
        <Choices
          @type="single"
          @options={{CITIES}}
          @value={{this.single}}
          @onChange={{this.onSingle}}
          @registerAPI={{this.registerEscapeAPI}}
          @onReady={{this.onEscapeReady}}
          @placeholder="API demo shares single value"
        />
        <div class="flex flex-wrap gap-2">
          <button
            type="button"
            class="btn btn-sm"
            {{on "click" this.focusEscape}}
          >API focus()</button>
          <button
            type="button"
            class="btn btn-sm"
            {{on "click" this.clearEscape}}
          >API clearStore()</button>
        </div>
        <p class="text-sm opacity-70">log:
          <code>{{this.apiLog}}</code></p>
      </CookbookSection>

      <footer class="text-sm opacity-60 pb-8 space-y-1">
        <p>
          Source of this page:
          <code>test-app/app/templates/application.gts</code>
        </p>
        <p>
          Markdown index:
          <code>docs/COOKBOOK.md</code>
          (points here)
        </p>
      </footer>
    </main>
  </template>
}

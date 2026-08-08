import { pageTitle } from 'ember-page-title';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import type Owner from '@ember/owner';
import Choices from 'choices-ember/components/choices';
import ChoicesFieldset from 'choices-ember/components/choices-fieldset';

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
  @tracked daisyTheme: DaisyTheme = readStoredTheme();

  constructor(owner: Owner, args: object) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    super(owner, args as any);
    applyTheme(this.daisyTheme);
  }

  get daisyThemeOptions() {
    return DAISY_THEMES.map((name) => ({ value: name, label: name }));
  }

  /** Stable config object so Choices does not recreate on every re-render. */
  themeSelectConfig = { searchEnabled: true, shouldSort: false };

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
  @tracked city: string | null = null;
  @tracked station: string | null = null;
  @tracked remote: { value: string; label: string }[] = [];
  @tracked remoteValue: string | null = null;
  @tracked remoteLoading = false;
  @tracked remoteLoadCount = 0;
  @tracked groupValue: string | null = null;

  // ── Nested tracked domain objects ─────────────────────────────────
  @tracked people: Person[] = [
    new Person('1', 'Ada Lovelace', 'ada@example.com'),
    new Person('2', 'Grace Hopper', 'grace@example.com'),
    new Person('3', 'Alan Turing', 'alan@example.com'),
  ];
  @tracked selectedPersonId: string | null = null;
  /** Draft fields for the edit form (not the domain object until submit). */
  @tracked draftName = '';
  @tracked draftEmail = '';
  @tracked personSavedMessage: string | null = null;

  /**
   * Map domain → choice snapshots. Reading `person.name` (tracked) here
   * is what keeps the dropdown label in sync when the form submits.
   */
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

  onSingle = (v: string | string[] | null) => {
    this.single = v as string | null;
  };
  onMulti = (v: string | string[] | null) => {
    this.multi = Array.isArray(v) ? v : [];
  };
  onTags = (v: string | string[] | null) => {
    this.tags = Array.isArray(v) ? v : [];
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

  /**
   * Parent-owned async load. Replaces `@options` when the request settles.
   * Keeps `@value` if the selected id still exists in the new list.
   */
  loadRemote = async () => {
    this.remoteLoading = true;
    this.personSavedMessage = null;
    // Keep previous options visible while loading (optional UX);
    // do NOT clear remoteValue so controlled selection survives refresh.
    const previousValue = this.remoteValue;

    await new Promise((r) => setTimeout(r, 400));
    this.remoteLoadCount += 1;
    const n = this.remoteLoadCount;

    // Simulate a refetch that may add/rename items but still includes
    // previously selected ids so the selection can stick.
    this.remote = [
      { value: 'a', label: `Alpha (load #${n})` },
      { value: 'b', label: `Beta (load #${n})` },
      ...(n > 1 ? [{ value: 'c', label: `Charlie (load #${n})` }] : []),
    ];

    // Preserve selection when the value is still present; only clear if gone.
    if (
      previousValue != null &&
      !this.remote.some((o) => o.value === previousValue)
    ) {
      this.remoteValue = null;
    }
    // else leave this.remoteValue as-is — bridge re-applies it after setChoices

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

  /**
   * Mutate nested @tracked fields on the domain object.
   * Dropdown labels update because personOptions reads person.name.
   */
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

  <template>
    {{pageTitle 'choices-ember demo'}}

    <header
      class='sticky top-0 z-[200] border-b border-base-300 bg-base-100/95 backdrop-blur px-4 py-3'
    >
      <div
        class='max-w-2xl mx-auto flex flex-wrap items-center gap-3 justify-between'
      >
        <div class='min-w-0'>
          <p class='font-semibold leading-tight'>choices-ember demo</p>
          <p class='text-xs opacity-60'>daisyUI theme → data-theme on &lt;html&gt;</p>
        </div>
        <label class='flex items-center gap-2 min-w-[12rem] grow sm:grow-0 sm:w-56'>
          <span class='text-sm whitespace-nowrap opacity-80'>Theme</span>
          <div class='grow'>
            <Choices
              @type='single'
              @theme='daisy'
              @options={{this.daisyThemeOptions}}
              @value={{this.daisyTheme}}
              @onChange={{this.onDaisyThemeChange}}
              @config={{this.themeSelectConfig}}
              @placeholder='Theme'
            />
          </div>
        </label>
      </div>
    </header>

    <main class='demo p-6 max-w-2xl mx-auto space-y-8'>
      <h1 class='text-2xl font-bold'>choices-ember</h1>
      <p class='opacity-70'>
        Phase 1–4 walking demos. Stock Choices CSS + daisyUI fieldset. Switch
        themes above — Choices
        <code>@theme="daisy"</code>
        follows CSS variables.
      </p>

      <section class='space-y-2'>
        <h2 class='text-lg font-semibold'>Single (Choices default skin)</h2>
        <Choices
          @type='single'
          @options={{CITIES}}
          @value={{this.single}}
          @onChange={{this.onSingle}}
          @placeholder='Pick a city'
        />
        <p class='text-sm'>value: {{this.single}}</p>
      </section>

      <section class='space-y-2'>
        <h2 class='text-lg font-semibold'>Multiple</h2>
        <Choices
          @type='multiple'
          @options={{CITIES}}
          @value={{this.multi}}
          @onChange={{this.onMulti}}
        />
      </section>

      <section class='space-y-2'>
        <h2 class='text-lg font-semibold'>Text tags</h2>
        <Choices
          @type='text'
          @value={{this.tags}}
          @onChange={{this.onTags}}
          @placeholder='Add tag + Enter'
        />
      </section>

      <section class='space-y-2'>
        <h2 class='text-lg font-semibold'>Groups</h2>
        <Choices
          @type='single'
          @options={{GROUPED}}
          @value={{this.groupValue}}
          @onChange={{this.onGroup}}
        />
      </section>

      <section class='space-y-2'>
        <h2 class='text-lg font-semibold'>Async options (parent load)</h2>
        <p class='text-sm opacity-70'>
          Reload replaces
          <code>@options</code>
          but keeps
          <code>@value</code>
          when the selected id still exists in the new list.
        </p>
        <div class='flex gap-2 items-center'>
          <button
            type='button'
            class='btn btn-sm btn-primary'
            disabled={{this.remoteLoading}}
            {{on 'click' this.loadRemote}}
          >
            {{if this.remoteLoading 'Loading…' 'Load / refresh remote'}}
          </button>
          <span class='text-sm'>selected: {{this.remoteValue}}</span>
        </div>
        <Choices
          @type='single'
          @options={{this.remote}}
          @value={{this.remoteValue}}
          @onChange={{this.onRemote}}
          @placeholder='Load then pick — refresh keeps selection'
        />
      </section>

      <section class='space-y-3'>
        <h2 class='text-lg font-semibold'>Nested tracked labels (Person form)</h2>
        <p class='text-sm opacity-70'>
          Options are domain objects with
          <code>@tracked name</code>. Pick a person → edit → submit updates the
          dropdown label without changing the selected id.
        </p>

        <Choices
          @type='single'
          @options={{this.personOptions}}
          @value={{this.selectedPersonId}}
          @onChange={{this.onPersonChange}}
          @placeholder='Select a person'
        />
        <p class='text-sm'>selected id: {{this.selectedPersonId}}</p>

        {{#if this.selectedPerson}}
          <form
            class='space-y-3 p-4 border border-base-300 rounded-box bg-base-200'
            {{on 'submit' this.savePerson}}
          >
            <p class='text-sm font-medium'>Edit person #{{this.selectedPerson.id}}</p>
            <label class='form-control w-full'>
              <span class='label-text'>Name</span>
              <input
                class='input input-bordered w-full'
                value={{this.draftName}}
                {{on 'input' this.onDraftNameInput}}
              />
            </label>
            <label class='form-control w-full'>
              <span class='label-text'>Email</span>
              <input
                class='input input-bordered w-full'
                type='email'
                value={{this.draftEmail}}
                {{on 'input' this.onDraftEmailInput}}
              />
            </label>
            <button type='submit' class='btn btn-primary btn-sm'>
              Save (updates dropdown label)
            </button>
            {{#if this.personSavedMessage}}
              <p class='text-sm text-success'>{{this.personSavedMessage}}</p>
            {{/if}}
          </form>
        {{else}}
          <p class='text-sm opacity-60'>Select someone to open the form.</p>
        {{/if}}
      </section>

      <section class='space-y-4'>
        <h2 class='text-lg font-semibold'>Dependent selects + Fieldset</h2>
        <ChoicesFieldset
          @legend='City'
          @description='Pick first'
          @type='single'
          @options={{CITIES}}
          @value={{this.city}}
          @onChange={{this.onCity}}
          @fieldsetClass='bg-base-200 border-base-300 rounded-box border p-4 w-full'
        />
        <ChoicesFieldset
          @legend='Station'
          @description='Depends on city'
          @type='single'
          @options={{this.stations}}
          @value={{this.station}}
          @onChange={{this.onStation}}
          @disabled={{this.stationDisabled}}
          @fieldsetClass='bg-base-200 border-base-300 rounded-box border p-4 w-full'
        />
      </section>

      <section class='space-y-2'>
        <h2 class='text-lg font-semibold'>Native input (compare chrome)</h2>
        <input
          class='input input-bordered w-full'
          placeholder='Native daisy input'
        />
      </section>
    </main>
  </template>
}

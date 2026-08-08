import Choices from 'choices.js';
import type {
  ClassNames,
  EventChoice,
  InputChoice,
  InputGroup,
  Options as ChoicesConfig,
} from 'choices.js';

import { DAISY_CLASS_NAMES } from '../themes/daisy-class-names.ts';
import { UNSTYLED_CLASS_NAMES } from '../themes/unstyled-class-names.ts';
import { mapOptions, type ChoicesOption } from './map-options.ts';
import {
  normalizeSingleFromGetValue,
  normalizeValue,
  normalizeValues,
} from './normalize-value.ts';

export type ChoicesMode = 'text' | 'single' | 'multiple';
export type ChoicesTheme = 'default' | 'daisy' | 'unstyled';

export interface ChoicesPublicAPI {
  focus: () => void;
  clearStore: () => void;
  getValue: (valueOnly?: boolean) => unknown;
  instance: Choices | null;
}

export interface BridgeArgs {
  type?: ChoicesMode;
  options?: ChoicesOption[];
  value?: string | string[] | null;
  onChange?: (value: string | string[] | null) => void;
  onAdd?: (detail: EventChoice) => void;
  onRemove?: (detail: EventChoice) => void;
  onSearch?: (detail: { value: string; resultCount: number }) => void;
  onShowDropdown?: () => void;
  onHideDropdown?: () => void;
  disabled?: boolean;
  placeholder?: string;
  config?: Partial<ChoicesConfig>;
  syncKey?: string | number;
  onReady?: (instance: Choices) => void;
  registerAPI?: (api: ChoicesPublicAPI | null) => void;
  class?: string;
  theme?: ChoicesTheme;
}

export interface BridgeHandle {
  sync(args: BridgeArgs): void;
  destroy(): void;
}

/**
 * Config keys that require destroy + re-init (constructor-time in Choices).
 * Also: `@theme` and `@type` (tracked separately).
 */
export const RECREATE_KEYS = [
  'searchEnabled',
  'classNames',
  'allowHTML',
  'callbackOnCreateTemplates',
] as const;

function asClassList(value: string | string[] | undefined): string[] {
  if (value == null) {
    return [];
  }
  return Array.isArray(value) ? [...value] : [value];
}

function mergeClassNames(
  base: ClassNames | undefined,
  override: Partial<ClassNames> | undefined,
): ClassNames | undefined {
  if (!base && !override) {
    return undefined;
  }
  if (!base) {
    return override as ClassNames;
  }
  if (!override) {
    return base;
  }
  const keys = new Set([
    ...Object.keys(base),
    ...Object.keys(override),
  ]) as Set<keyof ClassNames>;
  const result = { ...base } as ClassNames;
  for (const key of keys) {
    const o = override[key];
    if (o !== undefined) {
      result[key] = o as ClassNames[typeof key];
    }
  }
  return result;
}

function themePreset(theme: ChoicesTheme | undefined): ClassNames | undefined {
  switch (theme) {
    case 'daisy':
      return DAISY_CLASS_NAMES;
    case 'unstyled':
      return UNSTYLED_CLASS_NAMES;
    default:
      return undefined;
  }
}

function buildConfig(args: BridgeArgs): Partial<ChoicesConfig> {
  const type = args.type ?? 'single';
  const base: Partial<ChoicesConfig> = {
    allowHTML: false,
    removeItemButton: type === 'multiple' || type === 'text',
    silent: false,
  };

  if (args.placeholder != null) {
    base.placeholder = true;
    base.placeholderValue = args.placeholder;
  }

  // Merge order: addon defaults ← theme preset ← @config ← @class on outer
  const config = args.config ?? {};
  const preset = themePreset(args.theme);
  const withTheme = mergeClassNames(preset, config.classNames);

  const merged: Partial<ChoicesConfig> = {
    ...base,
    ...config,
    classNames: withTheme,
  };

  // Re-apply placeholder from args over config if both present
  if (args.placeholder != null) {
    merged.placeholder = true;
    merged.placeholderValue = args.placeholder;
  }

  // Addon defaults for removeItemButton lose to explicit @config
  if (config.removeItemButton !== undefined) {
    merged.removeItemButton = config.removeItemButton;
  }

  if (args.class) {
    const existing = merged.classNames;
    const outerList = asClassList(existing?.containerOuter);
    if (outerList.length === 0) {
      outerList.push('choices');
    }
    merged.classNames = {
      ...(existing as ClassNames),
      containerOuter: [
        ...outerList,
        ...args.class.split(/\s+/).filter(Boolean),
      ],
    } as ClassNames;
  }

  // Drop undefined classNames so Choices uses stock defaults for theme=default
  if (merged.classNames == null) {
    delete merged.classNames;
  }

  return merged;
}

function fingerprintRecreate(
  config: Partial<ChoicesConfig>,
  theme: ChoicesTheme | undefined,
): string {
  const slice: Record<string, unknown> = { theme: theme ?? 'default' };
  for (const key of RECREATE_KEYS) {
    slice[key] = config[key as keyof ChoicesConfig];
  }
  try {
    return JSON.stringify(slice);
  } catch {
    return String(Math.random());
  }
}

function fingerprintOptions(mapped: (InputChoice | InputGroup)[]): string {
  try {
    return JSON.stringify(mapped);
  } catch {
    return String(Math.random());
  }
}

function fingerprintValue(value: string | string[] | null | undefined): string {
  if (value == null) {
    return '';
  }
  if (Array.isArray(value)) {
    return value.map(String).join('\0');
  }
  return String(value);
}

export function createBridge(
  element: HTMLSelectElement | HTMLInputElement,
): BridgeHandle {
  let instance: Choices | undefined;
  let syncing = false;
  let lastRecreateFp = '';
  let lastOptionsFp = '';
  let lastValueFp = '';
  let lastDisabled: boolean | undefined;
  let lastSyncKey: string | number | undefined;
  /** Host type is init-level; changing it destroys + recreates the instance. */
  let lastType: ChoicesMode | undefined;
  let currentArgs: BridgeArgs = {};

  const onChange = (event: Event) => {
    if (syncing || !instance) {
      return;
    }
    // Prefer change event; also used after add/remove for multi
    void event;
    const type = currentArgs.type ?? 'single';
    const raw = instance.getValue(true);
    if (type === 'single') {
      currentArgs.onChange?.(normalizeSingleFromGetValue(raw));
    } else {
      currentArgs.onChange?.(
        Array.isArray(raw) ? raw.map(String) : raw == null || raw === '' ? [] : [String(raw)],
      );
    }
  };

  const onAddItem = (event: Event) => {
    if (syncing) {
      return;
    }
    const detail = (event as CustomEvent<EventChoice>).detail;
    currentArgs.onAdd?.(detail);
  };

  const onRemoveItem = (event: Event) => {
    if (syncing) {
      return;
    }
    const detail = (event as CustomEvent<EventChoice>).detail;
    currentArgs.onRemove?.(detail);
  };

  const onSearch = (event: Event) => {
    if (syncing) {
      return;
    }
    const detail = (event as CustomEvent<{ value: string; resultCount: number }>)
      .detail;
    currentArgs.onSearch?.(detail);
  };

  const onShowDropdown = () => {
    if (!syncing) {
      currentArgs.onShowDropdown?.();
    }
  };

  const onHideDropdown = () => {
    if (!syncing) {
      currentArgs.onHideDropdown?.();
    }
  };

  function wireListeners(el: HTMLElement) {
    el.addEventListener('change', onChange);
    el.addEventListener('addItem', onAddItem);
    el.addEventListener('removeItem', onRemoveItem);
    el.addEventListener('search', onSearch);
    el.addEventListener('showDropdown', onShowDropdown);
    el.addEventListener('hideDropdown', onHideDropdown);
  }

  function unwireListeners(el: HTMLElement) {
    el.removeEventListener('change', onChange);
    el.removeEventListener('addItem', onAddItem);
    el.removeEventListener('removeItem', onRemoveItem);
    el.removeEventListener('search', onSearch);
    el.removeEventListener('showDropdown', onShowDropdown);
    el.removeEventListener('hideDropdown', onHideDropdown);
  }

  function publicAPI(): ChoicesPublicAPI {
    return {
      focus: () => {
        instance?.showDropdown();
        // Focus the visible search/input when present
        const el = element as HTMLElement;
        el.focus?.();
      },
      clearStore: () => {
        instance?.clearStore();
      },
      getValue: (valueOnly?: boolean) => instance?.getValue(valueOnly),
      instance: instance ?? null,
    };
  }

  function applyValue(args: BridgeArgs) {
    if (!instance) {
      return;
    }
    const type = args.type ?? 'single';
    syncing = true;
    try {
      if (type === 'single') {
        const v = normalizeValue(args.value);
        if (v == null) {
          instance.setChoiceByValue([]);
        } else {
          instance.setChoiceByValue(v);
        }
      } else if (type === 'text') {
        const values = normalizeValues(args.value);
        instance.removeActiveItems();
        if (values.length) {
          instance.setValue(values);
        }
      } else {
        // multiple
        const values = normalizeValues(args.value);
        instance.removeActiveItems();
        if (values.length) {
          instance.setChoiceByValue(values);
        }
      }
    } finally {
      syncing = false;
    }
  }

  function applyOptions(args: BridgeArgs) {
    if (!instance) {
      return;
    }
    const type = args.type ?? 'single';
    if (type === 'text') {
      return;
    }
    const mapped = mapOptions(args.options);
    syncing = true;
    try {
      // replaceChoices + replaceItems so selected display labels update when
      // nested option fields change. Never refresh() for Ember option updates.
      // Controlled @value is re-applied immediately after.
      instance.setChoices(mapped, 'value', 'label', true, true, true);
    } finally {
      syncing = false;
    }
    // re-apply controlled selection after replace
    if (args.value !== undefined) {
      applyValue(args);
    }
  }

  function applyDisabled(args: BridgeArgs) {
    if (!instance) {
      return;
    }
    if (args.disabled) {
      instance.disable();
    } else {
      instance.enable();
    }
  }

  function init(args: BridgeArgs) {
    const config = buildConfig(args);
    instance = new Choices(element, config);
    wireListeners(element);
    lastRecreateFp = fingerprintRecreate(config, args.theme);

    // Initial options + value
    const mapped = mapOptions(args.options);
    lastOptionsFp = fingerprintOptions(mapped);
    if ((args.type ?? 'single') !== 'text') {
      syncing = true;
      try {
        instance.setChoices(mapped, 'value', 'label', true, true, true);
      } finally {
        syncing = false;
      }
    }

    if (args.value !== undefined) {
      applyValue(args);
      lastValueFp = fingerprintValue(args.value);
    } else {
      lastValueFp = '';
    }

    lastDisabled = Boolean(args.disabled);
    if (args.disabled) {
      instance.disable();
    }

    lastType = args.type ?? 'single';
    lastSyncKey = args.syncKey;
    args.onReady?.(instance);
    args.registerAPI?.(publicAPI());
  }

  function destroyInstance() {
    if (!instance) {
      return;
    }
    unwireListeners(element);
    try {
      instance.destroy();
    } catch {
      // Choices may throw if already torn down
    }
    instance = undefined;
    currentArgs.registerAPI?.(null);
    lastRecreateFp = '';
    lastOptionsFp = '';
    lastValueFp = '';
    lastDisabled = undefined;
    lastType = undefined;
  }

  return {
    sync(args: BridgeArgs) {
      currentArgs = args;
      const config = buildConfig(args);
      const recreateFp = fingerprintRecreate(config, args.theme);
      const type = args.type ?? 'single';
      const forceSync = args.syncKey !== undefined && args.syncKey !== lastSyncKey;

      if (!instance) {
        init(args);
        return;
      }

      // Type and recreate-key config changes require a fresh Choices instance.
      if (type !== lastType || recreateFp !== lastRecreateFp) {
        destroyInstance();
        init(args);
        return;
      }

      const mapped = mapOptions(args.options);
      const optionsFp = fingerprintOptions(mapped);
      if (forceSync || optionsFp !== lastOptionsFp) {
        applyOptions(args);
        lastOptionsFp = optionsFp;
        // applyOptions re-applies value when controlled
        lastValueFp = fingerprintValue(args.value);
      } else if (args.value !== undefined) {
        const valueFp = fingerprintValue(args.value);
        if (forceSync || valueFp !== lastValueFp) {
          applyValue(args);
          lastValueFp = valueFp;
        }
      }

      const disabled = Boolean(args.disabled);
      if (disabled !== lastDisabled) {
        applyDisabled(args);
        lastDisabled = disabled;
      }

      lastSyncKey = args.syncKey;
    },

    destroy() {
      destroyInstance();
      currentArgs = {};
    },
  };
}

import Choices from 'choices.js';
import { DAISY_CLASS_NAMES } from '../themes/daisy-class-names.js';
import { UNSTYLED_CLASS_NAMES } from '../themes/unstyled-class-names.js';
import { mapOptions } from './map-options.js';
import { normalizeValue, normalizeValues, normalizeSingleFromGetValue } from './normalize-value.js';

/**
 * Config keys that require destroy + re-init (constructor-time in Choices).
 * Also: `@theme` and `@type` (tracked separately).
 */
const RECREATE_KEYS = ['searchEnabled', 'classNames', 'allowHTML', 'callbackOnCreateTemplates'];
function asClassList(value) {
  if (value == null) {
    return [];
  }
  return Array.isArray(value) ? [...value] : [value];
}
function mergeClassNames(base, override) {
  if (!base && !override) {
    return undefined;
  }
  if (!base) {
    return override;
  }
  if (!override) {
    return base;
  }
  const keys = new Set([...Object.keys(base), ...Object.keys(override)]);
  const result = {
    ...base
  };
  for (const key of keys) {
    const k = key;
    const o = override[k];
    if (o !== undefined) {
      // Per-key replace (Choices shallow-merges classNames slots)
      Object.assign(result, {
        [k]: o
      });
    }
  }
  return result;
}
function themePreset(theme) {
  switch (theme) {
    case 'daisy':
      return DAISY_CLASS_NAMES;
    case 'unstyled':
      return UNSTYLED_CLASS_NAMES;
    default:
      return undefined;
  }
}
function buildConfig(args) {
  const type = args.type ?? 'single';
  const base = {
    allowHTML: false,
    removeItemButton: type === 'multiple' || type === 'text',
    silent: false
  };
  if (args.placeholder != null) {
    base.placeholder = true;
    base.placeholderValue = args.placeholder;
  }

  // Merge order: addon defaults ← theme preset ← @config ← @class on outer
  const config = args.config ?? {};
  const preset = themePreset(args.theme);
  const withTheme = mergeClassNames(preset, config.classNames);
  const merged = {
    ...base,
    ...config,
    classNames: withTheme
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
      ...existing,
      containerOuter: [...outerList, ...args.class.split(/\s+/).filter(Boolean)]
    };
  }

  // Drop undefined classNames so Choices uses stock defaults for theme=default
  if (merged.classNames == null) {
    delete merged.classNames;
  }
  return merged;
}
function fingerprintRecreate(config, theme) {
  const slice = {
    theme: theme ?? 'default'
  };
  for (const key of RECREATE_KEYS) {
    slice[key] = config[key];
  }
  try {
    return JSON.stringify(slice);
  } catch {
    return String(Math.random());
  }
}
function fingerprintOptions(mapped) {
  try {
    return JSON.stringify(mapped);
  } catch {
    return String(Math.random());
  }
}
function fingerprintValue(value) {
  if (value == null) {
    return '';
  }
  if (Array.isArray(value)) {
    return value.map(String).join('\0');
  }
  return String(value);
}
function createBridge(element) {
  let instance;
  let syncing = false;
  let lastRecreateFp = '';
  let lastOptionsFp = '';
  let lastValueFp = '';
  let lastDisabled;
  let lastSyncKey;
  /** Host type is init-level; changing it destroys + recreates the instance. */
  let lastType;
  let currentArgs = {};
  const onChange = event => {
    if (syncing || !instance) {
      return;
    }
    const type = currentArgs.type ?? 'single';
    const raw = instance.getValue(true);
    if (type === 'single') {
      currentArgs.onChange?.(normalizeSingleFromGetValue(raw));
    } else {
      currentArgs.onChange?.(Array.isArray(raw) ? raw.map(String) : raw == null || raw === '' ? [] : [String(raw)]);
    }
  };
  const onAddItem = event => {
    if (syncing) {
      return;
    }
    const detail = event.detail;
    currentArgs.onAdd?.(detail);
  };
  const onRemoveItem = event => {
    if (syncing) {
      return;
    }
    const detail = event.detail;
    currentArgs.onRemove?.(detail);
  };
  const onSearch = event => {
    if (syncing) {
      return;
    }
    const detail = event.detail;
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
  function wireListeners(el) {
    el.addEventListener('change', onChange);
    el.addEventListener('addItem', onAddItem);
    el.addEventListener('removeItem', onRemoveItem);
    el.addEventListener('search', onSearch);
    el.addEventListener('showDropdown', onShowDropdown);
    el.addEventListener('hideDropdown', onHideDropdown);
  }
  function unwireListeners(el) {
    el.removeEventListener('change', onChange);
    el.removeEventListener('addItem', onAddItem);
    el.removeEventListener('removeItem', onRemoveItem);
    el.removeEventListener('search', onSearch);
    el.removeEventListener('showDropdown', onShowDropdown);
    el.removeEventListener('hideDropdown', onHideDropdown);
  }
  function publicAPI() {
    return {
      focus: () => {
        instance?.showDropdown();
        // Focus the visible search/input when present
        const el = element;
        el.focus?.();
      },
      clearStore: () => {
        instance?.clearStore();
      },
      getValue: valueOnly => instance?.getValue(valueOnly),
      instance: instance ?? null
    };
  }
  function applyValue(args) {
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
  function applyOptions(args) {
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
      // Choices may return a Promise; bridge sync is fire-and-forget under syncing
      void instance.setChoices(mapped, 'value', 'label', true, true, true);
    } finally {
      syncing = false;
    }
    // re-apply controlled selection after replace
    if (args.value !== undefined) {
      applyValue(args);
    }
  }
  function applyDisabled(args) {
    if (!instance) {
      return;
    }
    if (args.disabled) {
      instance.disable();
    } else {
      instance.enable();
    }
  }
  function init(args) {
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
        void instance.setChoices(mapped, 'value', 'label', true, true, true);
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
    sync(args) {
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
    }
  };
}

export { RECREATE_KEYS, createBridge };
//# sourceMappingURL=bridge.js.map

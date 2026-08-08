import Component from '@glimmer/component';
import { registerDestructor } from '@ember/destroyable';
import type Owner from '@ember/owner';
import Modifier from 'ember-modifier';
import type ChoicesInstance from 'choices.js';
import type {
  EventChoice,
  InputChoice,
  InputGroup,
  Options as ChoicesConfig,
} from 'choices.js';

import {
  createBridge,
  type BridgeArgs,
  type BridgeHandle,
  type ChoicesMode,
  type ChoicesPublicAPI,
} from '../utils/bridge.ts';
import { mapOptions } from '../utils/map-options.ts';

export type { ChoicesMode, ChoicesPublicAPI };
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
     * the bridge reads value/label/disabled/group fields.
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
    name?: string;

    /**
     * Visual preset. Default: 'default' (stock Choices look).
     */
    theme?: 'default' | 'daisy' | 'unstyled';

    /**
     * Extra classes merged into classNames.containerOuter.
     */
    class?: string;

    /**
     * Pass-through Choices constructor options (merged over addon defaults).
     */
    config?: Partial<ChoicesConfig>;

    /**
     * Force resync when nested data is not autotracked.
     */
    syncKey?: string | number;

    /**
     * Called once after successful init.
     */
    onReady?: (instance: ChoicesInstance) => void;

    /**
     * Register a small stable API for focus/clear without holding the raw instance.
     */
    registerAPI?: (api: ChoicesPublicAPI | null) => void;
  };
}

/**
 * Class modifier: create bridge once, sync on every tracked-arg invalidation,
 * destroy only on teardown. Functional modifiers tear down on every re-run,
 * which would thrash Choices.
 */
interface AttachSignature {
  Element: HTMLSelectElement | HTMLInputElement;
  Args: {
    Named: BridgeArgs;
  };
}

class AttachChoicesModifier extends Modifier<AttachSignature> {
  #bridge: BridgeHandle | null = null;

  constructor(owner: Owner, args: object) {
    // ember-modifier Args typing is loose at construction time
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    super(owner, args as any);
    registerDestructor(this, () => {
      this.#bridge?.destroy();
      this.#bridge = null;
    });
  }

  modify(
    element: HTMLSelectElement | HTMLInputElement,
    _positional: unknown[],
    named: BridgeArgs,
  ) {
    if (!this.#bridge) {
      this.#bridge = createBridge(element);
    }
    this.#bridge.sync(named);
  }
}

/**
 * Reactive Choices.js bridge. Empty host element — Choices owns option DOM.
 * Phase 1: controlled single select is fully supported; multi/text are wired
 * for later phases but not acceptance-tested yet.
 */
export default class ChoicesComponent extends Component<ChoicesSignature> {
  attach = AttachChoicesModifier;

  get type(): ChoicesMode {
    return this.args.type ?? 'single';
  }

  get isText(): boolean {
    return this.type === 'text';
  }

  get isMultiple(): boolean {
    return this.type === 'multiple';
  }

  /**
   * Snapshot options in a tracked getter so nested `@tracked` labels/values
   * invalidate this computation and re-enter the modifier `modify()`.
   */
  get mappedOptions(): (InputChoice | InputGroup)[] {
    return mapOptions(this.args.options);
  }

  get bridgeArgs(): BridgeArgs {
    return {
      type: this.type,
      // Pass already-mapped plain snapshots; bridge will not re-map when
      // it receives InputChoice shapes (mapOptions is idempotent).
      options: this.mappedOptions,
      value: this.args.value,
      onChange: this.args.onChange,
      onAdd: this.args.onAdd,
      onRemove: this.args.onRemove,
      onSearch: this.args.onSearch,
      onShowDropdown: this.args.onShowDropdown,
      onHideDropdown: this.args.onHideDropdown,
      disabled: this.args.disabled,
      placeholder: this.args.placeholder,
      config: this.args.config,
      syncKey: this.args.syncKey,
      onReady: this.args.onReady,
      registerAPI: this.args.registerAPI,
      class: this.args.class,
      theme: this.args.theme ?? 'default',
    };
  }

  <template>
    {{#if this.isText}}
      <input
        type="text"
        name={{@name}}
        disabled={{@disabled}}
        placeholder={{@placeholder}}
        {{this.attach
          type=this.bridgeArgs.type
          options=this.bridgeArgs.options
          value=this.bridgeArgs.value
          onChange=this.bridgeArgs.onChange
          onAdd=this.bridgeArgs.onAdd
          onRemove=this.bridgeArgs.onRemove
          onSearch=this.bridgeArgs.onSearch
          onShowDropdown=this.bridgeArgs.onShowDropdown
          onHideDropdown=this.bridgeArgs.onHideDropdown
          disabled=this.bridgeArgs.disabled
          placeholder=this.bridgeArgs.placeholder
          config=this.bridgeArgs.config
          syncKey=this.bridgeArgs.syncKey
          onReady=this.bridgeArgs.onReady
          registerAPI=this.bridgeArgs.registerAPI
          class=this.bridgeArgs.class
          theme=this.bridgeArgs.theme
        }}
        ...attributes
      />
    {{else}}
      <select
        name={{@name}}
        multiple={{this.isMultiple}}
        disabled={{@disabled}}
        data-placeholder={{@placeholder}}
        {{this.attach
          type=this.bridgeArgs.type
          options=this.bridgeArgs.options
          value=this.bridgeArgs.value
          onChange=this.bridgeArgs.onChange
          onAdd=this.bridgeArgs.onAdd
          onRemove=this.bridgeArgs.onRemove
          onSearch=this.bridgeArgs.onSearch
          onShowDropdown=this.bridgeArgs.onShowDropdown
          onHideDropdown=this.bridgeArgs.onHideDropdown
          disabled=this.bridgeArgs.disabled
          placeholder=this.bridgeArgs.placeholder
          config=this.bridgeArgs.config
          syncKey=this.bridgeArgs.syncKey
          onReady=this.bridgeArgs.onReady
          registerAPI=this.bridgeArgs.registerAPI
          class=this.bridgeArgs.class
          theme=this.bridgeArgs.theme
        }}
        ...attributes
      ></select>
    {{/if}}
  </template>
}

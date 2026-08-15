import Component from '@glimmer/component';
import { registerDestructor } from '@ember/destroyable';
import Modifier from 'ember-modifier';
import { createBridge } from '../utils/bridge.js';
import { mapOptions } from '../utils/map-options.js';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';

/**
 * Class modifier: create bridge once, sync on every tracked-arg invalidation,
 * destroy only on teardown. Functional modifiers tear down on every re-run,
 * which would thrash Choices.
 */
class AttachChoicesModifier extends Modifier {
  #bridge = null;
  constructor(owner, args) {
    // ember-modifier Args typing is loose at construction time
    // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-argument
    super(owner, args);
    registerDestructor(this, () => {
      this.#bridge?.destroy();
      this.#bridge = null;
    });
  }
  modify(element, _positional, named) {
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
class ChoicesComponent extends Component {
  attach = AttachChoicesModifier;
  get type() {
    return this.args.type ?? 'single';
  }
  get isText() {
    return this.type === 'text';
  }
  get isMultiple() {
    return this.type === 'multiple';
  }
  /**
  * Snapshot options in a tracked getter so nested `@tracked` labels/values
  * invalidate this computation and re-enter the modifier `modify()`.
  */
  get mappedOptions() {
    return mapOptions(this.args.options);
  }
  get bridgeArgs() {
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
      theme: this.args.theme ?? 'default'
    };
  }
  static {
    setComponentTemplate(precompileTemplate("{{#if this.isText}}\n  <input type=\"text\" name={{@name}} disabled={{@disabled}} placeholder={{@placeholder}} {{this.attach type=this.bridgeArgs.type options=this.bridgeArgs.options value=this.bridgeArgs.value onChange=this.bridgeArgs.onChange onAdd=this.bridgeArgs.onAdd onRemove=this.bridgeArgs.onRemove onSearch=this.bridgeArgs.onSearch onShowDropdown=this.bridgeArgs.onShowDropdown onHideDropdown=this.bridgeArgs.onHideDropdown disabled=this.bridgeArgs.disabled placeholder=this.bridgeArgs.placeholder config=this.bridgeArgs.config syncKey=this.bridgeArgs.syncKey onReady=this.bridgeArgs.onReady registerAPI=this.bridgeArgs.registerAPI class=this.bridgeArgs.class theme=this.bridgeArgs.theme}} ...attributes />\n{{else}}\n  <select name={{@name}} multiple={{this.isMultiple}} disabled={{@disabled}} data-placeholder={{@placeholder}} {{this.attach type=this.bridgeArgs.type options=this.bridgeArgs.options value=this.bridgeArgs.value onChange=this.bridgeArgs.onChange onAdd=this.bridgeArgs.onAdd onRemove=this.bridgeArgs.onRemove onSearch=this.bridgeArgs.onSearch onShowDropdown=this.bridgeArgs.onShowDropdown onHideDropdown=this.bridgeArgs.onHideDropdown disabled=this.bridgeArgs.disabled placeholder=this.bridgeArgs.placeholder config=this.bridgeArgs.config syncKey=this.bridgeArgs.syncKey onReady=this.bridgeArgs.onReady registerAPI=this.bridgeArgs.registerAPI class=this.bridgeArgs.class theme=this.bridgeArgs.theme}} ...attributes></select>\n{{/if}}", {
      strictMode: true
    }), this);
  }
}

export { ChoicesComponent as default };
//# sourceMappingURL=choices.js.map

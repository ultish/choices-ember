import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import type ChoicesInstance from 'choices.js';
import type {
  EventChoice,
  Options as ChoicesConfig,
} from 'choices.js';

import Choices, {
  type ChoicesMode,
  type ChoicesOption,
  type ChoicesPublicAPI,
} from './choices.gts';

export interface ChoicesFieldsetSignature {
  Element: HTMLFieldSetElement;
  Args: {
    /** legend text (fieldset-legend) */
    legend?: string;
    /** description under the control (daisyUI .label paragraph) */
    description?: string;
    /** label above the control (daisyUI .label), when not using legend-only */
    label?: string;
    /** extra classes on <fieldset> (e.g. bg-base-200 border …) */
    fieldsetClass?: string;
    /** when true, set disabled on fieldset + forward to Choices */
    disabled?: boolean;

    // ── pass-through to <Choices> ──
    type?: ChoicesMode;
    options?: ChoicesOption[];
    value?: string | string[] | null;
    onChange?: (value: string | string[] | null) => void;
    onAdd?: (detail: EventChoice) => void;
    onRemove?: (detail: EventChoice) => void;
    onSearch?: (detail: { value: string; resultCount: number }) => void;
    onShowDropdown?: () => void;
    onHideDropdown?: () => void;
    placeholder?: string;
    name?: string;
    config?: Partial<ChoicesConfig>;
    syncKey?: string | number;
    onReady?: (instance: ChoicesInstance) => void;
    registerAPI?: (api: ChoicesPublicAPI | null) => void;
    class?: string;
    /** defaults to 'daisy' for this component */
    theme?: 'default' | 'daisy' | 'unstyled';
  };
  Blocks: {
    legend?: [];
    description?: [];
  };
}

/**
 * daisyUI 5 fieldset chrome around `<Choices @theme="daisy">`.
 * Composition only — no second bridge. App must provide Tailwind + daisyUI.
 */
export default class ChoicesFieldset extends Component<ChoicesFieldsetSignature> {
  get inputId(): string {
    return `choices-fieldset-${guidFor(this)}`;
  }

  get theme(): 'default' | 'daisy' | 'unstyled' {
    return this.args.theme ?? 'daisy';
  }

  get outerClass(): string {
    const extra = this.args.class ?? '';
    return ['w-full', extra].filter(Boolean).join(' ');
  }

  get fieldsetClassList(): string {
    return ['fieldset', this.args.fieldsetClass ?? ''].filter(Boolean).join(' ');
  }

  <template>
    <fieldset
      class={{this.fieldsetClassList}}
      disabled={{@disabled}}
      ...attributes
    >
      {{#if (has-block 'legend')}}
        <legend class='fieldset-legend'>{{yield to='legend'}}</legend>
      {{else if @legend}}
        <legend class='fieldset-legend'>{{@legend}}</legend>
      {{/if}}

      {{#if @label}}
        <label class='label' for={{this.inputId}}>{{@label}}</label>
      {{/if}}

      <Choices
        id={{this.inputId}}
        @type={{@type}}
        @options={{@options}}
        @value={{@value}}
        @onChange={{@onChange}}
        @onAdd={{@onAdd}}
        @onRemove={{@onRemove}}
        @onSearch={{@onSearch}}
        @onShowDropdown={{@onShowDropdown}}
        @onHideDropdown={{@onHideDropdown}}
        @placeholder={{@placeholder}}
        @name={{@name}}
        @config={{@config}}
        @syncKey={{@syncKey}}
        @onReady={{@onReady}}
        @registerAPI={{@registerAPI}}
        @disabled={{@disabled}}
        @theme={{this.theme}}
        @class={{this.outerClass}}
      />

      {{#if (has-block 'description')}}
        <p class='label'>{{yield to='description'}}</p>
      {{else if @description}}
        <p class='label'>{{@description}}</p>
      {{/if}}
    </fieldset>
  </template>
}

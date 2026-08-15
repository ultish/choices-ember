import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import ChoicesComponent from './choices.js';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';

/**
 * daisyUI 5 fieldset chrome around `<Choices @theme="daisy">`.
 * Composition only — no second bridge. App must provide Tailwind + daisyUI.
 */
class ChoicesFieldset extends Component {
  get inputId() {
    return `choices-fieldset-${guidFor(this)}`;
  }
  get theme() {
    return this.args.theme ?? 'daisy';
  }
  get outerClass() {
    const extra = this.args.class ?? '';
    return ['w-full', extra].filter(Boolean).join(' ');
  }
  get fieldsetClassList() {
    return ['fieldset', this.args.fieldsetClass ?? ''].filter(Boolean).join(' ');
  }
  static {
    setComponentTemplate(precompileTemplate("<fieldset class={{this.fieldsetClassList}} disabled={{@disabled}} ...attributes>\n  {{#if (has-block \"legend\")}}\n    <legend class=\"fieldset-legend\">{{yield to=\"legend\"}}</legend>\n  {{else if @legend}}\n    <legend class=\"fieldset-legend\">{{@legend}}</legend>\n  {{/if}}\n\n  {{#if @label}}\n    <label class=\"label\" for={{this.inputId}}>{{@label}}</label>\n  {{/if}}\n\n  <Choices id={{this.inputId}} @type={{@type}} @options={{@options}} @value={{@value}} @onChange={{@onChange}} @onAdd={{@onAdd}} @onRemove={{@onRemove}} @onSearch={{@onSearch}} @onShowDropdown={{@onShowDropdown}} @onHideDropdown={{@onHideDropdown}} @placeholder={{@placeholder}} @name={{@name}} @config={{@config}} @syncKey={{@syncKey}} @onReady={{@onReady}} @registerAPI={{@registerAPI}} @disabled={{@disabled}} @theme={{this.theme}} @class={{this.outerClass}} />\n\n  {{#if (has-block \"description\")}}\n    <p class=\"label\">{{yield to=\"description\"}}</p>\n  {{else if @description}}\n    <p class=\"label\">{{@description}}</p>\n  {{/if}}\n</fieldset>", {
      strictMode: true,
      scope: () => ({
        Choices: ChoicesComponent
      })
    }), this);
  }
}

export { ChoicesFieldset as default };
//# sourceMappingURL=choices-fieldset.js.map

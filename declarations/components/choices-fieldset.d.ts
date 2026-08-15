import Component from '@glimmer/component';
import type ChoicesInstance from 'choices.js';
import type { EventChoice, Options as ChoicesConfig } from 'choices.js';
import { type ChoicesMode, type ChoicesOption, type ChoicesPublicAPI } from './choices';
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
        type?: ChoicesMode;
        options?: ChoicesOption[];
        value?: string | string[] | null;
        onChange?: (value: string | string[] | null) => void;
        onAdd?: (detail: EventChoice) => void;
        onRemove?: (detail: EventChoice) => void;
        onSearch?: (detail: {
            value: string;
            resultCount: number;
        }) => void;
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
    get inputId(): string;
    get theme(): 'default' | 'daisy' | 'unstyled';
    get outerClass(): string;
    get fieldsetClassList(): string;
}
//# sourceMappingURL=choices-fieldset.d.ts.map
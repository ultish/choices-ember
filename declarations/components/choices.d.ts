import Component from '@glimmer/component';
import type Owner from '@ember/owner';
import Modifier from 'ember-modifier';
import type ChoicesInstance from 'choices.js';
import type { EventChoice, InputChoice, InputGroup, Options as ChoicesConfig } from 'choices.js';
import { type BridgeArgs, type ChoicesMode, type ChoicesPublicAPI } from '../utils/bridge.ts';
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
        onSearch?: (detail: {
            value: string;
            resultCount: number;
        }) => void;
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
declare class AttachChoicesModifier extends Modifier<AttachSignature> {
    #private;
    constructor(owner: Owner, args: object);
    modify(element: HTMLSelectElement | HTMLInputElement, _positional: unknown[], named: BridgeArgs): void;
}
/**
 * Reactive Choices.js bridge. Empty host element — Choices owns option DOM.
 * Phase 1: controlled single select is fully supported; multi/text are wired
 * for later phases but not acceptance-tested yet.
 */
export default class ChoicesComponent extends Component<ChoicesSignature> {
    attach: typeof AttachChoicesModifier;
    get type(): ChoicesMode;
    get isText(): boolean;
    get isMultiple(): boolean;
    /**
     * Snapshot options in a tracked getter so nested `@tracked` labels/values
     * invalidate this computation and re-enter the modifier `modify()`.
     */
    get mappedOptions(): (InputChoice | InputGroup)[];
    get bridgeArgs(): BridgeArgs;
}
//# sourceMappingURL=choices.d.ts.map
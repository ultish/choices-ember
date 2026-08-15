import Choices from 'choices.js';
import type { EventChoice, Options as ChoicesConfig } from 'choices.js';
import { type ChoicesOption } from './map-options.ts';
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
    onSearch?: (detail: {
        value: string;
        resultCount: number;
    }) => void;
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
export declare const RECREATE_KEYS: readonly ["searchEnabled", "classNames", "allowHTML", "callbackOnCreateTemplates"];
export declare function createBridge(element: HTMLSelectElement | HTMLInputElement): BridgeHandle;
//# sourceMappingURL=bridge.d.ts.map
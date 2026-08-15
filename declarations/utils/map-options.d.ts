import type { InputChoice, InputGroup } from 'choices.js';
export type ChoicesOption = InputChoice | InputGroup;
/**
 * Map Ember/domain option objects to plain Choices InputChoice / InputGroup
 * snapshots. **Reads** value, label, disabled, selected, placeholder,
 * customProperties, and group fields so nested tracked properties invalidate
 * the bridge.
 */
export declare function mapOptions(options: ChoicesOption[] | undefined | null): (InputChoice | InputGroup)[];
//# sourceMappingURL=map-options.d.ts.map
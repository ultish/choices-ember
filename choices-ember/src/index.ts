export { default as Choices } from './components/choices.gts';
export type {
  ChoicesMode,
  ChoicesOption,
  ChoicesPublicAPI,
  ChoicesSignature,
} from './components/choices.gts';

export { default as ChoicesFieldset } from './components/choices-fieldset.gts';
export type { ChoicesFieldsetSignature } from './components/choices-fieldset.gts';

export { mapOptions } from './utils/map-options.ts';
export {
  normalizeSingleFromGetValue,
  normalizeValue,
  normalizeValues,
} from './utils/normalize-value.ts';
export { RECREATE_KEYS } from './utils/bridge.ts';
export type { ChoicesTheme } from './utils/bridge.ts';

export { DAISY_CLASS_NAMES } from './themes/daisy-class-names.ts';
export { UNSTYLED_CLASS_NAMES } from './themes/unstyled-class-names.ts';

// Re-export useful Choices.js types for consumers
export type {
  InputChoice,
  InputGroup,
  EventChoice,
  Options as ChoicesConfig,
} from 'choices.js';

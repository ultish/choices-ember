import type Choices from './components/choices.gts';
import type ChoicesFieldset from './components/choices-fieldset.gts';

export default interface Registry {
  Choices: typeof Choices;
  ChoicesFieldset: typeof ChoicesFieldset;
}

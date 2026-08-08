'use strict';

module.exports = {
  extends: ['stylelint-config-standard'],
  rules: {
    // Tailwind v4 / daisyUI pipeline (not classic CSS imports)
    'import-notation': null,
    'no-invalid-position-at-import-rule': null,
    'media-feature-range-notation': null,
    'at-rule-no-unknown': [
      true,
      {
        ignoreAtRules: [
          'plugin',
          'source',
          'theme',
          'utility',
          'variant',
          'custom-variant',
          'apply',
          'layer',
          'config',
          'reference',
          'tailwind',
        ],
      },
    ],
  },
};

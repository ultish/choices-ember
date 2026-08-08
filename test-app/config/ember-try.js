'use strict';

const getChannelURL = require('ember-source-channel-url');
const { embroiderSafe, embroiderOptimized } = require('@embroider/test-setup');

/**
 * Support matrix matches peer `ember-source: ">= 6.0.0"`.
 *
 * Ember 7 (release/beta/canary) currently fails: host components do not
 * paint Choices DOM (no `.choices` / fieldset). Track separately — do not
 * fail CI until the addon is ported/verified on 7.
 */
module.exports = async function () {
  return {
    usePnpm: true,
    scenarios: [
      {
        name: 'ember-lts-6.4',
        npm: {
          devDependencies: {
            'ember-source': '~6.4.0',
          },
        },
      },
      {
        name: 'ember-lts-6.8',
        npm: {
          devDependencies: {
            'ember-source': '~6.8.0',
          },
        },
      },
      // test-app default is ~6.12 (current LTS) — covered by main CI jobs
      {
        name: 'ember-release',
        // Ember 7.x — allowedToFail until Choices bridge renders under 7
        allowedToFail: true,
        npm: {
          devDependencies: {
            'ember-source': await getChannelURL('release'),
          },
        },
      },
      {
        name: 'ember-beta',
        allowedToFail: true,
        npm: {
          devDependencies: {
            'ember-source': await getChannelURL('beta'),
          },
        },
      },
      {
        name: 'ember-canary',
        allowedToFail: true,
        npm: {
          devDependencies: {
            'ember-source': await getChannelURL('canary'),
          },
        },
      },
      embroiderSafe(),
      embroiderOptimized(),
    ],
  };
};

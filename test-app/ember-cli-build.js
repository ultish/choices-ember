'use strict';

const EmberApp = require('ember-cli/lib/broccoli/ember-app');

module.exports = function (defaults) {
  let app = new EmberApp(defaults, {
    'ember-cli-babel': { enableTypeScriptTransform: true },
    autoImport: {
      watchDependencies: ['choices-ember'],
    },
    postcssOptions: {
      compile: {
        enabled: true,
        includePaths: ['app'],
        cacheInclude: [
          /.*\.(css|scss|sass|less)$/,
          /.postcssrc/,
          /postcss.config.*$/,
        ],
        plugins: [
          {
            module: require('@tailwindcss/postcss'),
          },
        ],
      },
    },
  });

  const { maybeEmbroider } = require('@embroider/test-setup');
  return maybeEmbroider(app);
};

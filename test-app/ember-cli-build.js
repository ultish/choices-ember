'use strict';

const path = require('path');
const EmberApp = require('ember-cli/lib/broccoli/ember-app');

/**
 * Monorepo + ember-try can leave multiple ember-source copies on disk.
 * choices-ember's precompiled gts calls setComponentTemplate from whichever
 * @ember/component webpack resolves for that package. If that is a different
 * ember-source than the app, getComponentTemplate is undefined and components
 * render as empty HTML comments.
 *
 * Force every ember-source path to the one resolved from this test-app.
 */
function dedupeEmberSourceWebpackPlugin(emberRoot) {
  // Lazy-require webpack from wherever ember-auto-import provides it
  let webpack;
  try {
    webpack = require('webpack');
  } catch {
    try {
      webpack = require(
        path.join(
          path.dirname(require.resolve('ember-auto-import/package.json')),
          'node_modules/webpack',
        ),
      );
    } catch {
      return null;
    }
  }

  const rootNorm = emberRoot.replace(/\\/g, '/');
  return new webpack.NormalModuleReplacementPlugin(
    /ember-source/,
    (resource) => {
      if (typeof resource.request !== 'string') {
        return;
      }
      const req = resource.request.replace(/\\/g, '/');
      // Absolute pnpm path into some other ember-source version
      const m = req.match(
        /^(.*)\/ember-source@[^/]+\/node_modules\/ember-source(\/.*)?$/,
      );
      if (m && !req.startsWith(rootNorm)) {
        resource.request = rootNorm + (m[2] || '');
      }
    },
  );
}

module.exports = function (defaults) {
  const emberRoot = path.dirname(
    require.resolve('ember-source/package.json', { paths: [__dirname] }),
  );
  const appNodeModules = path.join(__dirname, 'node_modules');
  const dedupePlugin = dedupeEmberSourceWebpackPlugin(emberRoot);

  let app = new EmberApp(defaults, {
    'ember-cli-babel': { enableTypeScriptTransform: true },
    autoImport: {
      watchDependencies: ['choices-ember'],
      webpack: {
        resolve: {
          modules: [appNodeModules, 'node_modules'],
        },
        plugins: dedupePlugin ? [dedupePlugin] : [],
      },
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

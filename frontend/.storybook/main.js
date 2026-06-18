const webpack = require('webpack');
const fs = require('fs');
const path = require('path');

const projectRootPath = path.resolve('.');
const lessPlugin = require('@plone/volto/webpack-plugins/webpack-less-plugin');
const RelativeResolverPlugin = require('@plone/volto/webpack-plugins/webpack-relative-resolver');
const scssPlugin = require('razzle-plugin-scss');

const createConfig = require('razzle/config/createConfigAsync.js');
const razzleConfig = require(path.join(projectRootPath, 'razzle.config.js'));

const SVGLOADER = {
  test: /icons\/.*\.svg$/,
  use: [
    {
      loader: 'svg-loader',
    },
    {
      loader: 'svgo-loader',
      options: {
        plugins: [
          {
            name: 'preset-default',
            params: {
              overrides: {
                convertPathData: false,
                removeViewBox: false,
              },
            },
          },
          'removeTitle',
          'removeUselessStrokeAndFill',
        ],
      },
    },
  ],
};

const defaultRazzleOptions = {
  verbose: false,
  debug: {},
  buildType: 'iso',
  cssPrefix: 'static/css',
  jsPrefix: 'static/js',
  enableSourceMaps: true,
  enableReactRefresh: true,
  enableTargetBabelrc: false,
  enableBabelCache: true,
  forceRuntimeEnvVars: [],
  mediaPrefix: 'static/media',
  staticCssInDev: false,
  emitOnErrors: false,
  disableWebpackbar: false,
  browserslist: [
    '>1%',
    'last 4 versions',
    'Firefox ESR',
    'not ie 11',
    'not dead',
  ],
};

module.exports = {
  stories: [
    '../packages/**/*.mdx',
    '../packages/**/*.stories.@(js|jsx|ts|tsx)',
  ],
  addons: [
    '@storybook/addon-links',
    '@storybook/addon-essentials',
    '@storybook/addon-webpack5-compiler-babel',
  ],
  framework: {
    name: '@storybook/react-webpack5',
    options: { builder: { useSWC: true } },
  },
  typescript: {
    check: false,
    checkOptions: {},
    reactDocgen: 'react-docgen-typescript',
    reactDocgenTypescriptOptions: {
      compilerOptions: {
        allowSyntheticDefaultImports: false,
        esModuleInterop: false,
      },
      propFilter: () => true,
    },
  },
  webpackFinal: async (config, { configType }) => {

    config.module.rules.push({
      test: /\.(js|jsx|ts|tsx)$/,
      exclude: /node_modules/,
      use: {
        loader: 'babel-loader',
        options: {
          presets: ['@babel/preset-env', '@babel/preset-react'],
        },
      },
    });

    let baseConfig;
    baseConfig = await createConfig(
      'web',
      'dev',
      {

        modifyWebpackConfig: razzleConfig.modifyWebpackConfig,
        plugins: razzleConfig.plugins,
      },
      webpack,
      false,
      undefined,
      [],
      defaultRazzleOptions,
    );
    const { AddonRegistry } = require('@plone/registry/addon-registry');

    const { registry } = AddonRegistry.init(projectRootPath);

    config = lessPlugin({ registry }).modifyWebpackConfig({
      env: { target: 'web', dev: 'dev' },
      webpackConfig: config,
      webpackObject: webpack,
      options: {},
    });

    config = scssPlugin.modifyWebpackConfig({
      env: { target: 'web', dev: 'dev' },
      webpackConfig: config,
      webpackObject: webpack,
      options: { razzleOptions: {} },
    });

    config.module.rules.unshift(SVGLOADER);
    const fileLoaderRule = config.module.rules.find((rule) =>
      rule.test.test('.svg'),
    );
    fileLoaderRule.exclude = /icons\/.*\.svg$/;

    config.plugins.unshift(
      new webpack.DefinePlugin({
        __DEVELOPMENT__: true,
        __CLIENT__: true,
        __SERVER__: false,
      }),
    );

    const resultConfig = {
      ...config,
      resolve: {
        ...config.resolve,
        alias: { ...config.resolve.alias, ...baseConfig.resolve.alias },
        fallback: { ...config.resolve.fallback, zlib: false },
        plugins: [
          ...(config.resolve.plugins || []),
          new RelativeResolverPlugin(registry),
        ],
      },
    };

    const addonPaths = registry
      .getAddons()
      .map((addon) => fs.realpathSync(addon.modulePath));

    resultConfig.module.rules[13].exclude = (input) =>

      /node_modules\/(?!(@plone\/volto)\/)/.test(input) &&

      /storybook-config-entry\.js$/.test(input) &&
      /storybook-stories\.js$/.test(input) &&

      !addonPaths.some((p) => input.includes(p));

      resultConfig.module.rules[13].include = [
        /preview\.jsx/,
        ...(Array.isArray(resultConfig.module.rules[13].include)
          ? resultConfig.module.rules[13].include
          : [resultConfig.module.rules[13].include].filter(Boolean)),
        ...addonPaths,
      ];

    const addonExtenders = registry.getAddonExtenders().map((m) => require(m));

    const extendedConfig = addonExtenders.reduce(
      (acc, extender) =>
        extender.modify(acc, { target: 'web', dev: 'dev' }, config),
      resultConfig,
    );

    return extendedConfig;
  },
};

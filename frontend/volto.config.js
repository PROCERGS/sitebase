const addons = [
  'volto-procergs-sitebase'
];
const theme = '';

// Keep addons static so the preparation scripts can register optional addons.
const configuredAddons = addons.some(
  (entry) => entry.split(':')[0] === 'volto-procergs-project-manager',
)
  ? require('volto-procergs-project-manager/build/configure-profiles.cjs').configureProfiles(addons)
  : addons;

module.exports = {
  addons: configuredAddons,
  theme
};

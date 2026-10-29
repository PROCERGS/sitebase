# Changes

## 1.3.4 (2026-10-29)

### Changed
- Update backend dependencies
- Upgrade the frontend package manager from `pnpm` 9.1.1 to 10.34.5.
- Upgrade frontend dependencies

### Fixed
- Preserve the `packageManager` field when merging frontend package metadata during the Docker build.

## 1.3.1 (2026-09-08)
### Fixed
 - Atualiza versões de ``plone.app.portlets`` para 6.0.4 e ``plone.app.event`` para 5.2.4 no ``mx.ini``.

## 1.3.0 (2026-08-19)

### Added
- Split `install` from a new `prepare` step (`make prepare` / `backend-prepare` / `frontend-prepare`) so site-specific customization (packages, addons, theme, mrs-developer entries, pnpm workspace) is decoupled from installation. **Workflow
change:** run `make prepare` before/instead of relying on `make install` to inject customizations.
- New customization variables: `FRONTEND_SET_THEME` and `FRONTEND_ADD_PNPM_WORKSPACE`.
- Hardened `add_addons.sh`, `add_mrsdeveloper.sh`, `add_packages.sh` against shell/JSON quoting issues; addon list deduplication; preserve pinned versions when injecting a package without an explicit version.
### Fixed
- Fixed Volto theme not being applied correctly via `FRONTEND_SET_THEME`/environment variable.
- Reduced frontend Docker build context and final image bloat (`.dockerignore` cleanup, drop redundant `pnpm build:deps`, exclude the test-only `volto-testing` workspace package from the production install, `pnpm store prune`).
- Bumped `tar` to `>=7.5.19` in the frontend.
- Removed a hard pin to `pnpm@9.1.1` in the frontend final image; the image now inherits a current `pnpm@9.x` from the base prod-config image.
### Removed
- Removed `authomatic`/OAuth2 SOE backend customization and its `pas.plugins.authomatic` dependency, plus the `@plone-collective/volto-authomatic` frontend dependency.


## 1.2.1 (2026-05-26)

- Fix backend Dockerfile permissions for OpenShift random UID compatibility (gid 0)

## 1.2.0 (2026-05-26)

- Backend Dockerfile fixes for Red Hat UBI9 base image

## 1.1.0 (2026-03-27)

- Add Dockerfile-based build parity with S2I scripts

## 1.0.0 (2024-09-27)

- Initial version [PROCERGS]

# Site Plone 🚀

[![Built with Cookieplone](https://img.shields.io/badge/built%20with-Cookieplone-0083be.svg?logo=cookiecutter)](https://github.com/plone/cookiecutter-plone/)
[![Black code style](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/ambv/black)
[![Backend Tests](https://github.com/PROCERGS/sitebase/actions/workflows/backend.yml/badge.svg)](https://github.com/PROCERGS/sitebase/actions/workflows/backend.yml)
[![Frontend Tests](https://github.com/PROCERGS/sitebase/actions/workflows/frontend.yml/badge.svg)](https://github.com/PROCERGS/sitebase/actions/workflows/frontend.yml)

Projeto para site base

## Quick Start 🏁

### Prerequisites ✅

Ensure you have the following installed:

- Python 3.11 🐍
- Node 22 🟩
- pnpm 🧶
- Docker 🐳

### Installation 🔧

1. Clone the repository:

```shell
git clone git@github.com:PROCERGS/sitebase.git
cd sitebase
```

2. Install both Backend and Frontend:

```shell
make install
```

### Fire Up the Servers 🔥

1. Create a new Plone site on your first run:

```shell
make backend-create-site
```

2. Start the Backend at [http://localhost:8080/](http://localhost:8080/):

```shell
make backend-start
```

3. In a new terminal, start the Frontend at [http://localhost:3000/](http://localhost:3000/):

```shell
make frontend-start
```

Voila! Your Plone site should be live and kicking! 🎉

### Local Stack Deployment 📦

Deploy a local `Docker Compose` environment that includes:

- Docker images for Backend and Frontend 🖼️
- A stack with a Traefik router and a Postgres database 🗃️
- Accessible at [http://sitebase.localhost](http://sitebase.localhost) 🌐

Execute the following:

```shell
make stack-start
make stack-create-site
```

And... you're all set! Your Plone site is up and running locally! 🚀

## Project Structure 🏗️

This monorepo consists of three distinct sections: `backend`, `frontend`, and `devops`.

- **backend**: Houses the API and Plone installation, utilizing pip instead of buildout, and includes a policy package named procergs.sitebase.
- **frontend**: Contains the React (Volto) package.
- **devops**: Encompasses Docker Stack, Ansible playbooks, and Cache settings.

### Why This Structure? 🤔

- All necessary codebases to run the site are contained within the repo (excluding existing addons for Plone and React).
- Specific GitHub Workflows are triggered based on changes in each codebase (refer to .github/workflows).
- Simplifies the creation of Docker images for each codebase.
- Demonstrates Plone installation/setup without buildout.

## Code Quality Assurance 🧐

To automatically format your code and ensure it adheres to quality standards, execute:

```shell
make check
```

Linters can be run individually within the `backend` or `frontend` folders.

## Internationalization 🌐

Generate translation files for Plone and Volto with ease:

```shell
make i18n
```

## Credits and Acknowledgements 🙏

Crafted with care by **Generated using [Cookieplone (0.8.1)](https://github.com/plone/cookieplone) and [cookiecutter-plone (5df29b1)](https://github.com/plone/cookiecutter-plone/commit/5df29b17884fa57bcdc799084ac3d35a4b9b76c6) on 2024-12-11 16:46:05.735881**. A special thanks to all contributors and supporters!

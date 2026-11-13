# AGENTS.md

> This file provides context for AI coding agents working in this repository.
> It complements [README.md](README.md) (human-oriented) with agent-executable instructions.

## Project Overview

This is an **OCA (Odoo Community Association) addon repository** for Odoo 19.0.
It contains a collection of Odoo modules for management system compliance
(ISO 9001, ISO 14001, ISO 45001, ISO 27001, etc.).

Each top-level directory (e.g. `mgmtsystem/`, `mgmtsystem_action/`) is a standalone
Odoo addon module with its own `__manifest__.py`, `pyproject.toml`, `models/`,
`views/`, `tests/`, `security/`, and `i18n/` directories.

## Setup commands

### Prerequisites

- **Python 3.10+** (pre-commit CI uses 3.12; test CI uses 3.10)
- **Odoo 19.0** runtime or the OCA CI container (`ghcr.io/oca/oca-ci/py3.10-odoo19.0:latest`)
- **PostgreSQL 13+** (for running tests)
- **Node.js 22+** (for pre-commit JS/ESLint/Prettier hooks; pinned to 22.9.0 in pre-commit config)

### Install pre-commit hooks

```bash
pip install pre-commit
pre-commit install
```

### Install addon dependencies (in OCA CI environment)

```bash
oca_install_addons
```

### Local development with Odoo

Clone this repo into your Odoo `addons_path`, then install desired modules:

```bash
odoo -d <database> -i mgmtsystem -u mgmtsystem --stop-after-init
```

To install all modules at once:

```bash
odoo -d <database> -i mgmtsystem,mgmtsystem_action,mgmtsystem_audit,mgmtsystem_kpi,mgmtsystem_manual,mgmtsystem_nonconformity,mgmtsystem_review,mgmtsystem_risk,mgmtsystem_quality,mgmtsystem_environment,mgmtsystem_health_safety,mgmtsystem_hazard,mgmtsystem_hazard_risk,mgmtsystem_information_security,mgmtsystem_security_event,mgmtsystem_survey,mgmtsystem_partner,mgmtsystem_nonconformity_hr,mgmtsystem_nonconformity_repair,mgmtsystem_info_security_manual,document_page_procedure,document_page_quality_manual,document_page_work_instruction,document_page_environmental_aspect,document_page_environment_manual,document_page_health_safety_manual
```

## Testing instructions

### Run all tests (OCA CI environment)

```bash
oca_init_test_database
oca_run_tests
```

### Run a specific module's tests with Odoo

```bash
odoo -d <database> -i mgmtsystem --test-enable --test-tags=/mgmtsystem --stop-after-init
```

### Run a single test class or method

```bash
odoo -d <database> -i mgmtsystem --test-enable --test-tags=mgmtsystem.TestModelAction --stop-after-init
odoo -d <database> -i mgmtsystem --test-enable --test-tags=mgmtsystem.TestModelAction.test_create_system --stop-after-init
```

### Run pre-commit checks (includes linting + formatting)

```bash
pre-commit run --all-files
```

To skip the auto-generated README check (useful when only editing README fragments):

```bash
SKIP=oca-gen-addon-readme pre-commit run --all-files
```

### CI workflow

CI is defined in `.github/workflows/`:

- **pre-commit.yml** — runs all pre-commit hooks on all files (Python 3.12).
- **test.yml** — runs the full test suite in two matrix variants:
  - `test with Odoo` (official Odoo 19.0, container `ghcr.io/oca/oca-ci/py3.10-odoo19.0:latest`)
  - `test with OCB` (OCA Community Backports 19.0, container `ghcr.io/oca/oca-ci/py3.10-ocb19.0:latest`)
  - Uses PostgreSQL 13 as a service container.
  - Sets `OCA_ENABLE_CHECKLOG_ODOO=1` to enable Odoo log checking (configured via `checklog-odoo.cfg`).
  - Steps: `oca_install_addons` → `manifestoo check-licenses` → `manifestoo check-dev-status --default-dev-status=Beta` → `oca_init_test_database` → `oca_run_tests` → codecov upload.
  - The OCB matrix job also exports `.pot` translation files on push to the OCA repo (`oca_export_and_push_pot`).
  - An `unreleased-deps` job rejects `requirements.txt` / `test-requirements.txt` entries that contain URLs or relative paths.
- **stale.yml** — automatically closes stale issues and PRs.

### Test conventions

- Tests live in `<addon>/tests/` and must have `__init__.py` importing test files.
- Use Odoo's `TransactionCase` for database-level tests, `HttpCase` for controller/JS tests.
- Every code change that adds or modifies model behavior **must** include or update corresponding tests.

## Code style

### Python

- **Formatter/Linter**: [Ruff](https://docs.astral.sh/ruff/) — config in `.ruff.toml`.
  - Target: Python 3.10
  - Selected rules: `B` (flake8-bugbear), `C90` (mccabe, max complexity 16), `E501` (line length, default 88), `I` (isort), `UP` (pyupgrade)
  - isort section order: `future → standard-library → third-party → odoo → odoo-addons → first-party → local-folder`
  - `setup/*` is excluded from ruff
  - `__init__.py`: F401 and I001 ignored (unused/unsorted imports OK)
  - `__manifest__.py`: B018 ignored
- **Pylint (Odoo)**: [pylint-odoo](https://github.com/OCA/pylint-odoo) — configs in `.pylintrc` (full, non-blocking, `--exit-zero`) and `.pylintrc-mandatory` (blocking).
  - Always run with `--rcfile=.pylintrc-mandatory` for blocking checks.
  - Mandatory rules include: `sql-injection`, `eval-used`, `dangerous-default-value`, `print-used`, `no-write-in-compute`, `external-request-timeout`, `license-allowed`, `manifest-required-author`, `manifest-required-key`, `manifest-version-format`, `translation-field`, `translation-required`, `translation-not-lazy`, `translation-fstring-interpolation`, `translation-injection`, and more (see `.pylintrc-mandatory` for the full list).
  - License-allowed values: `AGPL-3`, `GPL-2`, `GPL-2 or any later version`, `GPL-3`, `GPL-3 or any later version`, `LGPL-3`.
  - Valid Odoo version: `19.0`.
  - Manifest required author: `Odoo Community Association (OCA)`.
  - Manifest required key: `license`.
  - Manifest deprecated keys: `description`, `active`.

### JavaScript

- **Linter**: ESLint 9 — config in `eslint.config.cjs`.
  - `ecmaVersion: 2024`, `sourceType: "script"` (not module)
  - Globals (readonly): `odoo`, `openerp`, `owl`, `_`, `$`, `jQuery`, `moment`, `luxon`, `fuzzy`, `QUnit`, plus all `globals.browser`
- **Formatter**: Prettier — config in `prettier.config.cjs`.
  - Uses `@prettier/plugin-xml`
  - `printWidth: 88`, `semi: true`, `trailingComma: "es5"`, `bracketSpacing: false`, `proseWrap: "always"`, `xmlWhitespaceSensitivity: "preserve"`

### XML / HTML / CSS / YAML

- **Formatter**: Prettier with `@prettier/plugin-xml`.
- **EditorConfig**: `.editorconfig` — 4-space indent for most files, 2-space for JSON/YAML/RST/MD.

### Odoo module conventions

- Every module has a `__manifest__.py` with required keys: `name`, `version` (format `19.0.x.y.z`), `license` (allowed: AGPL-3, GPL-2, GPL-3, LGPL-3), `author` (must include "Odoo Community Association (OCA)").
- Models go in `<addon>/models/`, views in `<addon>/views/`, security in `<addon>/security/`.
- Translations live in `<addon>/i18n/` — **never create `en.po` files** (pre-commit hook rejects them).
- Module README is auto-generated from fragments in `<addon>/readme/` (DESCRIPTION.md, CONFIGURE.md, CONTRIBUTORS.md, CREDITS.md). The generated file is `<addon>/README.rst`.
- Each addon has a `pyproject.toml` with `[build-system]` using the `whool` backend.

## Dev environment tips

- **Navigating the repo**: Each top-level directory is an independent addon. Use `__manifest__.py` to understand dependencies (`depends` key).
- **Whool**: Addon packaging uses [whool](https://github.com/sbidoul/whool). The `setup/_metapackage/pyproject.toml` is the metapackage listing all addons.
- **Copier template**: This repo is generated from `oca-addons-repo-template` (see `.copier-answers.yml`). Do not edit `.copier-answers.yml` manually.
- **Renovate**: Dependency updates are managed by Renovate bot (`renovate.json`), enabled for Copier manager only.
- **`.pot` files**: Translation template files are auto-exported by CI in the OCB matrix job — do not manually edit unless fixing a translation source string.
- **README.md**: The top-level `README.md` addon table is auto-generated. Edit individual addon README fragments in `<addon>/readme/` instead.
- **`checklog-odoo.cfg`**: Configures `checklog-odoo` to suppress expected Odoo log warnings during CI tests.
- **Forbidden files**: `.rej` files (copier rejection junks), `en.po`, and obsolete dotfiles (`.travis.yml`, `.t2d.yml`, `CONTRIBUTING.md`, `.prettierrc.yml`, `.eslintrc.yml`) are rejected by pre-commit.

## PR / Commit instructions

### Branch conventions

- **Base branch**: `19.0`
- **Feature branches**: Named descriptively (e.g. `docs/add-agents-md`)
- **OCA bot branches**: `19.0-ocabot-*` (for translation exports)
- PRs should target the `19.0` branch (or `19.0-*` forward-port branches).

### Pre-commit requirements

Before committing, ensure all checks pass:

```bash
pre-commit run --all-files
```

Key checks that must pass (non-exhaustive):
- `ruff` (lint + format)
- `pylint_odoo` with `.pylintrc-mandatory` (blocking)
- `oca-checks-odoo-module` (Odoo module structure validation, runs with `--fix`)
- `oca-checks-po` (translation file validation)
- `prettier` (formatting for JS/XML/HTML/CSS/YAML/MD/TOML)
- `eslint` (JavaScript linting, runs with `--fix`)
- `whool-init` (addon packaging initialization)
- `oca-gen-addon-readme` (auto-generate addon README from fragments)
- `oca-gen-external-dependencies` (auto-generate external dependencies)
- Standard pre-commit hooks (trailing whitespace, end-of-file, merge conflicts, debug statements, etc.)

### Commit guidelines

- Write clear, descriptive commit messages.
- Include the OCA copyright header in new Python files:
  ```python
  # Copyright <Year> <Author>
  # License AGPL-3.0 or later (http://www.gnu.org/licenses/agpl).
  ```
- Keep PRs focused — one feature or fix per PR.
- All generated files (README.rst, etc.) must be checked into git.
- Ensure `manifestoo check-licenses` and `manifestoo check-dev-status --default-dev-status=Beta` pass.

### PR review

- PRs are reviewed by OCA maintainers.
- CI must pass (pre-commit + test matrix).
- Code coverage is reported via Codecov.

## Security gotchas

- **SQL injection**: Use Odoo's ORM query methods. Raw SQL must use parameterized queries. pylint-odoo enforces `sql-injection` detection.
- **No `eval()`**: The `eval-used` pylint rule is mandatory.
- **Dangerous defaults**: `dangerous-default-value` is enforced (avoid mutable default arguments).
- **License compliance**: All modules must declare an approved license in `__manifest__.py`. Check with `manifestoo check-licenses`.
- **Translation injection**: Translation strings must not use f-strings or `.format()` with user input — use lazy translation (`_()`) properly. pylint-odoo enforces `translation-fstring-interpolation`, `translation-injection`, `translation-not-lazy`, and related rules.
- **No sensitive data**: Never commit database credentials, API keys, or `.env` files. The `.gitignore` already excludes common patterns.
- **External requests**: `external-request-timeout` is enforced — always set timeouts on external HTTP requests.
- **No write in compute**: `no-write-in-compute` is enforced — do not call `write()` inside computed fields.

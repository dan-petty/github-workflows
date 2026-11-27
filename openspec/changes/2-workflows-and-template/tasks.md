# Tasks

## 1. The files of infra

Kind: other.

- [x] 1.1 Copy the reusable workflows `pr-title.yml`, `release.yml` and `k8s-validate.yml`, their scripts and config, `copier.yml`, `templates/`, the tests, the private-data guard and the lint config from infra `main`; keep only the tools of these checks in `mise.toml`, `mise.lock`, `pyproject.toml` and `uv.lock`
  - Verification: `mise install --locked` and `uv sync --frozen` exit 0

## 2. The callers of the template

Kind: behavior.

- [x] 2.1 Change the expectations of `tests/test-repository-template.sh` to callers of `dan-petty/github-workflows` and the answer `template_ref`, with no caller of a workflow of `dan-petty/infra`. See them fail with the template of infra
  - Verification: `$ mise exec -- tests/test-repository-template.sh`
- [x] 2.2 Render the callers of `dan-petty/github-workflows` and the answer `template_ref` in `copier.yml` and `templates/repository/`
  - Verification: `$ mise exec -- tests/test-repository-template.sh`

## 3. The workflows of this repository

Kind: other.

- [x] 3.1 Name this repository in the reusable workflows, the scripts and the config; remove `.copier-answers.yml`; call the local workflows from `pr-title-caller.yml` and `release-caller.yml`
  - Verification: `mise exec -- actionlint`, `.venv/bin/zizmor --offline .github/workflows/` and `git ls-files .copier-answers.yml` (no output)
- [x] 3.2 Run the moved checks in `ci.yml`, with `k8s-validate.yml` on `tests/fixtures/`, and test `scripts/k8s-validate.sh` with the fixtures and ignore files that the test writes
  - Verification: `mise exec -- tests/test-k8s-validate.sh`, `mise exec -- tests/test-ci-check-names.sh` and the checks of the pull request

## 4. Documents

Kind: other.

- [x] 4.1 Describe the workflows, the template, the releases and the checks in README.md, AGENTS.md and `templates/README.md`, and the files that a person now keeps in their own headers
  - Verification: read the sections; `.venv/bin/yamllint --strict .` and `mise exec -- scripts/private-data-scan.sh dir .` exit 0

## Workflow follow-up

- Pending a person: the first release `v0.1.0` of this repository after the merge, from the release pull request of `release-caller.yml`.
- Step 4 of dan-petty/infra#217: infra deletes the moved files and calls `k8s-validate.yml` of this repository; its Renovate presets match `dan-petty/github-workflows`; devops-cli sets `template_repository` to `dan-petty/github-workflows`; each consumer runs `copier recopy` from the new source.

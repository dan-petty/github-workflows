## Purpose

This repository is the source of the repository template and of the reusable workflows, not a render of the template: it pins no release of itself, and its root release tags are the versions that Copier and Renovate read.

## ADDED Requirements

### Requirement: The template source is not a render of the template
The repository SHALL hold no `.copier-answers.yml`. Its callers `.github/workflows/pr-title-caller.yml` and `.github/workflows/release-caller.yml` SHALL call the reusable workflows of the same commit with `uses: ./.github/workflows/<workflow>.yml`, and no workflow of the repository SHALL pin a release of the repository.

#### Scenario: No answers file and no pin of the repository
- **WHEN** `git ls-files .copier-answers.yml` and `grep -rn 'dan-petty/github-workflows/' .github/workflows/` run in the repository
- **THEN** both print nothing, and `mise exec -- actionlint` and `.venv/bin/zizmor --offline .github/workflows/` exit 0

#### Scenario: The title check keeps its name
- **WHEN** a pull request into `main` opens
- **THEN** the live check of the check runs of its head commit, `GET /repos/dan-petty/github-workflows/commits/<sha>/check-runs`, gives the check `PR title / Semantic PR title`

### Requirement: The releases are root tags
release-please SHALL release the root package with tags `vX.Y.Z` and no component, so that Copier and the copier manager of Renovate read each tag as a PEP 440 version. The first release SHALL be `v0.1.0`.

#### Scenario: The release-please config is valid
- **WHEN** `check-jsonschema` checks `release-please-config.json` and `.release-please-manifest.json` with the schemas of release-please
- **THEN** both pass

#### Scenario: The first release
- **WHEN** the first release pull request of `release-caller.yml` merges
- **THEN** the live check `GET /repos/dan-petty/github-workflows/releases/latest` gives the tag `v0.1.0`

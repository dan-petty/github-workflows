## Purpose

The form of each caller of a reusable workflow of this repository that the repository template renders: a supply-chain check accepts it, and only the copier update of the template writes it.

## ADDED Requirements

### Requirement: The template pins each caller to the commit of the rendered tag
Each caller of a reusable workflow that the repository template renders SHALL be `uses: dan-petty/github-workflows/.github/workflows/<workflow>.yml@<sha> # <tag>`. `<tag>` is the tag that Copier renders (`template_ref`, else `_commit`), and `<sha>` is the commit that Copier renders (`_copier_conf.vcs_ref_hash`). No rendered caller SHALL hold a bare tag, and no rendered file SHALL call a workflow of `dan-petty/infra`.

#### Scenario: Each answer set renders a commit SHA and the tag
- **WHEN** Copier renders the working tree with each answer set of the template test
- **THEN** `mise exec -- tests/test-repository-template.sh` finds a 40-character commit SHA and the comment `# <tag>` in each caller of `dan-petty/github-workflows`, no bare tag, and no file that names `dan-petty/infra/.github/workflows`

#### Scenario: A render of a lightweight release tag
- **WHEN** Copier renders the template at a lightweight tag `v1.0.0` with the release flow on
- **THEN** `mise exec -- tests/test-repository-template.sh` finds `@<sha> # v1.0.0` in `pr-title.yml` and `release.yml`, where `<sha>` is `git rev-parse v1.0.0^{commit}`

#### Scenario: A template folder with no git
- **WHEN** Copier renders a copy of `copier.yml` and `templates/` that is not a git repository
- **THEN** `mise exec -- tests/test-repository-template.sh` finds that the render fails with the message "Copier gives no commit of the template"

#### Scenario: This repository holds each called workflow
- **WHEN** Copier renders the working tree with the release flow on
- **THEN** `mise exec -- tests/test-repository-template.sh` finds each called workflow in `.github/workflows/` of this repository with `on: workflow_call`, and each secret that the release caller passes

#### Scenario: A supply-chain check of the render
- **WHEN** `.venv/bin/zizmor --offline` checks the workflows of a render of a release tag
- **THEN** it reports no `unpinned-uses` finding

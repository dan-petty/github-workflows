# template-file-owners Specification

## Purpose

The owner of each file of the repository template of this repository, so that `copier update` and `copier recopy` give no conflict and keep the content of the repository, and the scope descriptions, the extra labels and the required checks that a repository holds as answers.

## Requirements

### Requirement: Each file of the template has one owner
The template SHALL own each file that it renders, except `.github/renovate.json`, `.pre-commit-config.yaml`, `.devops/project.toml`, `version.txt` and `.release-please-manifest.json`, which the repository owns after the first copy (`_skip_if_exists` of `copier.yml`). `copier update` and `copier recopy --overwrite` SHALL give each file of the template the render of the target tag, keep each file of the repository as it is, and write no conflict marker and no rejected hunk.

#### Scenario: A copier update of a repository with its own content
- **WHEN** a render of `v1.0.0` holds its own content in the five files of the repository, the tag `v1.1.0` changes each file of the template, and `copier update --skip-answered --defaults --vcs-ref v1.1.0` runs
- **THEN** `mise exec -- tests/test-repository-template.sh` finds no conflict, no change in the five files, each other file equal to a render of `v1.1.0`, and each caller pinned to the commit of `v1.1.0`

#### Scenario: The re-adoption of a repository with changed template files
- **WHEN** the same repository also holds a label, a comment and caller pins of another release that the template does not render, and `copier recopy --skip-answered --defaults --overwrite --vcs-ref v1.1.0` runs
- **THEN** `mise exec -- tests/test-repository-template.sh` finds no conflict, no change in the five files, and each other file equal to a render of `v1.1.0`

### Requirement: The scope descriptions are an answer
The template SHALL render the description of a `scope/<scope>` label from the answer `scope_descriptions`, a mapping of a scope to its description, and else the description of the template. Copier SHALL refuse a description of a scope that is not `ci`, `deps`, `docs` or a scope of `scopes`, and a description that is not a text of 1 to 100 characters with no `"` or `\`.

#### Scenario: The answer gives a scope label its description
- **WHEN** Copier renders the working tree with `scopes=api,worker` and `scope_descriptions={api: "The HTTP API in api/", ci: "Workflows: build, scan and publish"}`
- **THEN** `mise exec -- tests/test-repository-template.sh` finds these two descriptions, the descriptions of the template for `deps` and `docs`, and "The area worker of this repository"

#### Scenario: Copier refuses a description that it cannot render
- **WHEN** Copier renders the working tree with a description of the scope `api` and no scope `api`, with a description that holds `"`, with an empty description, or with a list in place of a mapping
- **THEN** `copier copy` fails each time, and `mise exec -- tests/test-repository-template.sh` reports each refusal

### Requirement: The required checks are an answer
The ruleset `main` of `github/repository.yaml` SHALL require each check of the answer `required_checks`, once, and then the title check of `.github/workflows/pr-title.yml`, each with the integration 15368 of GitHub Actions. Copier SHALL refuse a check name with a character other than a letter, a digit, a space or `._/()-`.

#### Scenario: The default answers require the title check
- **WHEN** Copier renders the working tree with the default answers
- **THEN** `mise exec -- tests/test-repository-template.sh` finds one required check, named by the job of the caller and the job of `pr-title.yml` of this repository, and `check-jsonschema` accepts `github/repository.yaml`

#### Scenario: The answer adds checks
- **WHEN** Copier renders the working tree with `required_checks=K8s, Lint / yamllint,K8s`
- **THEN** `mise exec -- tests/test-repository-template.sh` finds the required checks `K8s`, `Lint / yamllint` and the title check, each from integration 15368

#### Scenario: Copier refuses a check name that is not plain
- **WHEN** Copier renders the working tree with `required_checks=K8s: lint`
- **THEN** `copier copy` fails, and `mise exec -- tests/test-repository-template.sh` reports the refusal

### Requirement: The template renders the folders of OpenSpec
The template SHALL render an empty `openspec/specs/.gitkeep` and an empty `openspec/changes/archive/.gitkeep` next to `openspec/config.yaml`, the layout that `openspec init` writes, so that a repository holds `openspec/specs/` before its first archived spec.

#### Scenario: Each render holds the two empty files
- **WHEN** Copier renders the working tree with each answer set of the test
- **THEN** `mise exec -- tests/test-repository-template.sh` finds `openspec/specs/.gitkeep` and `openspec/changes/archive/.gitkeep` in the exact file list of each render, each with 0 bytes

### Requirement: The extra labels are an answer
The template SHALL write each label of the answer `extra_labels`, a mapping of a label name to its `color` and `description`, into `.github/labels.yml` after the labels of the template, in the order of the answer. The default answer `{}` SHALL add no label.

#### Scenario: The answer adds the labels of the repository
- **WHEN** Copier renders the working tree with `release_flow=true`, `scopes=api` and `extra_labels` of the two labels `certified-by-sentinel` and `needs-guardrail`
- **THEN** `mise exec -- tests/test-repository-template.sh` finds the scope labels, the two `autorelease:` labels and then the two extra labels with their colors and descriptions, finds `extra_labels` in `.copier-answers.yml`, and `yamllint --strict` accepts `.github/labels.yml`

#### Scenario: The default answer adds no label
- **WHEN** Copier renders the working tree with the default answers
- **THEN** `mise exec -- tests/test-repository-template.sh` finds only the labels `scope/ci`, `scope/deps` and `scope/docs`, and `extra_labels: {}` in `.copier-answers.yml`

### Requirement: Copier refuses an extra label that it cannot render
Copier SHALL refuse an extra label with a name of `scope/*` or `autorelease:*` in any letter case, one name twice with another letter case, a name that is not a text of 1 to 50 characters with no `"` or `\`, a key other than `color` and `description`, a color that is not a text of six hexadecimal digits, or a description that is not a text of 1 to 100 characters with no `"` or `\`.

#### Scenario: Copier refuses each extra label of the test
- **WHEN** Copier renders the working tree with an extra label `scope/docs`, `Scope/API` or `autorelease: pending`, with the names `bug` and `BUG`, with a name that holds `"` or has 51 characters, with the color `#D73A4A`, `D73A4` or `123456` with no quotes, with no description or a description that holds `"`, with the key `colour`, with a text in place of the mapping of a label, or with a list in place of the mapping
- **THEN** `copier copy` fails each time with `Validation error for question 'extra_labels'`, and `mise exec -- tests/test-repository-template.sh` reports each refusal

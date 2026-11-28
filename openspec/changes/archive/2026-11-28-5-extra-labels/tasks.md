# Tasks

## 1. The answer extra_labels

Kind: behavior.

- [x] 1.1 Add the cases of `extra_labels` to `tests/test-repository-template.sh`: two extra labels with the release flow and a scope, their order, color and description, the answer in `.copier-answers.yml`, the default `{}`, and each refusal with the message of the validator. See them fail with the template of `main`
  - Verification: `$ mise exec -- tests/test-repository-template.sh`
- [x] 1.2 Add the question `extra_labels` with its validator to `copier.yml`, and write each extra label into `templates/repository/.github/labels.yml.jinja` after the labels of the template
  - Verification: `$ mise exec -- tests/test-repository-template.sh`

## 2. Documents

Kind: other.

- [x] 2.1 Describe `extra_labels` in `templates/README.md`: the question, the file `.github/labels.yml`, the owner, the answers of the re-adoption and the cases of the test
  - Verification: read the sections; `.venv/bin/yamllint --strict .` and `mise exec -- scripts/private-data-scan.sh dir .` exit 0

## Workflow follow-up

- After the release that holds this change, dan-petty/vibes re-adopts the template with `copier recopy` and its labels `certified-by-sentinel` and `needs-guardrail` in `extra_labels`, in a pull request of dan-petty/vibes.

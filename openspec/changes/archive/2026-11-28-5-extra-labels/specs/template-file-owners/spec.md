## ADDED Requirements

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

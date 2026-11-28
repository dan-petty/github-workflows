# Proposal: an answer for the labels that are not scopes

## Why
The template owns `.github/labels.yml` (#225) and writes it from the answers `scopes` and `scope_descriptions` and from the release flow. A repository has no answer for its own labels that are not scopes. dan-petty/vibes declares two such labels: `certified-by-sentinel`, which its workflow `pr-sentinel.yml` applies, and `needs-guardrail`, which its workflow `recursive-hardening.yml` reads. `copier recopy --skip-answered --defaults --overwrite --vcs-ref v0.1.0` over vibes removes both labels, so vibes cannot re-adopt the template without a loss. This change closes #5.

## What Changes
- The new question `extra_labels` of `copier.yml`: a YAML mapping of a label name to its `color` and `description`, with the default `{}`. Its validator refuses a name of a label of the template in any letter case (`scope/*` comes from `scopes`, `autorelease:*` from release-please), one name twice with another letter case, a name that is not a text of 1 to 50 characters with no `"` or `\`, a label with a key other than `color` and `description`, a color that is not a text of six hexadecimal digits, and a description that is not a text of 1 to 100 characters with no `"` or `\`.
- `templates/repository/.github/labels.yml.jinja` writes each label of `extra_labels` after the labels of the template, in the order of the answer. A render with the default answer gives the same labels as before.
- `tests/test-repository-template.sh` renders two extra labels with the release flow and a scope, and checks the order, the color and the description of each label, the answer in `.copier-answers.yml`, and each refusal with the message of the validator.
- `templates/README.md` describes the question, the file, the owner and the re-adoption with `extra_labels`.

## Capabilities
- `template-file-owners` (modified): the new requirements "The extra labels are an answer" and "Copier refuses an extra label that it cannot render".

## Impact
- A new question with a default: `copier update --skip-answered --defaults` of a rendered repository gives `extra_labels: {}` and the same labels. The change is not breaking, and its type is `feat`.
- A repository with its own labels keeps them with `--data extra_labels=<mapping>` or with `extra_labels` in the `--data-file` of the re-adoption.
- The change fits one pull request.

## Feasibility
Confirmed on 2026-11-28 with Copier 9.19.1 (`uv.lock`):
- Copier renders a question of `type: yaml` as a Python mapping, and runs its `validator` on an answer of `--data`. A validator that renders text fails the render with `Validation error for question '<question>': <text>` (`copier/_user_data.py`, `Question.validate_answer`). The question `scope_descriptions` already uses this form.
- With no question `extra_labels`, `copier copy --data extra_labels=<mapping>` succeeds and renders no label: 18 of the 175 cases of the new test fail with the template of `main`, and 175 of 175 pass with this change.
- A recopy of dan-petty/vibes (`main` at 1f66cad) from this branch with `extra_labels` of its two labels keeps both labels in `.github/labels.yml`, with their colors and descriptions.

## Existing Tool Considered
Copier answers are the standard Copier form for a fact of a repository, and the template already holds `scopes`, `scope_descriptions` and `required_checks` this way. `_skip_if_exists` for `.github/labels.yml` would give the file to the repository, so each repository drifts from the labels of the template: the owner rejected it on 2026-11-27. The change adds no script and deletes no code.

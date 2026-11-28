# Design

## Decisions
- **One answer `extra_labels`, a mapping of a name to `{color, description}`.** A mapping gives each name once, as `scope_descriptions` does, and Copier writes it into `.copier-answers.yml` as YAML, so `copier update` keeps the labels.
- **The template writes the extra labels after its own labels, in the order of the answer.** The scope labels and the labels of release-please keep their place, so a render with the default answer gives the same labels as before.
- **The validator refuses the names of the template in any letter case.** GitHub ignores the letter case of a label name. A `scope/*` label outside `scopes` would add a scope that the answer `scopes` does not hold, and release-please owns the `autorelease:` labels. The validator refuses the two prefixes, not only the names that the template writes now.
- **The validator refuses a color or a description that the file or GitHub cannot hold.** The template writes each value in double quotes, so a `"` or a `\` breaks the YAML. GitHub allows 50 characters in a label name and 100 in a description, and a color of six hexadecimal digits with no `#`. A color with digits only, such as `123456`, is a number in YAML: the validator refuses it, and the user writes it in quotes.
- **The template writes the color as the answer gives it.** GitHub accepts a color in each letter case.

## Rejected alternatives
- **`_skip_if_exists` for `.github/labels.yml`.** The repository would then own the file, and its labels would drift from the labels of the template. The owner rejected it on 2026-11-27.
- **A YAML list of `{name, color, description}`, the form of `.github/labels.yml`.** A list can hold one name twice, so the validator needs one more rule, and the form differs from `scope_descriptions`.
- **Refuse the workflow labels of devops-cli, such as `type/*` and `status/*`.** The template does not know the list of devops-cli, and a copy of the list in the template would drift.

# Proposal: move the reusable workflows and the template from infra

## Why
dan-petty/infra holds the reusable workflows `pr-title.yml`, `release.yml` and `k8s-validate.yml`, the Copier repository template, and its platform code, and it releases all of them as one version. Each release of infra thus moves the workflow pins and the template of each consumer, also when no workflow and no template file changed (dan-petty/infra#217: 27 pin pull requests for 10 releases from 2026-11-25 to 2026-11-27). This is step 3 of dan-petty/infra#217 and closes #2.

Owner, 2026-11-27: "I should have a github workflows repo that holds any workflow code that is needed and leverage standard code and libraries where possible", and "standardize templates and workflows where possible".

## What Changes
- Copy the three reusable workflows, the scripts and the config that they run (`scripts/pr-title-scopes.sh`, `scripts/k8s-validate.sh`, `.kube-linter.yaml`), the tool pins that they install (`mise.toml`, `mise.lock`), `copier.yml`, `templates/` and their tests from infra `main` (v0.26.1). `clear-status.yml` does not move: infra deletes it.
- The template renders each caller as `uses: dan-petty/github-workflows/.github/workflows/<workflow>.yml@<sha> # <tag>`. The answer `infra_ref` that Copier does not ask becomes `template_ref`.
- This repository is the template source, not a render of it: `.copier-answers.yml` goes, and the callers `pr-title-caller.yml` and `release-caller.yml` call the workflows of the same commit with `uses: ./.github/workflows/<workflow>.yml`. The job names keep the check `PR title / Semantic PR title`.
- `ci.yml` runs the moved tests, actionlint, `zizmor --offline`, `yamllint --strict`, shellcheck and the private-data guard, with the path filters of infra. It calls `k8s-validate.yml` with the fixtures `tests/fixtures/`, and the job `K8s` reports its result. `tests/test-k8s-validate.sh` uses these fixtures and ignore files that it writes, in place of the charts and the ignore files of infra.
- The private-data guard of infra (`scripts/private-data-scan.sh`, `.gitleaks.toml`, its test and its pre-commit hook) moves.
- README.md, AGENTS.md and `templates/README.md` describe the workflows, the template, the releases and the checks of this repository.

## Capabilities
- `template-file-owners` (new here): the owner of each file of the template, and the answers `scope_descriptions` and `required_checks`, as infra specified them.
- `template-workflow-pins` (new here): the template pins each caller of this repository to the commit of the rendered tag.
- `pr-title-scopes` (new here): the scopes that `pr-title.yml` accepts. The requirement on the labels of infra stays in infra.
- `ci-check-names` (new here): the check `K8s` of `ci.yml` reports one name.
- `reusable-workflow-runner` (new here): the input `runs-on` of `k8s-validate.yml` and `pr-title.yml`.
- `template-source` (new): this repository is the template source, calls its own workflows and releases root tags.
- `renovate-copier` stays in infra with the Renovate presets.

## Impact
- No consumer changes in this pull request. infra, devops-cli and each consumer change in step 4 of dan-petty/infra#217, after the first release `v0.1.0` of this repository.
- The concurrency groups of `pr-title.yml` and `release.yml` start with `github-workflows-`, and each workflow checks out its own commit into `.workflow-source`. A caller sets no group with that prefix.
- The change fits one pull request.

## Feasibility
Confirmed on 2026-11-27:
- With the files of infra `main`, `mise exec -- tests/test-repository-template.sh` passes 137 of 137 cases here. With the new expectations and the old template, 23 of 145 cases fail; with the new template, 145 of 145 pass.
- A caller of the same repository with `uses: ./.github/workflows/<workflow>.yml` runs the workflow of the same commit, and `job.workflow_repository` and `job.workflow_sha` name that commit, as `pr-title-caller.yml` of infra shows on each pull request of infra.
- Copier sorts the tags of a template with PEP 440, and the copier manager of Renovate 45.1.0 uses the versioning `pep440` (dan-petty/infra#217), so the tags stay root tags `vX.Y.Z`.

## Existing Tool Considered
The workflows keep the maintained actions of infra: amannn/action-semantic-pull-request, googleapis/release-please-action, actions/create-github-app-token, actions/checkout, jdx/mise-action and dorny/paths-filter. The private-data guard keeps gitleaks: gitleaks takes no rule from an environment variable, so the script of infra that writes the rule of `PRIVATE_DOMAINS` into a temporary config moves with it (60 lines, no new code). GitHub secret scanning is on, but it finds no private address, host name or device path. No script is added. The change deletes `.copier-answers.yml` and the two rendered callers of this repository.

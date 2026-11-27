# Design

## Decisions
- **The workflows and the template move together.** A caller pins `_copier_conf.vcs_ref_hash` with the comment `# <_commit>`, so the pin and the template version are one release and the template needs no second answer.
- **The answer `infra_ref` becomes `template_ref`.** Copier does not ask it and does not write it into `.copier-answers.yml`, so no consumer holds it. The tests give it to render the working tree with a known tag.
- **The callers of this repository have their own names.** The reusable workflows keep the paths `pr-title.yml` and `release.yml` that each consumer calls, so the callers of this repository are `pr-title-caller.yml` and `release-caller.yml`, as in infra. The caller job `PR title` and the called job `Semantic PR title` keep the required check.
- **The concurrency groups and the checkout folder name this repository.** `github-workflows-pr-title-<pr>` and `github-workflows-release-<ref>`, and `.workflow-source`: the old names `infra-` and `.infra-workflow` named a repository that no longer holds the workflows.
- **Local fixtures for `k8s-validate.yml`.** `tests/fixtures/` holds the example Kustomize base, component and overlay and the example chart of infra. `tests/test-k8s-validate.sh` writes its own trivy and kube-linter ignore files, so it tests the script and no judgment of a consumer.
- **The private-data guard moves.** The repository is public, and the template writes files into other repositories. The guard of infra already covers this need with gitleaks.
- **`github/repository.yaml` stays a file that a person keeps.** `devops repos onboard` reads the baseline from the render of the template, not from this file, so the file lists only the title check, as the render gave it.

## Rejected alternatives
- **Keep the template in infra with a component tag such as `template-v1.2.3`.** Copier and the copier manager of Renovate need PEP 440 root tags, and each consumer keeps two pins (dan-petty/infra#217).
- **Transfer retric-ai/github-actions.** The owner created this repository in place of the transfer, and a workflow of another owner cannot use the self-hosted runner of a private dan-petty repository (dan-petty/infra#217).
- **Keep this repository a render of its own template.** Its callers then pin its own release tags, and each release opens a copier update in this repository (the loop of dan-petty/infra#225).
- **A workflow that is both the caller and the reusable workflow (`on: pull_request` and `on: workflow_call`).** The check name then differs between the two events, and actionlint and zizmor check one file for two roles.
- **gitleaks-action in place of the script.** It runs the same gitleaks with no rule from `PRIVATE_DOMAINS`, and the pre-commit hook needs the script anyway.
- **Move `tests/test-k8s-validate.sh` with the fixtures of infra.** The charts and the ignore files of infra stay in infra, and the judgments of infra are not judgments of this repository.

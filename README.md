# github-workflows

The reusable GitHub Actions workflows and the Copier repository template of the repositories of
dan-petty, and the checks that test them. A repository renders the template once, and the template
writes the callers of the workflows. The workflows and the template have one release stream: a
release tag `vX.Y.Z` of this repository is a release of both. The shared Renovate presets stay in
[dan-petty/infra](https://github.com/dan-petty/infra) (`renovate/`).

## The repository holds no private data

The repository is public, and the template writes files into other repositories. It holds no
secret and no value of one environment: no real domain, no host or node name, no private address,
no device path and no token. Templates, tests and documents use `example.com` and the RFC 5737
addresses 192.0.2.0/24, 198.51.100.0/24 and 203.0.113.0/24. The private-data guard of CI refuses
each of these values ("Private-data guard").

## Layout

| Path | Content |
| --- | --- |
| `.github/workflows/` | The reusable workflows `k8s-validate.yml`, `pr-title.yml` and `release.yml`, CI (`ci.yml`), and the callers of this repository: the title check (`pr-title-caller.yml`) and the releases (`release-caller.yml`). |
| `scripts/` | The scripts that the reusable workflows run (`k8s-validate.sh`, `pr-title-scopes.sh`), and the private-data guard (`private-data-scan.sh`). |
| `.kube-linter.yaml` | The shared kube-linter config of `k8s-validate.yml`. |
| `copier.yml`, `templates/` | The Copier template of a new repository (`templates/repository/`) and the schema of its settings baseline ([templates/README.md](templates/README.md)). |
| `tests/` | The test of each script, of the template and of the check names of `ci.yml`. `tests/fixtures/` holds the Kustomize root and the Helm chart that CI gives to `k8s-validate.yml`. |
| `openspec/` | The specs of the workflows and of the template, and the archived changes. |

## Pin a release

A repository pins this repository at a release tag `vX.Y.Z`, never at `main`. A caller of a
reusable workflow pins `<sha>`, the commit of the tag (`git rev-parse vX.Y.Z^{commit}`), with the
tag in a comment: the github-actions manager of Renovate writes this form for a digest pin, and a
repository with a supply-chain rule refuses a bare tag. The commit of the tag is the digest that
Renovate reads, also for an annotated tag.

| Form | Pin |
| --- | --- |
| Reusable workflow | `uses: dan-petty/github-workflows/.github/workflows/<workflow>.yml@<sha> # vX.Y.Z` |
| Copier template | `copier copy --vcs-ref vX.Y.Z https://github.com/dan-petty/github-workflows.git <dir>`, which writes `_commit: vX.Y.Z` into `.copier-answers.yml` ([templates/README.md](templates/README.md)) |

Each pin has one owner. The template renders the callers `.github/workflows/pr-title.yml` and
`.github/workflows/release.yml` of a repository at the commit of the tag that it renders, so the
copier update of the template moves these pins, and Renovate leaves them alone (a package rule of
the `renovate/base.json` preset of dan-petty/infra). Renovate moves each other pin, such as a
caller of `k8s-validate.yml`.

## Releases

[release-please](https://github.com/googleapis/release-please-action) makes each release. On each
push to `main`, `.github/workflows/release-caller.yml` calls the reusable workflow `release.yml` of
the same commit ("Call the reusable workflows"), which opens or updates one release pull request.
It holds the next version in `version.txt` and `.release-please-manifest.json`, and the new entry
of `CHANGELOG.md`. The workflow turns on auto-merge and requests review (`dan-petty` by default) on
the release pull request, and GitHub merges it when its required checks pass; a person can also
merge it. The next run of release-please creates the tag `vX.Y.Z` and its GitHub release. With the
repository setting *immutable releases*, nobody can move or delete a published tag, so a pin
always gets the same content.

The tags are root tags `vX.Y.Z` (`include-component-in-tag: false` of
`release-please-config.json`). Copier sorts the tags of a template with PEP 440, and the copier
manager of Renovate compares them with the versioning `pep440`, so a tag with a component prefix
such as `template-v1.2.3` does not work for either.

release-please reads the type of each commit on `main` since the last release. The largest change
gives the next version. The squash commit of a pull request gets the title of the pull request, so
write the title as a Conventional Commit. `.github/workflows/pr-title-caller.yml` calls the
reusable workflow `pr-title.yml` of the same commit, which checks the title of each pull request
and the subject of the commit of a pull request with one commit:

| Commit | Next version |
| --- | --- |
| The first release | `v0.1.0` (`initial-version` of `release-please-config.json`) |
| A breaking change: `!` after the type, or a `BREAKING CHANGE:` footer | The next major version. Renovate opens a major update as a separate pull request. |
| `feat` | The next minor version |
| `fix`, `perf` or `revert` | The next patch version |
| `build`, `chore`, `ci`, `docs`, `refactor`, `style` or `test` | No release of its own |

A change of a workflow input or of a template question that a caller must follow is a breaking
change. A change of a document or of a test only is not a release: its type is `docs` or `test`.

The release App gives the token of the job, so the checks of `ci.yml` run on the release pull
request. A pull request that `GITHUB_TOKEN` opens starts no workflow. The job runs in the
environment `release`, which holds the variable `RELEASE_APP_CLIENT_ID` and the secret
`RELEASE_APP_PRIVATE_KEY` of the App. When one of them is missing, the job stops with an error that
names it.

This repository is the template source, not a render of it: it has no `.copier-answers.yml`, and
its callers call the workflows of the same commit with `uses: ./.github/workflows/<workflow>.yml`.
Thus it pins no release of itself, and a release opens no pull request in this repository.

## Call the reusable workflows

A repository calls a reusable workflow at the commit of a release tag ("Pin a release"). The job
that calls it gives the permissions that the called job needs: a called workflow can only reduce
them. Each workflow runs the actions and the tools of its own commit, so a caller gets the versions
of its tag. This repository calls each workflow of its own commit, so its checks test them:
`ci.yml` calls `k8s-validate.yml` with the fixtures of `tests/fixtures/`, `pr-title-caller.yml`
calls `pr-title.yml` and `release-caller.yml` calls `release.yml`. The job YAML of `ci.yml` runs
[zizmor](https://docs.zizmor.sh/) over the workflows: each action has a pin to a commit SHA, no job
gets more permissions than it needs and no call passes `secrets: inherit`. `.github/zizmor.yml`
holds its settings.

`k8s-validate.yml` and `pr-title.yml` take the input `runs-on`, the runner label of the called job.
Empty, the default, selects the GitHub-hosted runner `ubuntu-26.04`. A `workflow_call` input is a
boolean, a number or a string, so the input names one label, such as the name of a runner scale set.
A caller with the runner name in the variable `RUNNER` passes `runs-on: ${{ vars.RUNNER }}`: when
the variable is not set, the value is empty
([GitHub docs](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#vars-context)).
The called job can use a self-hosted runner of the caller only when the caller and this repository
have the same owner
([GitHub docs](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations#how-reusable-workflows-use-runners)).

`pr-title.yml` and `release.yml` set the concurrency of their job, with a group that starts with
`github-workflows-`. A caller needs no concurrency group. When it sets one, the group must not start
with `github-workflows-`: the same group in a caller and a called workflow can cancel the caller
([GitHub docs](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations#supported-keywords-for-jobs-that-call-a-reusable-workflow)).

### `k8s-validate.yml`

`.github/workflows/k8s-validate.yml` (`on: workflow_call`) checks Kubernetes manifests, Helm charts
and Prometheus rules. It runs `kustomize build` and `helm template` into `kubeconform -strict` (with
the CRD schemas of the [datreeio CRDs-catalog](https://github.com/datreeio/CRDs-catalog), and the
non-standalone schema of `CustomResourceDefinition` of
[yannh/kubernetes-json-schema](https://github.com/yannh/kubernetes-json-schema)), kube-linter and
`trivy config` (HIGH and CRITICAL findings), and `helm lint --strict`, `helm unittest` and
`promtool check rules`. The render writes each object to its own file
`<n>-kustomize-<root>/` or `<n>-helm-<release>/`, then `<namespace>/` when the object has one, then
`<kind>-<name>.yaml`. Thus each finding names one object, and an entry of an ignore file can name
the file of one object. A chart folder `test-chart` is the test chart of the values template
`../values.yaml` of an upstream chart: it has one dependency, the upstream chart, and gets the
values template under the name of that dependency. The workflow installs the tools of the
`mise.lock` of its own commit, so a caller gets the tool versions of its tag.

```yaml
jobs:
  k8s:
    uses: dan-petty/github-workflows/.github/workflows/k8s-validate.yml@<sha> # vX.Y.Z
    permissions:
      contents: read
    with:
      kustomize-roots: |
        k8s/overlays/example
      helm-charts: |
        charts/example
      promtool-rules: |
        k8s/rules/example.rules.yaml
```

| Input | Content |
| --- | --- |
| `kustomize-roots` | The Kustomize folders to build, one on each line. |
| `helm-charts` | The Helm chart folders to lint, render and test, one on each line. Each `ci/*-values.yaml` file of a chart gives one render. |
| `kube-linter-config` | The kube-linter config file of the caller. Empty selects the shared `.kube-linter.yaml` of this repository. |
| `kube-linter-ignorefile` | The kube-linter ignore file of the caller: a list `checks` of entries with `check`, `paths` (patterns of the rendered files), `statement` and `expired_at`. The step adds the annotation `ignore-check.kube-linter.io/<check>` to each object that an entry names. After `expired_at`, the step stops. Empty gives no ignore file. |
| `promtool-rules` | The Prometheus rule files to check, one on each line. |
| `trivy-ignorefile` | The trivy ignore file of the caller, in the YAML form of trivy (`misconfigurations` with `id`, `paths`, `statement` and `expired_at`), which `trivy config` gets with `--ignorefile`. Empty gives no ignore file. |
| `runs-on` | The runner label of the job. Empty selects `ubuntu-26.04` ("Call the reusable workflows"). |

Each path is relative to the root of the caller repository. The shared `.kube-linter.yaml` holds
the default checks of kube-linter, five more checks and two custom checks. `pvc-prune-protection`:
a PersistentVolumeClaim must have the Argo CD sync options `Prune=false` and `Delete=false`.
`network-policy-egress-alone`: a NetworkPolicy with egress rules must not have the type `Ingress`.

A ruleset cannot require the check of a call that a condition can skip: GitHub names it
`<job> / Validate` when it runs and `<job>` when it is skipped. `ci.yml` thus has the job `K8s`,
which always reports and fails when the call failed (`tests/test-ci-check-names.sh`).

### `pr-title.yml`

`.github/workflows/pr-title.yml` (`on: workflow_call`) checks the title of a pull request with
[action-semantic-pull-request](https://github.com/amannn/action-semantic-pull-request): a
Conventional Commit, with a summary of at most 60 characters ("Releases"). For a pull request with
one commit, it also checks the subject of the commit (`validateSingleCommit`), because the squash
commit then gets that subject. Each type of Conventional Commits is allowed, and the scope is
optional. The scopes are the name after `scope/` of each `scope/*` label of the
`.github/labels.yml` of the caller, and these scopes of every repository, which need no label:

| Scope | Writer |
| --- | --- |
| `ci`, `deps`, `docs` | The repository template and the updates of Renovate, such as `chore(deps)` |
| `main` | The release pull request of release-please |
| `spec` | The plan pull request of devops-cli, such as `docs(spec)` |

The job reads the labels file of the commit of the run with `scripts/pr-title-scopes.sh` of its
own commit, so a new scope label needs no change of the workflow. When the labels file is missing,
the job stops with an error that names it.

```yaml
on:
  pull_request:
    types: [opened, edited, synchronize, reopened]
    branches:
      - main

permissions: {}

jobs:
  pr-title:
    name: PR title
    uses: dan-petty/github-workflows/.github/workflows/pr-title.yml@<sha> # vX.Y.Z
    permissions:
      contents: read
      pull-requests: read
```

The type `edited` runs the check again after a change of the title. The check of the caller above
has the name `PR title / Semantic PR title`.

| Input | Content |
| --- | --- |
| `runs-on` | The runner label of the job. Empty selects `ubuntu-26.04` ("Call the reusable workflows"). |

### `release.yml`

`.github/workflows/release.yml` (`on: workflow_call`) runs release-please with the token of the
release App ("Releases"). Its job runs in the environment `release` of the caller, which holds the
variable `RELEASE_APP_CLIENT_ID` and the secret `RELEASE_APP_PRIVATE_KEY` of the App. A job that
calls a reusable workflow cannot set `environment`, so the called job sets it. The caller must
still pass the secret by name, and the job then gets the value of the environment secret
([GitHub docs](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows#using-inputs-and-secrets-in-a-reusable-workflow)).
When the caller does not pass the secret, the run stops before the job starts. When the
environment does not hold the variable or the secret, the first step stops the job with an error
that names each missing credential. Keep the key only in the environment `release`: the workflows
of each branch can read a repository secret.

```yaml
on:
  push:
    branches:
      - main

permissions: {}

jobs:
  release:
    name: Release
    uses: dan-petty/github-workflows/.github/workflows/release.yml@<sha> # vX.Y.Z
    permissions: {}
    secrets:
      RELEASE_APP_PRIVATE_KEY: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
```

| Input | Content |
| --- | --- |
| `config-file` | The release-please config file of the caller, which holds the release type of each package. The default is `release-please-config.json`. |
| `manifest-file` | The release-please manifest file of the caller. The default is `.release-please-manifest.json`. |
| `reviewers` | The GitHub logins to request as reviewers of the release pull request, separated by commas. The default is `dan-petty`. |

| Output | Content |
| --- | --- |
| `release_created` | `true` when the run created the release of the root package, else empty. |
| `tag_name` | The tag of that release, such as `v1.2.3`, else empty. |

A later job of the caller can publish the release with `needs: release` and
`if: needs.release.outputs.release_created == 'true'`.

## Repository template

`copier.yml` and `templates/repository/` are the Copier template of a new repository.
`devops repos onboard` of devops-cli renders it into each new repository, and the copier manager of
Renovate brings each new release with `copier update`. [templates/README.md](templates/README.md)
tells the questions, the files, the owner of each file and the settings baseline.

## Tools

The repository pins each tool of the workflows and of the checks. `mise.toml` and `mise.lock` pin
the binary tools (actionlint, gitleaks, helm, helm-unittest, jq, kube-linter, kubeconform,
kustomize, Node, promtool, shellcheck, trivy, uv and yq), with the checksum of each download. The
test of the template runs the Renovate release of `tests/test-repository-template.sh` with the
`npx` of that Node. `pyproject.toml` and `uv.lock` pin the Python tools (check-jsonschema, Copier,
pre-commit, yamllint and zizmor). Install them into one shared cache folder and into `.venv`:

```sh
export MISE_DATA_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/infra-tools/mise"
mise install --locked
uv sync --frozen
```

To change a version, edit `mise.toml` and run `mise lock --platform linux-x64,linux-arm64`, or edit
`pyproject.toml` and run `uv lock`. Renovate proposes each update.

## Checks

`.github/workflows/ci.yml` runs on each pull request, each push to `main` and each manual run
(`workflow_dispatch`). A job runs only when a change touches the files of its tool. A manual run
runs every job. The check `K8s` always reports, with the result of the validation job `K8s run`,
so a ruleset can require it. To run a job locally, run its command from the repository root:

| Job | Command |
| --- | --- |
| Private-data guard | `mise exec -- tests/test-private-data-scan.sh` and `mise exec -- scripts/private-data-scan.sh dir .` |
| K8s | `KUSTOMIZE_ROOTS=tests/fixtures/k8s/tests/example HELM_CHARTS=tests/fixtures/charts/example PROMTOOL_RULES=tests/fixtures/k8s/components/example/rules/example.rules.yaml mise exec -- scripts/k8s-validate.sh all` |
| kube-linter config | `mise exec -- tests/test-kube-linter-config.sh` |
| K8s script | `mise exec -- tests/test-k8s-validate.sh` |
| YAML | `.venv/bin/yamllint --strict .` and `.venv/bin/zizmor --offline .github/workflows/` |
| actionlint | `mise exec -- actionlint`, `mise exec -- tests/test-pr-title-scopes.sh` and `mise exec -- tests/test-ci-check-names.sh` |
| shellcheck | `git ls-files -z '*.sh' \| xargs -0 mise exec -- shellcheck` |
| Repository template | `mise exec -- tests/test-repository-template.sh` ([templates/README.md](templates/README.md#test)) |

## Private-data guard

`scripts/private-data-scan.sh` runs [gitleaks](https://github.com/gitleaks/gitleaks) with
`.gitleaks.toml`: the default rules of gitleaks for secrets, and rules for RFC 1918, CGNAT and
link-local addresses, for names that end in `.lan` or `.local`, and for device paths. The allowlist
admits the k3s default cluster CIDR `10.42.0.0/16` and Service CIDR `10.43.0.0/16`, the block of
each private range (such as `10.0.0.0/8`), the Kubernetes cluster domain and the pseudo-devices
such as `/dev/null`. `tests/test-private-data-scan.sh` holds a case for each rule.

The guard also refuses each domain of the environment variable `PRIVATE_DOMAINS` (one domain on
each line) and each subdomain of it. gitleaks takes no rule from an environment variable, so the
script writes this one rule into a temporary copy of the config. In CI, the value comes from the
Actions secret `PRIVATE_DOMAINS`, so no file holds a real domain. When the secret is not set, the
job writes a warning in its log and its summary, and runs the other rules.

## Pre-commit hooks

After `uv sync --frozen`, run `.venv/bin/pre-commit install` once in each clone. The hooks of
`.pre-commit-config.yaml` refuse a commit on `main`, check the syntax of the YAML, JSON and TOML
files, and run the private-data guard on the staged changes.

# github-workflows — AI Agent Instructions

github-workflows holds the reusable GitHub Actions workflows and the Copier repository template of the repositories of dan-petty, and the checks that test them.

This file is the single source of truth for AI agent instructions. [CLAUDE.md](./CLAUDE.md), [GEMINI.md](./GEMINI.md) and [.github/copilot-instructions.md](./.github/copilot-instructions.md) are thin pointers to this file.

## Rules for every task

1. Branch from `main` and open a pull request for every change. Open it as a draft with `devops pr create`, and close its one issue (`Closes #<issue>`).
2. Plan each item as the OpenSpec change `openspec/changes/<issue>-<slug>/`, and archive the change in the last commit with `devops openspec archive <change>`.
3. Write the test before the code.
4. Before you push, run the command of each CI job whose files your change touches (README.md, "Checks").
5. Keep secrets and private data out of the repository: use `example.com` and the RFC 5737 addresses in all templates. Keep the private-data guard passing.
6. Pin consumers at the commit of a release tag `vX.Y.Z`, with the tag in a comment, never at `main`. This repository calls its own workflows with `./.github/workflows/<workflow>.yml`.
7. Install the tools with `mise install --locked` and `uv sync --frozen` (README.md, "Tools"). Run `uv lock` after a version change in `pyproject.toml`.
8. Change a file that the template renders in `templates/repository/` or in `copier.yml`, and keep the cases of `tests/test-repository-template.sh` passing.
9. Keep the names of the jobs that a ruleset requires, such as `PR title / Semantic PR title` and `K8s`.
10. Write the pull request title and each commit subject that lands on `main` as a Conventional Commit. release-please reads their types for the next release version (README.md, "Releases"). A change of a workflow input or a template question that a caller must follow is a breaking change.
11. Use `devops gh` and `devops pr`, never bare `gh`. Only a person merges pull requests.

## Where to look

| When you | Read |
| --- | --- |
| Start a task or look up a rule | [README.md](./README.md) |
| Call or change a reusable workflow | [README.md](./README.md), "Call the reusable workflows" |
| Change the repository template | [templates/README.md](./templates/README.md) |
| Make a release or choose a commit type | [README.md](./README.md), "Releases" |
| Run a check | [README.md](./README.md), "Checks" |
| Plan an item as an OpenSpec change | [openspec/config.yaml](./openspec/config.yaml), [openspec/specs/](./openspec/specs/) |

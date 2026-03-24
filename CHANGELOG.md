## v0.11.0 (2026-03-24)

### Feat

- **repo_template**: tweaked template to centralise config variables

## v0.10.1 (2026-03-24)

### Feat

- **sync-to-public**: default behaviour false, with override

## v0.10.0 (2026-03-23)

### Feat

- **README.md**: split post-release triggers
- **README.md**: added header and footger
- **README.md**: reorganised
- **README.md**: tweaked develop/release layout
- **README.md**: tweaked legend
- **README.md**: tweaked descriptions
- **README.md**: removed merge from legend
- **README.md**: added colouring
- **README.md**: lifecycle adjust
- **repo_template/orchestrator.yaml**: tweaked naming

### Fix

- **README.md**: layout
- **README.md**: layout
- **README.md**: layout -reverted separate develop box
- **README.md**: fixed layout horizontally
- **README.md**: fixed legend
- **README.md**: fixed legend
- **README.md**: fixed legend
- **README.md**: fixed legend colouring
- **README.md**: fixed punctuation parsing
- **README.md**: fixed {
- **README.md**: fix attempt for lifecycle
- **README.md**: fixed development lifecycle

### Refactor

- **minor**: tweaked comments and version check python version to 3.13

## v0.9.2 (2026-03-23)

### Fix

- **check-version**: pip installed packaging

## v0.9.1 (2026-03-23)

## v0.9.0 (2026-03-23)

### Feat

- **publish-to-pypi**: switched off by default

### Fix

- **orchestrator**: fix to internal/external entries

### Refactor

- **CI/CD**: refactored to harden some flows, switch PYPI_PUBLISH to false by default, and sort naming clarity

## v0.8.3 (2026-03-23)

### Fix

- **development**: force both workflows repos to use own orchestrators

## v0.8.2 (2026-03-23)

### Fix

- **sync-to-public2**: new fix attempt

## v0.8.1 (2026-03-23)

### Fix

- **sync-to-public**: attempt override push

## v0.8.0 (2026-03-23)

### Feat

- **review**: reviewd inc docs
- **.gitignore**: kept all *.yaml in template workflows

### Refactor

- **workflows**: refactored to remove repeat calls to config.yaml

## v0.7.0 (2026-03-23)

### Feat

- **back-sync-release**: prevent running of tests

### Fix

- **back-sync-release-to-main**: admin bypasses merge

## v0.6.0 (2026-03-23)

### Fix

- **public-release**: entered correct private/public repos

## v0.5.0 (2026-03-23)

### Feat

- **sync-from-public**: added for downstream templating

## v0.4.0 (2026-03-23)

### Fix

- **post-release-private**: fixed triggering of back sync

## v0.3.0 (2026-03-23)

### Feat

- **repo_template**: added ci-orchestrator.yaml to git keep

## v0.2.0 (2026-03-23)

### Feat

- **cleanup**: cleaned docs and cicd
- **template**: simplification
- **templates**: cleaned templates, removing unnecessary elements
- **templates**: tweaked
- **initial**: setup workflows

### Fix

- **build-and-test**: added pip for smoke testing
- **build-and-tes**: fixed reference to publish-on-release
- **workflows**: preventing workflows from triggering both self and main

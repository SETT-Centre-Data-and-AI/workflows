<p align="center">
  <img src="docs/images/workflows.png" alt="DAIR CI/CD Workflows" width="300">
</p>

# DAIR CI/CD Workflows

Centralised reusable GitHub Actions workflows for DAIR repositories.

This package is the CI/CD control layer for private development, public release, and downstream reuse.

## What This Package Does

- Applies consistent CI/CD checks across repositories.
- Enforces release-source and version rules.
- Automates private to public promotion.
- Supports stable downstream consumption and live internal development.

## How It Is Used

### Downstream repositories use stable release workflows

Downstream repositories call:

- `SETT-Centre-Data-and-AI/workflows/.github/workflows/central-orchestrator.yaml@release`

This gives stable, tested behaviour.

Setup guide: [Usage in Repos](repo_template/.github/workflows/README.md).

### Internal workflows repositories use local branch workflows

`workflows` and `workflows_development` call:

- `./.github/workflows/central-orchestrator.yaml`

This means workflow changes are tested directly from the current branch.


## Routing Flow

1. Caller workflow sends event context and repository inputs.
2. `central-orchestrator.yaml` resolves defaults and overrides through `config.yaml`.
3. Route conditions are evaluated from event, repo, base branch, and head branch.
4. Only required workflows run.

## Trigger Summary

### PR Opened/Synchronised
 - **Private: any -> `main`:** Runs `build-and-test.yaml` to run smoke tests and testing matrix
 - **Private/Public: `main/incoming_from_private` -> `release`:** Runs `ensure-release-source.yaml` and `pre-release-version-check.yaml` to ensure PR comes from `main` and version has been bumped

### PR Merged
 - **Private: `main` -> `release`:** Runs `back-sync-release-to-main.yaml` and `sync-to-public.yaml` to commit the release back to main (private), and sync to the public repo.
 - **Public: `incoming_from_private` -> `release`:** Runs `publish-to-pypi.yaml` when `publish-on-release` is enabled.

### Manual Dispatch
- **Sync from Public Repo**: pulls a public branch into the private repo
- **Publish to PyPI**: publishes to PyPI

## Key Workflows

- [central-orchestrator.yaml](.github/workflows/central-orchestrator.yaml)
- [self-orchestrator.yaml](.github/workflows/self-orchestrator.yaml)
- [config.yaml](.github/workflows/config.yaml)
- [build-and-test.yaml](.github/workflows/build-and-test.yaml)
- [ensure-release-source.yaml](.github/workflows/ensure-release-source.yaml)
- [pre-release-version-check.yaml](.github/workflows/pre-release-version-check.yaml)
- [back-sync-release-to-main.yaml](.github/workflows/back-sync-release-to-main.yaml)
- [sync-to-public.yaml](.github/workflows/sync-to-public.yaml)
- [sync-from-public.yaml](.github/workflows/sync-from-public.yaml)
- [publish-to-pypi.yaml](.github/workflows/publish-to-pypi.yaml)

## Architecture

```mermaid
flowchart TD
    A[Downstream repository] -->|calls @release| D[central-orchestrator.yaml]
    C[workflows or workflows_development] -->|calls local workflow| D
    D --> E[config.yaml]
    E --> F[Resolved config]
    F --> G[Checks and routing]
    G --> H[build-and-test]
    G --> I[ensure-release-source]
    G --> J[pre-release-version-check]
    G --> K[back-sync-release-to-main]
    G --> L[sync-to-public]
    G --> M[publish-to-pypi]
```

## Development Lifecycle

```mermaid
flowchart TB

    subgraph LEGEND[Legend]
    direction TB
        L_S[Source Branch]
        L_O(PR opened Workflow)
        L_R{Review: n reviewers}
        L_T[Target Branch]
        L_P(PR Closed Workflow)
        L_S --> L_O --> L_R --> L_T --> L_P
    end

    subgraph PRIVATE[Private]
    direction TB
        P_MAIN[main]
        P_DEV[any dev branch]
        P_WF_BUILD(build-and-test)
        P_REV_MAIN{Review: 1}
        P_WF_REL(ensure-release-source pre-release-version-check)
        P_REV_REL{Review: 1}
        P_REL[release]
        P_WF_BACK(back-sync-release-to-main)
        P_WF_SYNC(sync-to-public)
    end

    subgraph PUBLIC[Public]
    direction LR
        U_IN[incoming_from_private]
        U_REV{Review: 1}
        U_REL[release]
        U_WF_PUB(publish-to-pypi)
    end

    P_MAIN -->|Branch: any| P_DEV
    P_DEV -.->|PR Opened: any to main| P_WF_BUILD
    P_WF_BUILD -.-> P_REV_MAIN
    P_REV_MAIN -->|PR Merged: any to main| P_MAIN

    P_MAIN -.->|PR Opened: main to release| P_WF_REL
    P_WF_REL -.-> P_REV_REL
    P_REV_REL -->|PR Squashed: main to release| P_REL

    P_REL -.->|Post-merge trigger| P_WF_BACK
    P_REL -.->|Post-merge trigger| P_WF_SYNC
    P_WF_BACK -.->|Auto back sync release to main| P_MAIN
    P_WF_SYNC -.->|Sync release to incoming_from_private| U_IN

    U_IN -.->|PR Opened: incoming_from_private to release| U_REV
    U_REV -->|PR Merged incoming_from_private to release| U_REL
    U_REL -.->|Post-merge trigger| U_WF_PUB

    classDef branchNode fill:#ffe3e3,stroke:#c01c28,color:#7a0010,stroke-width:2px;
    classDef workflowNode fill:#e6f4ff,stroke:#175cd3,color:#0b3b91,stroke-width:2px;
    classDef reviewNode fill:#fff4cc,stroke:#b54708,color:#7a2e0e,stroke-width:2px;
    classDef markerNode fill:#f5f5f5,stroke:#667085,color:#1f2937;

    class P_MAIN,P_REL,P_DEV,U_REL,U_IN,L_S,L_T branchNode;
    class P_WF_BUILD,P_WF_REL,P_WF_BACK,P_WF_SYNC,U_WF_PUB,L_O,L_P workflowNode;
    class P_REV_MAIN,P_REV_REL,U_REV,L_R reviewNode;
```

## Licence

This work is licensed under [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/).

## Authors

DAIR Workflows was developed by Cai Davis at University Hospital Southampton NHS Foundation Trust's Data and AI Research Unit (DAIR), part of the Southampton Emerging Therapies and Technology Centre.

<p align="center">
  <a href="https://github.com/SETT-Centre-Data-and-AI">
    <img src="docs/images/SETT Header.png" alt="NHS UHS SETT Centre">
  </a>
</p>

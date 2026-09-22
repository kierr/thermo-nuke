# thermo-nuke

Extremely strict code quality reviews for Claude Code. Not a linter; a structural critic.

Catches the things linters can't: files crossing 1k lines, spaghetti branching, missed simplification opportunities ("code judo"), unnecessary abstractions, boundary leaks, and canonical helper duplication. The approval bar is intentionally high. No rubber-stamping "it works" implementations.

## Installation

```bash
claude plugin add thermo-nuke
```

Or install from source:

```bash
claude plugin add https://github.com/kierr/thermo-nuke
```

## Quick Start

### Review your current changes

```
/thermo-nuke:code-review
```

Good for small scopes: a few files, recent commits, or working tree changes.

### Full branch or PR review

```
claude --agent thermo-nuke:orchestrator
```

Or from within a session:

```
@thermo-nuke:orchestrator
```

The orchestrator assesses scope, slices large diffs into domain-cohesive groups, spawns parallel reviewers, and synthesizes findings into a consolidated report.

### Review a specific file or directory

```
@thermo-nuke:reviewer review app/models/person/
```

### Review a plan before coding

```
@thermo-nuke:plan-reviewer .planning/phases/42/PLAN.md
```

Catches structural problems when they're cheapest to fix.

## Components

| Component | Type | What it does |
|---|---|---|
| `/thermo-nuke:code-review` | Skill | The review rubric. Invoke directly for a quick review. |
| `thermo-nuke:orchestrator` | Agent | Coordinates full reviews: scope assessment, slicing, parallel reviewer dispatch, finding synthesis. |
| `thermo-nuke:reviewer` | Agent | Deep review of a specific scope or domain slice against the rubric. |
| `thermo-nuke:slice-planner` | Agent | Partitioning of large diffs into domain slices for parallel review. |
| `thermo-nuke:plan-reviewer` | Agent | Structural review of implementation plans before code is written. |

## How It Works

### Small diffs (< 30 files, < 2000 lines)

The orchestrator spawns a single reviewer agent with the full scope.

### Large diffs

1. **Assess**: determine scope, file count, and total lines changed
2. **Slice**: the slice-planner groups files into domain-cohesive slices sized for parallel review
3. **Gap check**: verify every file in the diff is covered by a slice; the planner creates gap-fill slices for uncovered files or cross-cutting dimensions
4. **Review**: parallel reviewer agents (one per slice, max 10 concurrent)
5. **Synthesize**: findings merged by root-cause clustering, coverage dimensions verified, consolidated report written
6. **Report**: findings presented by priority with an approval verdict

### Eight coverage dimensions

1. **Application code quality**: structure, abstractions, layering
2. **Security**: injection, PII flow, auth boundaries, credential handling
3. **Dependencies**: lockfile changes, version conflicts
4. **Migrations**: sequencing, rollback safety, model-code coupling
5. **Data contracts**: YAML/DB/seed/API-output schema consistency, enum validation, contract cross-checks
6. **CI/CD**: workflow correctness, enforcement gates
7. **Infrastructure**: config files, build system, secrets, unsafe defaults
8. **Documentation drift**: comments match code, ADRs match implementation

If any dimension is present in the diff but no reviewer confirmed checking it, a follow-up reviewer is spawned automatically.

## Output

Findings are organized by priority (must stay in sync with `skills/code-review/SKILL.md`):

1. Structural code-quality regressions
2. Missed opportunities for dramatic simplification / code-judo restructuring
3. Spaghetti / branching complexity increases
4. Boundary / abstraction / type-contract problems that make the code harder to reason about
5. File-size and decomposition concerns
6. Modularity and abstraction issues
7. Legibility and maintainability concerns

## Pre-push Hook

The repo includes a pre-push hook that requires a version bump for every push to main:

```bash
# Install the hook
ln -sf ../../scripts/pre-push .git/hooks/pre-push
```

The hook validates that the version in `.claude-plugin/plugin.json` has increased (not just changed) compared to the remote. It only gates pushes to `main` — feature branches are unrestricted.

## Development

This is a Claude Code plugin. The structure:

```
agents/              # Agent definitions (orchestrator, reviewer, slice-planner, plan-reviewer)
skills/              # Skill definitions (code-review rubric, plan-review rubric, help guide)
scripts/             # Git hooks and tooling
.claude-plugin/      # Plugin manifest
```

## License

MIT. See [LICENSE](LICENSE). The review rubric is adapted from [shaneholloman/cursor-plugins](https://github.com/shaneholloman/cursor-plugins) (MIT). See [NOTICE](NOTICE) for details.

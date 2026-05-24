---
name: help
description: How to use the thermo-nuke plugin. Explains available agents, skills, invocation modes, and when to choose which.
disable-model-invocation: true
---

# Thermo-Nuke Plugin Guide

## What It Does

Extremely strict code quality reviews focused on structure, maintainability, and design quality — not just bugs. The rubric catches: files crossing 1k lines, spaghetti branching, missed code-judo simplifications, unnecessary abstractions, boundary leaks, and canonical helper duplication.

## Components

| Component | Type | Purpose |
|---|---|---|
| `/thermo-nuke:code-review` | Skill | The review rubric itself. Preloaded into agents. Can be invoked directly for a quick code review. |
| `thermo-nuke:orchestrator` | Agent | Coordinates full reviews: assesses scope, slices large diffs, spawns parallel reviewers, synthesizes findings. |
| `thermo-nuke:reviewer` | Agent | Reviews a specific scope or domain slice using the thermo-nuclear rubric. |
| `thermo-nuke:slice-planner` | Agent | Analyzes a large diff and groups files into domain-cohesive slices for parallel review. |
| `thermo-nuke:plan-reviewer` | Agent | Reviews an implementation PLAN.md before code is written. Catches structural problems when cheapest to fix. |

## When to Use What

### Quick review of current changes
```
/thermo-nuke:code-review
```
Good for small scopes — a few files, recent commits, or working tree changes.

### Full branch/PR review
```
claude --agent thermo-nuke:orchestrator
```
Or just say: "run a thermo-nuclear review on this branch"

The orchestrator:
1. Assesses the diff size
2. Small scope → spawns a single reviewer
3. Large scope → slices into domains, spawns parallel reviewers, synthesizes findings

### Review a specific file or directory
```
@thermo-nuke:reviewer review app/models/person/
```
Or: "use thermo-nuke to review app/models/person/"

### Review a plan before coding
```
@thermo-nuke:plan-reviewer .planning/phases/42/PLAN.md
```
Or: "thermo-nuke review the plan for phase 42"

## Invocation Modes

| Mode | How | Best For |
|---|---|---|
| **Skill** | `/thermo-nuke:code-review` | Quick inline review in current session |
| **Main-thread agent** | `claude --agent thermo-nuke:orchestrator` | Full dedicated review session |
| **@-mention** | `@thermo-nuke:orchestrator` | Delegate from current session |
| **Natural language** | "run a thermo-nuclear review" | Claude auto-delegates to the orchestrator |

## Output

Findings organized by priority:
1. Structural code-quality regressions
2. Missed code-judo simplifications
3. Spaghetti / branching complexity
4. Boundary / abstraction / type-contract problems
5. File-size and decomposition concerns
6. Modularity and abstraction issues
7. Legibility and maintainability concerns

The approval bar is intentionally high — no rubber-stamping "it works" implementations.

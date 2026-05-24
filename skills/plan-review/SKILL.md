---
name: plan-review
description: "Thermo-nuclear review for implementation plans. Apply the code quality rubric to a PLAN.md before code is written. Use for reviewing plans, phase plans, or proposed implementations to catch structural problems early."
---

# Thermo-Nuke Plan Review

Apply the thermo-nuclear code quality rubric to an implementation plan — before code is written, when fixes are cheapest.

## Input

`$ARGUMENTS` specifies the plan to review:
- A file path (e.g. `.planning/phases/42/PLAN.md`)
- "current phase" — find the active plan in `.planning/phases/`
- Empty — look for `PLAN.md` in `.planning/` or the current directory

## Review Process

### Step 1: Read the Plan

Read the plan file. Extract:
- Proposed tasks and their file changes
- Dependencies between tasks
- Stated success criteria

### Step 2: Assess Against the Codebase

For each proposed task, check the current state of the files it would modify:

```bash
# Will any file cross 1k lines?
wc -l <proposed files>
```

Read the files that would be modified to understand current structure.

### Step 3: Apply the Rubric (Plan Adaptation)

Map each code-review concern to its plan equivalent:

| Code Review Concern | Plan Review Question |
|---|---|
| File crossing 1k lines | Will the proposed changes push any file past ~1k lines? If so, does the plan include decomposition? |
| Spaghetti / ad-hoc branching | Does the plan propose adding conditionals scattered across unrelated flows? Can the logic be centralized? |
| Code-judo / missed simplification | Is there a simpler plan that achieves the same goal? Does the plan introduce complexity a reframing could eliminate? |
| Unnecessary abstraction / wrappers | Does the plan propose wrappers, pass-through helpers, or indirection that doesn't earn its keep? |
| Boundary leaks | Does the plan put feature logic in shared paths? Logic in the wrong layer/module? |
| Canonical helper duplication | Does the plan propose new helpers when existing ones already do the job? |
| Type / boundary cleanliness | Does the plan introduce unclear boundaries, casts, or optionality that obscures the real invariant? |
| Sequential when parallel is possible | Are independent tasks serialized? Can the plan run more in parallel? |

### Step 4: Check Plan Quality

- **Task atomicity** — Can each task be verified independently? Or do tasks leave state half-applied?
- **Dependency correctness** — Are stated dependencies real? Are missing dependencies that should exist?
- **Success criteria** — Measurable? Or purely subjective with no deliverable?
- **Missing concerns** — Does the plan ignore async pipeline effects, search/index impact, or schema change safety?

## Output

Report findings in priority order:

1. **Structural plan problems** — plans that would produce spaghetti, file sprawl, or boundary leaks
2. **Missed code-judo** — simpler plans that achieve the same goal with less complexity
3. **Plan quality issues** — missing dependencies, unmeasurable success criteria, incomplete coverage
4. **Implementation risks** — plans that would break async pipelines, search indexes, or schema constraints

For each finding:
- **What:** the plan section and the concern
- **Why it matters:** what goes wrong if implemented as planned
- **Suggestion:** specific alternative approach or decomposition

## Tone

Same as the thermo-nuclear code review: direct, serious, demanding about quality. No rubber-stamping. If the plan would produce structural problems, say so clearly.

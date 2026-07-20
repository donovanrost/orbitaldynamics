# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner prior result-artifact filter routing regression repair.

Status:
Completed and verified.

Selected boundary:
Correct the argument order in the prior-plan result-artifact callbacks owned by
`ResourceFilterSourceReports` and `ContactFilterSourceReports`. Preserve both
public report collectors and all branch/artifact contracts.

Selection evidence:
- `BranchRefreshSourceInputs.result_artifact_embedded_reports/3` expects
  `(container, source_prefix, report_keys)`.
- Both prior-plan callbacks currently pass `(prior_plan, report_keys,
  "prior_plan")`; their mission-state counterparts use the correct order.
- The bug suppresses exactly the missing prior result-artifact resource-filter
  and contact-filter branches seen in three broad-suite failures.

Implementation:
Selected in `1d202538` and implemented in `340d966a`. Corrected both
prior-plan callbacks to pass `(prior_plan, "prior_plan", report_keys)` to
`result_artifact_embedded_reports/3`. Public collectors and emitted source paths
remain unchanged; embedded filter reports are no longer silently omitted.

Verification:
- All resource/contact-filter source and pressure tests passed with warnings as
  errors: 19 tests.
- The three broad-suite failures caused by missing derived filter branches are
  reproduced as passing in the focused set.
- Strict forced compile passed with warnings as errors: 4,129 files.
- Touched-file format and `git diff --check` passed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Campaign-planner prior result-artifact filter routing repair, selected in
`1d202538` and implemented in `340d966a`. Correct argument ordering restored
three missing-branch tests.

Next candidate:
Resolve the remaining refresh-budget replay-summary and readiness score-term
failures exposed by broad verification.

Blocked:
No.

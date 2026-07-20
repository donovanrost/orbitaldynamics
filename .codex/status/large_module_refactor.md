# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner prior result-artifact filter routing regression repair.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Schema contact-allocation report contract test split, selected in `7d687947`
and implemented in `bb5bec17`. The 1,746-line mixed module became a 982-line
summary/capability module and a 775-line full-report module.

Next candidate:
Implement and verify the filter-routing repair, then resolve the remaining
refresh-budget and readiness score-term failures.

Blocked:
No.

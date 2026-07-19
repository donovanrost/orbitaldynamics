# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation resource-evidence extraction.

Status:
Completed and pushed in `8875bd76`.

Selected boundary:
Extract reconciled resource margins, battery telemetry, spacecraft/payload/
antenna availability, degradation and mode state, and incompatible/suppressed
activity types into
`OrbitalDynamics.TimelineFeedback.ReconciliationResourceEvidence`. Preserve
the existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,220 lines, behind Timeline
  and MissionPlan.Activity but ahead of the remaining Manifest facade.
- The selected reconciliation-row fields form one planned-versus-realized
  spacecraft resource-state evidence responsibility and depend only on the
  planned and realized row maps.
- Identity, observation and communications evidence, throughput, timing,
  success outcomes, station-calendar evidence, execution uncertainty,
  operational-feedback exclusion, and report aggregation remain with their
  current owners.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,896
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, Cadence import, and contact-feedback contract
  coverage passed: 79 tests.
- Exact public old/new comparison against selection commit `d44a89d6` passed
  for five reports covering matched, mismatched, planned-only, realized-only,
  and mixed rows with divergent valid resource-state evidence.
- `mix xref callers` reports only the TimelineFeedback facade as a runtime
  caller of the extracted owner.
- Static ownership checks confirm the reconciliation implementations live in
  the dedicated owner while the facade retains its separate resource
  normalization and operational-feedback consumers.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation resource-evidence extraction, selected in
`d44a89d6` and implemented in `8875bd76`.
`timeline_feedback.ex` moved from 4,220 to 4,180 lines; the dedicated owner is
69 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

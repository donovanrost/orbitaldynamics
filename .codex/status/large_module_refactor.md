# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback success-factor reconciliation ownership extraction.

Status:
Completed and pushed in `cfb4be1d`.

Selected boundary:
Move reconciled contact, command, observation, and maneuver factor/source
projection plus feedback sample weight/source selection into the existing
`OrbitalDynamics.TimelineFeedback.SuccessFactor` owner. Preserve the existing
report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,950 lines, ahead of
  Manifest and ContactAllocation and behind the three larger
  orchestration-heavy facades.
- The selected fields and helpers form one planned-versus-realized
  success-factor evidence responsibility.
- Success-factor normalization already lives in the selected owner; this
  extension completes its reconciliation projection without a parallel module.
- Outcome projection, maneuver comparison, timing, throughput, identity, and
  operational-feedback aggregation remain separate.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,903
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, Cadence import, and contact-feedback contract
  coverage passed: 79 tests.
- Exact public old/new comparison against selection commit `c3205948` passed
  for five reports with divergent factor values, sources, and feedback weights.
- `mix xref callers` reports only the TimelineFeedback facade as a runtime
  caller of the SuccessFactor owner.
- Static ownership checks confirm factor reconciliation lives in SuccessFactor
  while normalization and operational aggregation retain their current owners.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback success-factor reconciliation ownership extraction, selected
in `c3205948` and implemented in `cfb4be1d`.
`timeline_feedback.ex` moved from 3,950 to 3,917 lines; the SuccessFactor owner
moved from 261 to 300 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

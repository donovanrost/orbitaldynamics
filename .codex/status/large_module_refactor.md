# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner readiness score-term regression diagnosis.

Status:
Refresh-budget repair implemented and verified; next regression pending selection.

Selected boundary:
Diagnose the remaining goal-era readiness-row-context failure before selecting
the narrowest production or expectation repair.

Selection evidence:
- The focused five-file regression gate now has only the readiness score-term
  failure plus the baseline golden-artifact drift.
- The readiness test expects a generic risk penalty of `-200`; current output is
  `-100`. Branch risk-indicator composition must be inspected before changing
  either implementation or test arithmetic.

Implementation:
`ee7ca527` normalizes only empty-map refresh-budget candidate-ID collections to
empty lists at the replay-summary boundary.

Verification:
- 15 focused refresh-budget and campaign-planner tests passed with warnings as
  errors.
- Strict compilation passed for 4,129 files.
- Formatting and diff checks passed.

Behavior/schema changes:
Empty candidate-ID collections again retain their array contract, eliminating
false budget, dropped-candidate, and candidate-limit pressure. Non-empty values,
counts, public APIs, and schemas are unchanged.

Last completed slice:
Candidate-refresh empty refresh-budget ID normalization repair, selected in
`ef64d969` and implemented in `ee7ca527`.

Next candidate:
Diagnose and resolve the final readiness score-term failure, then rerun the
five-file regression gate and broad suite.

Blocked:
No.

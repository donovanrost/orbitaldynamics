# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-rejection owner completion.

Status:
Complete and pushed.

Selected boundary:
Add `CandidateRejectionValidation.validate_report_artifact/3`, reusing its
existing `PlanChangeRegistryContracts` requirements and model-limit default.
Route the direct `candidate_rejection_report.v1` `Schema` clause through the
owner and preserve every existing owner API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,741 lines; the other
  targeted public facades are now 164 to 524 lines.
- The direct clause repeats required-field setup before delegating to
  `CandidateRejectionValidation`.
- The owner already resolves the same registry requirements and model limits
  for optional report validation.
- No route needs recursive `Schema` lookup.

Implementation:
Added `CandidateRejectionValidation.validate_report_artifact/3`, which owns
registry-backed required-field validation before the existing report validator.
Routed the direct `candidate_rejection_report.v1` `Schema` clause through that
owner. `schema.ex` moved from 4,741 to 4,739 lines; the focused owner moved from
60 to 66 lines.

Verification:
- Strict focused baseline: 13 tests passed.
- Focused plus adjacent candidate-rejection, refresh, planner, export, and
  fixture coverage: 27 tests passed.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,086 files successfully.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `CandidateRejectionValidation` APIs, validation results, and
checked-in exports remain unchanged.

Last completed slice:
Schema candidate-rejection owner completion, selected in `ab9be7ad` and
implemented in `c86ebe51`. `schema.ex` moved from 4,741 to 4,739 lines.

Next candidate:
Re-rank the remaining direct `Schema` validation clauses, prioritizing a
cohesive owner that can absorb facade-owned required-field setup without
recursive `Schema` lookup or public API changes.

Blocked:
No.

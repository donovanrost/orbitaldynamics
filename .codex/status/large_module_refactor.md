# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-rejection owner completion.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `CandidateRejectionValidation` APIs, validation results, and
checked-in exports must remain unchanged.

Last completed slice:
Schema maneuver decision-support owner routing extraction, selected in
`fa4dad79` and implemented in `89ccd78e`.
`schema.ex` moved from 4,745 to 4,741 lines.

Next candidate:
Implement and verify the selected candidate-rejection owner completion, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.

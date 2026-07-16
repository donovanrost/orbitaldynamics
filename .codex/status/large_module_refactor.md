# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh operational-timeline context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract the complete operational-timeline source-report validator, including
input keys, feedback/integrity counts, and its private count-map helper, behind
the existing public context function.

Why this slice:
The public validator and `validate_operational_timeline_count_maps/3` form one
self-contained responsibility with dedicated replay, candidate-source,
feedback, review, and import coverage.

Public facade to preserve:
`CandidateRefreshReportContracts.validate_operational_timeline_context/4`,
including its callback-list guard, plus all other public signatures.

Likely extraction target:
`CandidateRefreshOperationalTimelineContracts.validate/3`, owning the complete
flow and count-map field list.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_operational_timeline_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- operational-timeline replay/candidate-source/feedback/review-import tests
- candidate-refresh resource-provenance and schema contract coverage
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
The public `/4` function is a thin delegate, the private count-map helper moves
with its only owner, field/order/path behavior is unchanged, and focused/broader
checks pass.

Verification gaps:
- Full repository suite not run.

Last commit:
Published timeline-publication extraction `5af308fe`.

Blocked:
No.

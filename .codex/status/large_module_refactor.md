# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh timeline structural-validation context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract timeline activity-precondition, timeline-integrity, and
timeline-dependency-impact source-report validators behind their existing
public context functions.

Why this slice:
These three contexts form the dependency/exclusivity validation family and use
the same non-negative integer and typed count-map validation flow. Together they
are a cohesive responsibility; timeline publication remains separate.

Public facade to preserve:
All `CandidateRefreshReportContracts` public signatures, especially the three
selected `/4` functions and their callback-list guards.

Likely extraction target:
`CandidateRefreshTimelineValidationContracts`, owning the three complete
context flows and their shared field/count-map reducers.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_timeline_validation_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline precondition, integrity, and dependency-impact replay tests
- candidate-refresh resource-provenance and schema contract coverage
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
The three public functions are thin delegates to one focused structural-
validation owner, no field/order/error behavior changes, no stale helpers or
imports remain, and focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last commit:
Published timeline lifecycle extraction `a681760b`.

Blocked:
No.

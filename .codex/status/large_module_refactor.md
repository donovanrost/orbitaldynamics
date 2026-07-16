# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh timeline-activity context extraction.

Status:
Selected; implementation pending.

Selected slice:
Move the generic timeline-activity input validator into the existing timeline-
validation owner behind its public context function.

Why this slice:
The invalid-activity counter, reason map, and reason list are timeline structural
validation concerns. `CandidateRefreshTimelineValidationContracts` already owns
the related activity-precondition, integrity, and dependency-impact flows and
imports the exact primitives needed, so no new module or helper is required.

Public facade to preserve:
`validate_timeline_activity_context/4`, including its callback-list guard,
argument order, validation order, paths, messages, and all other public
signatures.

Likely extraction target:
`CandidateRefreshTimelineValidationContracts.validate_activity/3`.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_timeline_validation_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- focused timeline-activity state/precondition replay tests
- candidate-refresh schema/provenance contracts
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
The public `/4` context is a thin delegate with its guard unchanged, the complete
three-field timeline-activity flow moves without duplication, validation order/
paths/errors remain exact, and focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Review-feedback context extraction published as `ed0fbe29`: a 60-line owner
reduced the report-contract facade from 436 to 396 lines; 41 focused, 755
candidate-refresh, and 22 export tests passed; checked-in schemas and fingerprint
were unchanged; bounded review found no issues.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh timeline-activity context extraction.

Status:
Complete; publication pending.

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

Extraction target:
`CandidateRefreshTimelineValidationContracts.validate_activity/3`.

Files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_timeline_validation_contracts.ex`
- `.codex/status/large_module_refactor.md`

Result:
The public `/4` facade delegates to a new 14-line entry point in the existing
timeline-validation owner. The report-contract facade fell from 396 to 386
lines without schema-export changes.

Verification:
- compile with warnings as errors passed
- seven focused timeline-activity files plus candidate-refresh schema and
  resource-provenance contracts: 47 passed
- broader candidate-refresh suite: 755 passed
- schema export trio: 22 passed
- full schema export reproduced checked-in artifacts with no diff
- deterministic contract/bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- compile-connected xref roots stayed narrow; format and diff hygiene passed
- bounded read-only review found no issues and independently passed compile,
  the 47 focused tests, facade/API comparison, xref, format, and diff checks

Verification gaps:
- Full repository suite not run.

Last commit:
Published review-feedback extraction `ed0fbe29`; selected this slice in
`34f4ea79`.

Blocked:
No.

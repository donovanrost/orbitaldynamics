# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh review-feedback context extraction.

Status:
Complete; publication pending.

Selected slice:
Extract the timeline-feedback and maneuver-review source-report validators with
their shared optional count-map helper behind the existing public contexts.

Why this slice:
Both flows validate review input keys followed by explicitly typed feedback/
action count maps. `validate_optional_count_maps/4` is now exclusive to these
two contexts, which have six focused replay/build suites plus direct provenance
error-path coverage.

Public facade to preserve:
`validate_timeline_feedback_context/4` and
`validate_maneuver_review_context/4`, including callback-list guards, argument
order, validation order, paths, messages, and all other public signatures.

Extraction target:
`CandidateRefreshReviewFeedbackContracts`, with timeline-feedback and
maneuver-review entry points plus the private optional count-map helper.

Files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_review_feedback_contracts.ex`
- `.codex/status/large_module_refactor.md`

Result:
Both public `/4` facades delegate to a 60-line review-feedback owner. The two
complete flows and exclusive typed optional-count-map helper moved, and the
report-contract facade fell from 436 to 396 lines without schema-export changes.

Verification:
- compile with warnings as errors passed
- six focused timeline-feedback/maneuver-review files plus candidate-refresh
  schema and resource-provenance contracts: 41 passed
- broader candidate-refresh suite: 755 passed
- schema export trio: 22 passed
- full schema export reproduced checked-in artifacts with no diff
- deterministic contract/bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- compile-connected xref roots stayed narrow; format and diff hygiene passed
- bounded read-only review found no issues and independently passed compile,
  the 41 focused tests, facade/API comparison, xref, format, and diff checks

Verification gaps:
- Full repository suite not run.

Last commit:
Published objective-gap extraction `b2bb447b`; selected this slice in
`f188fe58`.

Blocked:
No.

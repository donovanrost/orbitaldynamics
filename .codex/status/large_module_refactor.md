# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh review-feedback context extraction.

Status:
Selected; implementation pending.

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

Likely extraction target:
`CandidateRefreshReviewFeedbackContracts`, with timeline-feedback and
maneuver-review entry points plus the private optional count-map helper.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_review_feedback_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- six timeline-feedback/maneuver-review replay and build files
- candidate-refresh schema/provenance contracts
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
Both public `/4` contexts are thin delegates with unchanged guards, both flows
and the exclusive helper move without duplication, validation order/paths/
errors remain exact, and focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Objective-gap context extraction published as `b2bb447b`: a 41-line owner
reduced the report-contract facade from 463 to 436 lines; 22 focused, 755
candidate-refresh, and 22 export tests passed; checked-in schemas and fingerprint
were unchanged; bounded review found no issues.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh timeline-publication context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract the complete timeline-publication source-report validator—count maps,
row counts, stable-ID lists, and stable-ID array maps—behind its existing public
context function.

Why this slice:
Timeline publication is a self-contained 75-line responsibility with dedicated
replay coverage and no callback or private-helper coupling.

Public facade to preserve:
`CandidateRefreshReportContracts.validate_timeline_publication_context/4`,
including its callback-list guard, plus all other public signatures.

Likely extraction target:
`CandidateRefreshTimelinePublicationContracts.validate/3`, owning the complete
publication flow and local field reducers.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_timeline_publication_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline-publication replay and candidate-source replay tests
- candidate-refresh resource-provenance and schema contract coverage
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
The public `/4` function is a thin delegate to one focused publication owner,
all field/order/path behavior is unchanged, no stale imports remain, and
focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last commit:
Published timeline structural-validation extraction `063e03fd`.

Blocked:
No.

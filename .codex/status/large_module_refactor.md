# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh timeline change-application context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract timeline-diff and timeline-transition-application source-report
validators behind their existing public context functions.

Why this slice:
Both contexts validate change application through ordered non-negative counters,
duplicate timeline identity evidence, and optional typed count maps. They form a
cohesive owner while timeline feedback and maneuver review remain separate.

Public facade to preserve:
`validate_timeline_diff_context/4` and
`validate_timeline_transition_application_context/4`, including their
callback-list guards, plus all other public signatures.

Likely extraction target:
`CandidateRefreshTimelineChangeContracts`, owning both complete validation
flows and local integer/count-map reducers.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_timeline_change_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline-diff and transition-application replay/candidate-source/build tests
- candidate-refresh resource-provenance and schema contract coverage
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
Both public `/4` functions are thin delegates, ordered field/error behavior is
unchanged, the parent retains its generic reducer for remaining families, and
focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last commit:
Published operational-timeline extraction `d6f1d30b`.

Blocked:
No.

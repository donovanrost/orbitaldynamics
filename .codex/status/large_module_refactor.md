# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh candidate-selection context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract the freshness and refresh-budget source-report validators behind their
existing public context functions.

Why this slice:
Freshness explains stale/unknown candidate eligibility and refresh budget
records the resulting kept/dropped candidate set. Together they form a cohesive
candidate-selection validation responsibility with focused replay/build tests.
Objective-gap demand validation remains out of scope.

Public facade to preserve:
`validate_freshness_context/4` and `validate_refresh_budget_context/4`, including
their callback-list guards, validation order, paths, messages, and all other
public signatures.

Likely extraction target:
`CandidateRefreshCandidateSelectionContracts`, with separate freshness and
refresh-budget entry points.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_candidate_selection_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- focused freshness and refresh-budget replay/build tests
- candidate-refresh schema/provenance contracts
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
Both public `/4` context functions are thin delegates with unchanged guards,
the complete freshness and refresh-budget flows move without duplication,
validation order/paths/errors remain exact, and focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Validation-safety-case extraction published as `f4789df9`: the facade fell from
535 to 504 lines and the validation-report owner grew from 84 to 121 lines; 11
focused, 755 candidate-refresh, and 22 export tests passed; checked-in schemas
and fingerprint were unchanged; deferred-callback review found no code issues.

Blocked:
No.

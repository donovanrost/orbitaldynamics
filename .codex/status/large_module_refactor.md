# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh candidate-rejection context extraction.

Status:
Selected; implementation pending.

Selected slice:
Move the candidate-rejection source-report validator into the existing
candidate-selection owner behind its public context function.

Why this slice:
Candidate rejection is a candidate-selection outcome beside freshness and
refresh budget. Its two count maps are the final family-specific body and sole
remaining caller of the facade's private direct count-map helper, with two
focused replay suites and direct provenance error-path coverage.

Public facade to preserve:
`validate_candidate_rejection_context/4`, including its callback-list guard,
argument order, validation order, paths, messages, and all other public APIs.

Likely extraction target:
`CandidateRefreshCandidateSelectionContracts.validate_candidate_rejection/3`.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_candidate_selection_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- two candidate-rejection replay summary files
- candidate-refresh schema/provenance contracts
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
The public `/4` context is a thin delegate with its guard unchanged, both map
validations move without duplication, the facade's private count-map helper is
removed, validation order/paths/errors remain exact, and all checks pass.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Communications-pressure extraction published as `923f946e`: a 71-line owner
reduced the report-contract facade from 364 to 337 lines and removed both stable-
ID imports; 116 focused, 755 candidate-refresh, and 22 export tests passed;
schemas/fingerprint were unchanged; bounded review found no issues.

Blocked:
No.

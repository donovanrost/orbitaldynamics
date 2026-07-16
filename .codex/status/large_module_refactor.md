# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh objective-gap context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract the complete objective-gap source-report validator behind its existing
public context function.

Why this slice:
The four gap counters and seven demand/routing count maps form one self-contained
objective-demand validation responsibility. The flow has a dedicated replay
suite and direct schema error-path coverage, with no callback or shared private
helper coupling.

Public facade to preserve:
`validate_objective_gap_context/4`, including its callback-list guard, argument
order, validation order, paths, messages, and all other public signatures.

Likely extraction target:
`CandidateRefreshObjectiveGapContracts.validate/3`.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_objective_gap_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- objective-gap replay summary tests
- candidate-refresh schema/provenance contracts
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
The public `/4` context is a thin delegate with its guard unchanged, the complete
objective-gap flow moves without duplication, validation order/paths/errors
remain exact, and focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Candidate-selection context extraction published as `3270171b`: a 63-line
owner reduced the report-contract facade from 504 to 463 lines; 42 focused, 755
candidate-refresh, and 22 export tests passed; checked-in schemas and fingerprint
were unchanged; bounded review found no issues.

Blocked:
No.

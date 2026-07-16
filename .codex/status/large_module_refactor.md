# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh provider-counteroffer context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract the complete provider-counteroffer source-report validator—scalar
counts/numbers, status maps, stable-ID routing maps/lists, and affected-ID
lists—behind its existing public context function.

Why this slice:
This is the largest remaining independent parent body at 99 lines, with a fully
ordered validation pipeline and dedicated replay, provenance, and standalone
contract coverage.

Public facade to preserve:
`CandidateRefreshReportContracts.validate_provider_counteroffer_context/4`,
including its callback-list guard, plus all other public signatures.

Likely extraction target:
`CandidateRefreshProviderCounterofferContracts.validate/3`, owning the complete
validation pipeline.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_provider_counteroffer_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- provider-counteroffer replay/source-provenance/standalone contract tests
- candidate-refresh resource-provenance and schema contract coverage
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
The public `/4` function is a thin delegate, all validation order/paths/errors
are unchanged, stale imports are removed only when unused, and focused/broader
checks pass.

Verification gaps:
- Full repository suite not run.

Last commit:
Published timeline change-application extraction `1fced6e0`.

Blocked:
No.

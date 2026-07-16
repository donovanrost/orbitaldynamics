# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh quality-gate context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract the complete quality-gate source-report validator—gate counts, typed
count maps, stable-ID routing maps/lists, status ID lists—and its sole optional
stable-ID array-map helper behind the existing public context function.

Why this slice:
The 80-line context is the only caller of the composite private helper and has
eight focused replay suites covering routing, pressure, unavailable-resource,
operational-summary, and import-readiness variants.

Public facade to preserve:
`CandidateRefreshReportContracts.validate_quality_gate_context/4`, including
its callback-list guard, plus all other public signatures.

Likely extraction target:
`CandidateRefreshQualityGateContracts.validate/3`, owning the complete flow and
optional stable-ID array-map helper.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_quality_gate_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- all quality-gate replay suites
- candidate-refresh resource-provenance and schema contract coverage
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
The public `/4` function is a thin delegate, its sole helper moves with it, all
field/order/path behavior is unchanged, stale imports are removed only when
unused, and focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last commit:
Published provider-counteroffer extraction `89fbc974`.

Blocked:
No.

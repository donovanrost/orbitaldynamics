# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh resource-signal context extraction.

Status:
Selected; implementation pending.

Selected slice:
Extract the link-capacity, constraint, resource-projection, and resource-filter
source-report validators behind their existing public context functions.

Why this slice:
These four flows validate the capacity, constraint, projected-pressure, and
filter evidence that drives branch-local resource decisions. They share the
same direct count-map pattern; resource filter adds its invalid input-ID list.
Communications contention/allocation/pressure contexts remain out of scope.

Public facade to preserve:
`validate_link_capacity_context/4`, `validate_constraint_context/4`,
`validate_resource_projection_context/4`, and
`validate_resource_filter_context/4`, including callback-list guards, argument
order, validation order, paths, messages, and all other public signatures.

Likely extraction target:
`CandidateRefreshResourceSignalContracts`, with four entry points and a private
direct count-map helper.

Likely files:
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_resource_signal_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- focused link-capacity, constraint, resource-projection, and resource-filter
  replay/build tests
- candidate-refresh schema/provenance contracts
- broader candidate-refresh, deterministic export/fingerprint, xref, and format

Definition of done:
All four public `/4` contexts are thin delegates with unchanged guards, their
complete flows move without duplication, validation order/paths/errors remain
exact, and focused/broader checks pass.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-activity context extraction published as `f3e73b46`: the existing
timeline-validation owner gained one 14-line entry point and the report-contract
facade fell from 396 to 386 lines; 47 focused, 755 candidate-refresh, and 22
export tests passed; schemas/fingerprint were unchanged; review found no issues.

Blocked:
No.

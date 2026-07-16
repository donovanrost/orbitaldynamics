# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: readiness/quality-gate handoff error ownership cleanup.

Status:
Completed and published.

Selected slice:
Let operational-readiness and quality-gate handoff matchers construct standard
schema errors through primitive support directly.

Why this slice:
Both one-entry callback bags route only `error/2`; exact source-match path and
message regressions already cover both handoff families.

Current coupling/problem:
Resolved. Both handoff matchers construct the standard schema error directly;
the facade only delegates their validation inputs.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Readiness/quality-gate source-pair order, paths, and exact mismatch errors.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_readiness_handoff_contracts.ex`
- `lib/orbital_dynamics/schema/quality_gate_handoff_contracts.ex`

Definition of done:
Both error-only callback bags and dynamic error wrappers are gone, exact/broad
tests and the fingerprint pass, and xref shows primitive support directly.

Behavior/schema changes:
None. Source-pair order, row gating, paths, messages, and deterministic schema
output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- 22 Cadence-import, operational/readiness, export, and exact readiness/quality
  stale-copy tests passed; 291 unrelated tests were excluded by line selectors.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows both handoff modules depend directly on primitive support; quality
  gate also retains its existing operational-readiness capability dependency.
- Formatting, `git diff --check`, and checked-in schema cleanliness passed.

Verification gaps:
- Full suite not run; exact stale-copy regressions, family/export tests, and the
  fingerprint are the verification boundary for this slice.

Last commit:
`b414bf06` (`Collapse readiness handoff error callbacks`).

Next candidate:
Assess resource-projection flow-summary equality ownership; keep mixed
activity-context ownership deferred.

Blocked:
No.

Notes:
- `schema.ex` is 14,548 lines after this slice (down from 14,564).
- `QualityGateHandoffContracts.validate_summary/4` retains its unrelated
  multi-operation callback interface.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.

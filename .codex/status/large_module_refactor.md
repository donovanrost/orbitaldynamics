# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: constraint-report callback and metadata ownership cleanup.

Status:
Completed and published.

Selected slice:
Move constraint-report model metadata into its contract-family module, move
generic non-negative integer checks into primitive support, and remove the
seventeen-callback facade bag.

Why this slice:
The contract module can own its three model definitions from the two constraint
capability sources; every remaining callback maps to existing support once the
generic integer check moves.

Current coupling/problem:
Resolved. Runtime validation and JSON export use family-owned model metadata;
the validator calls aggregation, collection, stable-ID, and primitive support
directly, while the facade only delegates artifacts.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/constraint_report_contracts.ex`
- `lib/orbital_dynamics/schema/primitive_validation.ex`

Definition of done:
Constraint-report metadata has one family-owned source, callback plumbing is
gone, focused runtime/export tests and fingerprint pass, and xref shows direct
support and constraint capability dependencies.

Behavior/schema changes:
None. Constraint models, model limits, derived counts/status, row validation,
paths/messages, and deterministic schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Fifteen constraint implementation, runtime validation, and export tests passed.
- Full checked-in schema export produced no diffs.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows direct constraint capability, aggregation, collection, primitive,
  and stable-ID dependencies.
- Formatting and `git diff --check` passed.

Verification gaps:
- Full suite not run; the focused fifteen-test constraint/export gate and
  deterministic fingerprint are the verification boundary for this slice.

Last commit:
`01139509` (`Collapse constraint report callbacks`).

Next candidate:
Collapse execution-report callback ownership; its status list is shared by
runtime/source-evidence validation and can become family-owned.

Blocked:
No.

Notes:
- `schema.ex` is 14,343 lines after this slice (down from 14,423).
- `ConstraintReportContracts` is 171 lines and callback-free.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.

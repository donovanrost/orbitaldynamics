# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: optimizer-contract callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Move generic list-count comparison and map-field stable-ID list validation into
support modules, then remove the optimizer contract's eight-callback facade bag.

Why this slice:
Both facade helpers are generic and already adjacent to their natural support
owners; all remaining callbacks map directly to primitive or stable-ID support.

Current coupling/problem:
Resolved. Generic list/count comparison is collection-support-owned, map-field
stable-ID lists are stable-ID-support-owned, primitive/stable-ID checks are
direct, and the facade only delegates artifacts.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/collection_validation.ex`
- `lib/orbital_dynamics/schema/optimizer_contract_contracts.ex`
- `lib/orbital_dynamics/schema/stable_id_validation.ex`

Definition of done:
Generic helpers are support-owned, optimizer callback plumbing is gone,
focused optimizer/runtime/export tests and fingerprint pass, and xref shows
direct collection/primitive/stable-ID support dependencies.

Behavior/schema changes:
None. Optimizer fields, selected/candidate/ranked IDs, derived counts,
cross-references, paths/messages, and deterministic schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Thirteen optimizer, schema, validation-fixture, and export tests passed.
- Full checked-in schema export produced no diffs.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and direct collection, primitive, and stable-ID
  support dependencies.
- Formatting and `git diff --check` passed.

Verification gaps:
- Full suite not run; the focused thirteen-test optimizer/export gate and
  deterministic fingerprint are the verification boundary for this slice.

Last commit:
`a6beafbf` (`Collapse optimizer contract callbacks`).

Next candidate:
Collapse capability-catalog callback ownership while keeping the facade-owned
contract registry explicit as data rather than hidden function callbacks.

Blocked:
No.

Notes:
- `schema.ex` is 14,234 lines after this slice (down from 14,277).
- `OptimizerContractContracts` is 86 lines and callback-free.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.

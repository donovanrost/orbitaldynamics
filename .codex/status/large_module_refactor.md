# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: capability-catalog callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Pass the facade-owned contract registry explicitly as data and replace the
capability catalog's eight-callback bag with direct registry/primitive support.

Why this slice:
The registry map is the only facade-owned state; names and membership already
belong to `Schema.Registry`, while all validation operations are primitive.

Current coupling/problem:
Resolved. The facade passes its registry map explicitly, the family validator
uses `Schema.Registry` and primitive support directly, and no callback plumbing
remains.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/capability_catalog_contracts.ex`

Definition of done:
The contract registry is an explicit input, callback plumbing is gone, focused
catalog/registry/export tests and fingerprint pass, and xref shows direct
registry/primitive dependencies.

Behavior/schema changes:
None. Catalog sections, executable-contract names/counts, registry membership,
paths/messages, and deterministic schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Eleven capability-catalog, registry, validation-fixture, and export tests passed.
- Full checked-in schema export produced no diffs.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and direct registry/primitive dependencies.
- Formatting and `git diff --check` passed.

Verification gaps:
- Full suite not run; the focused eleven-test catalog/export gate and
  deterministic fingerprint are the verification boundary for this slice.

Last commit:
`9e9d7c3f` (`Collapse capability catalog callbacks`).

Next candidate:
Collapse validation-diagnostic callback ownership; both issue and remediation
validators use only four primitive support operations.

Blocked:
No.

Notes:
- `schema.ex` is 14,219 lines after this slice (down from 14,234).
- `CapabilityCatalogContracts` is 110 lines and callback-free.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.

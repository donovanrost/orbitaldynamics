# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: optional schema-contract field callback cleanup.

Status:
Completed and published.

Selected slice:
Let `Schema.SchemaContractField` call primitive equality validation directly.

Why this slice:
Its only callback already points to primitive support, and its optional-field
semantics form a complete, isolated boundary.

Current coupling/problem:
Resolved. The helper calls primitive equality directly, and the facade only
delegates validation inputs.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Optional `schema_contract` presence and exact equality error behavior.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/schema_contract_field.ex`

Definition of done:
The callback bag and dynamic dispatch are gone, broad schema/export tests and
the exact fingerprint pass, and xref shows only primitive support.

Behavior/schema changes:
None. Optional-field presence semantics, paths, errors, and deterministic schema
output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- 59 cross-family campaign, refresh, timeline, resource, validation, operator
  review, and schema-export tests passed.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and the helper's sole dependency on primitive
  support.
- Formatting, `git diff --check`, and checked-in schema cleanliness passed.

Verification gaps:
- Full suite not run; the cross-family gate and deterministic fingerprint are
  the verification boundary for this slice.

Last commit:
`422ae6f0` (`Collapse schema contract field callback`).

Next candidate:
Reassess another primitive-only callback bag; defer mixed activity-context
ownership until its facade-specific dependencies have support boundaries.

Blocked:
No.

Notes:
- `schema.ex` is 14,594 lines after this slice (down from 14,601).
- `SchemaContractField` is 13 lines and no longer resolves dynamic callbacks.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.

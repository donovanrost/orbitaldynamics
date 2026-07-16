# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: resource-projection assumption callback cleanup.

Status:
Completed and published.

Selected slice:
Let `Schema.ResourceProjectionAssumptionsContracts` call optional-field equality
validation directly.

Why this slice:
Its only callback now points to primitive support, and its three exact
capability assertions form one cohesive boundary.

Current coupling/problem:
Resolved. Assumption validation calls primitive equality directly, and the
facade only delegates validation inputs.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Resource-projection subsystem capability assumption order and exact errors.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/resource_projection_assumptions_contracts.ex`

Definition of done:
The callback bag and dynamic dispatch are gone, resource/broad export tests and
the exact fingerprint pass, and xref shows primitive/resource dependencies.

Behavior/schema changes:
None. Capability assertion order, paths, messages, and deterministic schema
output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- 28 resource, candidate-refresh provenance, campaign repair/strategy, JSON
  schema, and schema-export tests passed.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows facade/JSON-schema callers and direct dependencies on resource
  projection plus primitive validation.
- Formatting, `git diff --check`, and checked-in schema cleanliness passed.

Verification gaps:
- Full suite not run; the resource/export gate and deterministic fingerprint
  are the verification boundary for this slice.

Last commit:
`631a9228` (`Collapse resource assumption callback`).

Next candidate:
Assess the two list-count handoff callback bags; keep mixed activity-context
ownership deferred.

Blocked:
No.

Notes:
- `schema.ex` is 14,587 lines after this slice (down from 14,594).
- `ResourceProjectionAssumptionsContracts` is 45 lines and no longer resolves
  dynamic callbacks.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Realized spacecraft-state row callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace realized spacecraft-state row callbacks with direct primitive and
stable-ID support while preserving parent snapshot composition.

Why this slice:
All six callbacks map to existing support, with focused snapshot tests covering
required identity, stable IDs, and incompatible activity-type list items.

Current coupling/problem:
The snapshot parent forwards its broad callback bag into a cohesive leaf that
needs only shared primitive and stable-ID behavior.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema/realized_spacecraft_state_contracts.ex`
- `lib/orbital_dynamics/schema/realized_state_snapshot_contracts.ex`

Definition of done:
The snapshot parent no longer forwards callbacks into spacecraft-state rows,
leaf wrappers are gone, focused snapshot/export tests and fingerprint pass, and
xref shows direct primitive/stable-ID dependencies.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors`
- `mix test test/orbital_dynamics/schema/contact_feedback_contracts_test.exs:1157 test/orbital_dynamics/schema/contact_feedback_contracts_test.exs:1651 test/orbital_dynamics/schema_export_test.exs`
  (5 passed, 3 excluded)
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- Contract fingerprint:
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- `mix xref callers OrbitalDynamics.Schema.RealizedSpacecraftStateContracts`
- Focused xref graph for the spacecraft-state leaf
- `mix format --check-formatted`
- `git diff --check`

Verification gaps:
- Full suite not run.

Last commit:
`89c76db7` (`Collapse realized spacecraft state callbacks`).

Next candidate:
Audit the resource-projection flow-row leaf callback boundary; keep campaign
strategy and mixed activity-context deferred.

Blocked:
No.

Notes:
- Starting point: the realized spacecraft-state leaf is 57 lines; its snapshot
  parent is 268 lines.
- Ending point: the leaf is 46 lines and the parent is 261 lines.
- The generated schema export was byte-for-byte unchanged.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema-migration callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Move schema-migration report model limits into the cohesive leaf and replace
its callback bag with direct primitive and collection validation.

Why this slice:
Thirteen callbacks mapped to shared support and the fixed model-limit list could
be owned by the leaf while remaining the single executable/JSON Schema source.

Result:
- Removed the fourteen-function facade callback bag and callback argument.
- `SchemaMigrationContracts` now calls shared primitive/collection validation
  directly and owns `model_limits/0` for executable and JSON Schema validation.
- Preserved validation order, derived status/counts, row actions/statuses, exact
  paths/messages, validation levels, and checked-in schema output.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`

Files changed:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/schema_migration_contracts.ex`

Verification:
- `mix compile --warnings-as-errors` passed.
- Focused validation/policy/schema-export tests passed: 6 tests, 0 failures,
  179 excluded.
- Runtime mutation probes preserved exact model-limit, deprecated-row
  replacement, and migration-action-count paths/messages.
- `mix orbital_dynamics.schema.export --all --directory schemas --output
  schemas/orbital_dynamics.schema_bundle.v1.json` passed.
- Schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Checked-in schema exports were unchanged.
- `mix format --check-formatted`, `git diff --check`, and focused xref caller
  checks passed; the leaf directly depends on primitive/collection support.
- Final review found no remaining schema-migration callback adapter/helper.

Verification gaps:
- Full suite not run; focused coverage was used for this behavior-preserving
  boundary cleanup.

Published implementation:
`c0630eb5` (`Collapse schema migration callbacks`).

Size change:
- `schema.ex`: 13,741 -> 13,712 lines.
- `schema_migration_contracts.ex`: 227 -> 173 lines.

Next candidate:
Study-benchmark callback ownership cleanup. Its twelve callbacks are shared
primitive/collection validation or the cohesive `SchemaContractField` helper;
the curated benchmark fixture test covers eight fixture families plus stale
scenario-count behavior.

Blocked:
No.

Notes:
- Realized-state-snapshot and timeline-transition application rows remain
  deferred because they compose callback-driven nested validators.
- Quality/readiness gates, plan delta, campaign plan/strategy, activity context,
  and resource-projection flow rows remain deferred because their bags compose
  facade-owned contextual or nested artifact validation.

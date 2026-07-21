# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Declare and reconcile nested V2 Cadence import manifests.

Status:
Complete; ready to publish.

Selection evidence:
- V2 always derives `cadence_import_manifest.v1` from its embedded
  `operator_review_package.v1`, but the repair registry declares neither the
  field nor its nested contract.
- Repair runtime validation therefore does not apply the standalone manifest's
  row, derived-count, model-limit, and no-write boundary checks.
- Both checked V2 manifests pass standalone validation and preserve their
  enclosing repair ID, review count, and ordered operator-review row IDs.

Intended behavior:
- Declare the optional Cadence import manifest and V1 nested contract in the V2
  registry and generated JSON Schema.
- Run the complete standalone Cadence import validator inside repair validation.
- Pin manifest source type/ID and row-source assumption to the enclosing repair
  and operator-review package.
- Reconcile manifest/provenance review counts and ordered source-review row IDs
  against the enclosing review package.
- Keep the field optional for compatible older V2 artifacts.
- Add checked-fixture, standalone, source/join, optional-manifest, and
  schema-export coverage; document the executable guarantee.

Level 6 pillar advanced:
Versioned, traceable V2 Cadence handoffs with executable nested validation.

Last published slice:
- `1fe471a9` Validate nested V2 command windows (`3745 passed`).

Likely files:
- V2 registry/runtime Cadence import contracts
- focused Cadence import and schema-export tests
- checked-in schema exports and V2 capability docs

Verification:
- Focused Cadence import contract tests: `5 passed`.
- Campaign-repair schema fixtures: `52 passed`.
- Schema suite plus schema-lint/export task tests: `439 passed`.
- Campaign-planner suite: `761 passed`.
- Full checked-artifact lint: `155/155 passed`, zero warnings.
- Full suite: `3750 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- Full schema export refreshed the V2 repair schema and aggregate bundle only.

Review:
- The V2 registry now declares optional `cadence_import_manifest` and its V1
  nested contract; generated schemas expose the complete manifest definition
  without requiring the field from compatible older V2 artifacts.
- Runtime repair validation now applies the standalone manifest contract,
  including row shapes and identities, derived counts/maps, supported source
  types, exact model limits, and artifact-only no-write assumptions.
- Repair-specific validation pins source type and source ID to the enclosing
  repair, requires the operator-review package named by the row-source
  assumption, and reconciles review counts plus ordered row IDs across the
  handoff.
- Both checked V2 repairs, all checked artifacts, and existing V1 Cadence import
  consumers remain valid.

Remaining maturity gaps:
- Continue exact V2 ranking/score reconciliation for replayable source fields.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent is performing bounded
mapping, implementation, review, and mechanical publish checks.

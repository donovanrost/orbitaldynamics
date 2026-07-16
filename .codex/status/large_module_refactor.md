# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Optimizer-objective callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace the four optimizer-objective validator entry points' callback plumbing
with direct shared dependencies and leaf-owned model vocabularies.

Why this slice:
Shared primitive, collection, stable-ID, and numeric-map support is already
extracted; numeric delta has cohesive aggregation support; limits come from
public planner/optimizer APIs; two fixed model vocabularies belong in the leaf.

Result:
- Removed the twenty-six-function facade bag and four callback arguments.
- Moved fixed tradeoff/score model vocabularies into the leaf as the single
  executable/JSON Schema source and removed the facade duplicates.
- The leaf now directly uses planner/optimizer limits plus primitive,
  collection, stable-ID, numeric-map, and numeric-delta support.
- Preserved row traversal, derived counts/keys/deltas, model limits, validation
  order, exact paths/messages, and schema output.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/optimizer_objective_contracts.ex`

Verification:
- `mix compile --warnings-as-errors` passed.
- Dedicated optimizer-objective contracts, four curated fixture families, and
  schema-export tests passed: 9 tests, 0 failures, 177 excluded.
- Runtime probes preserved exact tradeoff count, satisfaction selected-count,
  ranking value-delta, and score-term-key paths/messages.
- Full schema export passed; checked-in schemas remained unchanged.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref confirms the facade-only leaf entry and direct aggregation dependency.
- `mix format --check-formatted`, `git diff --check`, callback residue checks,
  and bounded diff review passed.

Verification gaps:
- Full suite not run; focused coverage was used for this behavior-preserving
  boundary cleanup.

Published implementation:
`0bf754db` (`Collapse optimizer objective callbacks`).

Size change:
- `schema.ex`: 13,620 -> 13,565 lines.
- `optimizer_objective_contracts.ex`: 559 -> 475 lines.

Next candidate:
Realized-activity callback ownership cleanup. Its fifteen shared validation
callbacks can become direct imports, and execution uncertainty already has a
cohesive `ExecutionMetricContracts` entry point; the leaf owns metadata identity
and provider trust-boundary semantics.

Blocked:
No.

Notes:
- Realized-activity focused fixtures cover identity objects, provider trust,
  uncertainty, vectors/probabilities, status, and derived metadata IDs.
- Starting point: `schema.ex` is 13,620 lines; optimizer-objective contracts are
  559 lines.
- Previous implementation commit: `206faab0`.
- Branch-event validation was audited and deferred because it composes semantic
  change, candidate-diff, safety-case, and other facade-owned validators.
- Approval-requirement validation was audited and deferred because it composes
  facade-owned activity-context, policy-rule-match, and escalation validators.
- Realized-state-snapshot and timeline-transition application rows remain
  deferred because they compose callback-driven nested validators.
- Quality/readiness gates, plan delta, campaign plan/strategy, activity context,
  and resource-projection flow rows remain deferred because their bags compose
  facade-owned contextual or nested artifact validation.

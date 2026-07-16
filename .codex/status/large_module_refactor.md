# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest-field-reference callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace the manifest-field-reference callback bag with direct primitive
validation while keeping the field-graph semantics in its cohesive leaf.

Why this slice:
All seven callbacks are shared primitive validation; the leaf already owns
derived counts, duplicate paths, parent links, sections, enum evidence,
top-level-required fields, activation sections, and array-item consistency.

Result:
- Removed the seven-function facade bag and callback argument.
- The leaf now directly uses primitive validation while retaining all field
  graph, enum, activation, required-field, and row-integrity semantics.
- Preserved graph traversal, derived comparisons, validation order, and exact
  paths/messages.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/manifest_field_reference_contracts.ex`

Verification:
- `mix compile --warnings-as-errors` passed.
- Focused curated fixture, JSON Schema field-reference, and schema-export tests
  passed: 5 tests, 0 failures, 194 excluded.
- Runtime probes preserved exact derived-count, duplicate-path, and enum-evidence
  paths/messages (including the existing nil count message).
- Full schema export passed; checked-in schemas remained unchanged.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade as the only runtime caller.
- `mix format --check-formatted`, `git diff --check`, callback residue checks,
  and bounded diff review passed.

Verification gaps:
- Full suite not run; focused coverage was used for this behavior-preserving
  boundary cleanup.

Published implementation:
`206faab0` (`Collapse manifest field reference callbacks`).

Size change:
- `schema.ex`: 13,633 -> 13,620 lines.
- `manifest_field_reference_contracts.ex`: 435 -> 403 lines.

Next candidate:
Optimizer-objective callback ownership cleanup. Its shared validation callbacks
can become direct imports; numeric delta already has cohesive shared support;
fixed model vocabularies can move into the leaf and remain the JSON Schema
source, while model limits come from public planner/optimizer APIs.

Blocked:
No.

Notes:
- Branch-event validation was audited and deferred because it composes semantic
  change, candidate-diff, safety-case, and other facade-owned validators.
- Approval-requirement validation was audited and deferred because it composes
  facade-owned activity-context, policy-rule-match, and escalation validators.
- Realized-state-snapshot and timeline-transition application rows remain
  deferred because they compose callback-driven nested validators.
- Quality/readiness gates, plan delta, campaign plan/strategy, activity context,
  and resource-projection flow rows remain deferred because their bags compose
  facade-owned contextual or nested artifact validation.

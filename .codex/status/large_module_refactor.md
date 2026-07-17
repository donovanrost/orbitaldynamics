# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection direct callback ownership cleanup.

Status:
Selected; implementation pending.

Selected slice:
Point the battery-field, remaining-field, battery-source, flow-context,
own-flow, and three cadence resource-projection callback captures directly at
the existing `Schema.ResourceProjectionHandoffContracts` owner. Remove the
eight pure delegates. Keep the general count-source delegate in the facade
because it injects the facade-owned downlink-flow predicate.

Why this slice:
Sixteen capture positions forward unchanged through eight pure delegates to one
existing owner. Direct captures consolidate battery, remaining, flow-context,
own-flow, and cadence validation without creating a callback bag. Excluding the
general count-source path preserves the explicit dependency on
`resource_projection_downlink_flow_row?/1` and keeps the boundary cohesive.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, cadence-import behavior, JSON Schema bytes, and aggregate
schema export bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused cadence-import, readiness, and review-import handoff contract tests
- JSON Schema contract/export tests and full checked-in schema regeneration
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
Every callback list directly captures the corresponding public
`ResourceProjectionHandoffContracts` validator for the selected eight
functions, those facade delegates are gone, and the dependency-bearing general
count-source wrapper remains unchanged,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema station-calendar handoff callback ownership cleanup published as
`a7b5f246`: all count-list and general/cadence source-match captures now point
directly to their existing contract owner; 182 schema/export tests passed,
full export bytes stayed exact, and bounded review was clean.

Next candidate:
Audit the resource-projection handoff callback family. Several delegates target
`ResourceProjectionHandoffContracts`, but count and battery paths also carry
predicate/row-selection dependencies. Select only a cohesive subset whose
callbacks and fallback clauses can be moved without creating a broad callback
bag or crossing the separate own-flow validator path.

Blocked:
No.

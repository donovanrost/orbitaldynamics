# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection direct callback ownership cleanup.

Status:
Completed and verified; publishing.

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

Outcome:
All sixteen selected resource-projection captures now point directly to the
existing `ResourceProjectionHandoffContracts` owner. Eight pure delegates were
removed, reducing `schema.ex` from 8,854 to 8,766 lines. Source-evidence
callback order is unchanged, and the three general count-source captures still
use the retained facade wrapper and downlink predicate exactly as before.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 47 focused resource-projection-referencing schema contract tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Behavior/schema changes:
None.

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

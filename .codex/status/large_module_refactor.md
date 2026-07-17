# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection count predicate ownership extraction.

Status:
Completed and published.

Selected slice:
Move `resource_projection_downlink_flow_row?/1` into
`Schema.ResourceProjectionHandoffContracts`, add a self-contained
`validate_count_handoff_matches_source/3`, and point the three facade callback
captures directly to it. Preserve the existing owner `/4` function.

Why this slice:
The four predicate clauses have no consumer outside the remaining facade
count-source wrapper. Moving them beside `handoff_count_values/2` gives the
resource-projection owner a complete default validation path while retaining
the injectable `/4` API. The three callback positions can then bypass the
facade without passing a callback bag.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, cadence-import behavior, JSON Schema bytes, and aggregate
schema export bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/resource_projection_handoff_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused cadence-import, readiness, and review-import handoff contract tests
- JSON Schema contract/export tests and full checked-in schema regeneration
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The owner exposes `/3` count-source validation using the moved predicate,
retains `/4` compatibility, all three facade captures point directly to `/3`,
and the facade wrapper/predicate clauses are gone,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Outcome:
`ResourceProjectionHandoffContracts` now owns the default downlink-flow
predicate and exposes self-contained count-source validation through `/3`.
All three facade callbacks point directly to it; the existing injectable `/4`
API is unchanged. Removing the facade wrapper and four predicate clauses
reduced `schema.ex` from 8,766 to 8,736 lines.

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
Schema resource-projection count predicate ownership extraction published as
`1bad14c5`: the owner now supplies default `/3` count validation with the moved
predicate while preserving injectable `/4`; 182 schema/export tests passed,
full export bytes stayed exact, and bounded review was clean.

Next candidate:
Audit `ContactAllocationHandoffContracts` source-match ownership separately
from allocation-field validation. General/cadence allocation, capacity-pack,
and provider-calendar contention validators appear directly capturable, while
allocation fields still inject a facade-owned duplicate-evidence validator.
Select only the dependency-free source-match subset.

Blocked:
No.

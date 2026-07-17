# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection count predicate ownership extraction.

Status:
Selected; implementation pending.

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

Verification gaps:
- Implementation and verification pending.

Tests run:
- Pending.

Behavior/schema changes:
None.

Last completed slice:
Schema resource-projection direct callback ownership cleanup published as
`06762106`: sixteen battery/remaining/flow/cadence captures now point directly
to their existing owner while the dependency-bearing count wrapper remains;
182 schema/export tests passed, full export bytes stayed exact, and bounded
review was clean.

Next candidate:
Audit moving the resource-projection downlink-flow predicate into
`ResourceProjectionHandoffContracts` and adding a facade-independent
`validate_count_handoff_matches_source/3`. Preserve the existing `/4` owner API;
select only if the predicate has no other facade consumers and all three count
captures can then point directly to the owner.

Blocked:
No.

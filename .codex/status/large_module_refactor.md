# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation capability callback routing.

Status:
Completed and pushed.

Selected boundary:
Add a whole-capability accessor to the existing
`OrbitalDynamics.Schema.ContactAllocationCapabilityContext` and route the
contact-allocation property-dispatch callback through it.
Keep contact-allocation property dispatch, row/capacity-pack schema
construction, assumptions composition, validation, and all public facades in
their current owners.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,188 lines.
- One lazy property-dispatch callback still queries
  `ContactAllocation.capabilities/0` directly even though all capability
  projections and assumptions already live in ContactAllocationCapabilityContext.
- A focused accessor and function capture complete that family's schema-facing
  capability ownership while preserving callback timing and per-call
  evaluation.
- Exact capability values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Added `contact_allocation_capabilities/0` to the existing
ContactAllocationCapabilityContext and replaced the facade's anonymous direct
domain callback with a focused function capture.
`schema.ex` moved from 6,188 to 6,187 lines; the existing capability owner
moved from 138 to 142 lines.

Verification:
- Strict focused contact-allocation/provider-reservation/export baseline
  before routing: 24 passed.
- The same strict focused suite after routing: 24 passed.
- Strict full schema-export task plus adjacent communications/report-fixture/
  fixture-visibility coverage: 14 passed.
- `mix xref callers
  OrbitalDynamics.Schema.ContactAllocationCapabilityContext` reports only
  `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,062 files.
- Implementation commit `760401de` pushed to `main`.

Behavior/schema changes:
None. Public facades, lazy callback timing, per-call capability evaluation,
capability values and ordering, generated JSON Schema, validation behavior,
and checked-in exports remain unchanged.

Last completed slice:
Schema contact-allocation capability callback routing, selected in `343d06ea`
and implemented in `760401de`.
`schema.ex` moved from 6,188 to 6,187 lines; the existing
ContactAllocationCapabilityContext owner moved from 138 to 142 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.

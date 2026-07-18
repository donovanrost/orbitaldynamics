# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema standalone communications property-dispatch extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for station-calendar provider,
relay data-path summary, and contact-allocation report into an internal
`Schema.StandaloneCommunicationsPropertyDispatch` owner.

Why this slice:
`Schema` is 7,775 lines. These three focused-schema clauses still assemble
communications contexts in the facade, while their adjacent reservation,
link-capacity, and contact-allocation-summary families already delegate.

Current coupling/problem:
The facade owns entry, relay model/assumption/row/count, and allocation
row/capacity/model/collection/capability contexts for three standalone
communications contracts.

Public facade to preserve:
All `Schema` APIs; the three JSON Schema documents; checked-in exports,
deterministic ordering, focused fallback behavior, context evaluation order,
and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/standalone_communications_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The three clauses pass compact dependencies to the new owner; named contexts
and focused fallback routing move out of `Schema`; focused station-provider,
communications, contact-allocation, and export tests pass; strict compile,
full byte-clean schema regeneration, and independent review are clean.

Verification gaps:
- Focused baseline, strict compile, export proof, and independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Ground-network report schema dispatch published as implementation `12c5485e`
and handoff `78348f18`: focused 30/30, strict 3,657-file compile, full
byte-clean schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`.

Blocked:
No.

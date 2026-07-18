# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema standalone communications property-dispatch extraction.

Status:
Implementation published as `3f05cbe7`; handoff publication pending.

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
- None for this slice. Full checked-in schema regeneration is byte-identical.
- Independent review was clean. No API, schema, export, ordering,
  error-behavior, ownership, or behavioral finding remains.

Tests run:
- Baseline and post-change focused station-provider/communications/
  contact-allocation/export subset: 37 passed with warnings as errors.
- Strict forced compile: 3,658 files clean with warnings as errors.
- Full schema export regenerated every checked-in schema and bundle with zero
  diff.
- Public `Schema` definitions match selection commit `3cf5af7a`; xref reports
  the dispatcher has only the `Schema` runtime caller.
- Format, changed/new-file whitespace, and `git diff --check` passed.
- Independent review confirmed exact context values and ordering, preserved
  eager calendar-provider entry evaluation and lazy relay/allocation
  dependencies, untouched adjacent dispatchers, then reran all proof clean.

Behavior/schema changes:
None intended.

Outcome:
Station-calendar provider, relay data-path summary, and contact-allocation
report routing now delegates to `StandaloneCommunicationsPropertyDispatch`.
Implementation published as `3f05cbe7`.

Last completed slice:
Ground-network report schema dispatch published as implementation `12c5485e`
and handoff `78348f18`: focused 30/30, strict 3,657-file compile, full
byte-clean schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`.

Blocked:
No.

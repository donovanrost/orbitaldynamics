# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema ground-network report property-dispatch extraction.

Status:
Slice selected; implementation not started.

Selected slice:
Move JSON-property dispatch/context assembly for command-window, station
calendar precedence, station reservation report, and station calendar report
into an internal `Schema.GroundNetworkReportPropertyDispatch` owner.

Why this slice:
`Schema` is 7,783 lines. These four adjacent communications/ground-network
report clauses already use dedicated builders, while reservation-summary and
link-capacity families already have their own dispatchers.

Current coupling/problem:
The facade owns named contexts for command rows, station models/contacts,
provider contention and entries, trust-boundary counts, stable IDs, and model
limits across four related reports.

Public facade to preserve:
All `Schema` APIs; the four report JSON Schema documents; checked-in exports,
deterministic ordering, focused fallback behavior, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/ground_network_report_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The four clauses pass compact dependencies to the new owner; named contexts and
focused fallback routing move out of `Schema`; focused command/station/
communications/export tests pass; strict compile, full byte-clean schema
regeneration, and independent review are clean.

Verification gaps:
- Focused command/station/communications/export baselines need capture.
- Checked-in schema exports must remain byte-identical.

Tests run:
- Live mapping found four adjacent report clauses with dedicated builders.
- Existing station-reservation-summary and link-capacity dispatchers are
  explicitly out of scope.
- No runtime or schema code has changed in this slice.

Behavior/schema changes:
None intended.

Outcome:
Pending.

Last completed slice:
Timeline transition schema dispatch published as implementation `fc25d762` and
handoff `f02b5597`: focused 40/40, strict 3,656-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
Implement and verify ground-network report schema property dispatch.

Blocked:
No.

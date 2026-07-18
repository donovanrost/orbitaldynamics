# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-rejection timeline property-dispatch extension.

Status:
Slice selected; selection publication pending.

Selected slice:
Move focused JSON-property routing/context assembly for candidate-rejection
report into the existing internal `Schema.TimelineReportPropertyDispatch`
owner, then remove the facade's now-unused `focused_json_schema_property/5`.

Why this slice:
`Schema` is 7,733 lines. Candidate rejection is the final direct focused
property clause and belongs with the existing operational timeline/report
owner.

Current coupling/problem:
The facade owns candidate-rejection limits, rows, reasons, operator actions,
stable-pattern context, focused fallback routing, and the shared helper that
will have no remaining callers.

Public facade to preserve:
All `Schema` APIs; the candidate-rejection JSON Schema document; checked-in
exports, deterministic ordering, focused fallback behavior, provider order and
arity, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_report_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The clause passes compact dependencies to the existing owner; named context and
focused fallback routing move out of `Schema`; the unused private facade helper
is removed; focused rejection/timeline/export tests pass; strict compile, full
byte-clean schema regeneration, and independent review are clean.

Verification gaps:
- Focused baseline, strict compile, export proof, and independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Schema-migration schema dispatch published as implementation `49c99fb8` and
handoff `3f4c5723`: focused 24/24, strict 3,667-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
After publication, remap `Schema` and the original large-module goal hotspots
to select the next responsibility-based extraction beyond property dispatch.

Blocked:
No.

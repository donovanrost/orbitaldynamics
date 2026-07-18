# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-report property-dispatch extraction.

Status:
Slice selected; implementation not started.

Selected slice:
Move JSON-property dispatch/context assembly for timeline feedback, integrity,
dependency-impact, and publication artifacts into an internal
`Schema.TimelineReportPropertyDispatch` owner.

Why this slice:
`Schema` remains 7,793 lines. These four adjacent clauses share the same
focused-dispatch pattern and already delegate property construction to dedicated
family builders, making their named context assembly one cohesive boundary.

Current coupling/problem:
The Schema facade still names and assembles row, capability, identity,
source-summary, stable-ID collection, issue-type, and model-limit dependencies
for four related timeline report families.

Public facade to preserve:
All `Schema` APIs; timeline feedback, integrity, dependency-impact, and
publication JSON Schema documents; recursive/embedded schema behavior;
checked-in exports, deterministic ordering, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_report_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The four clauses supply compact dependency tuples to the new dispatcher; named
builder contexts and focused fallback routing move out of the facade; focused
timeline schema tests pass; strict compile, full checked-in export
regeneration, and independent review are clean.

Verification gaps:
- Focused timeline schema/export baselines still need to be captured.
- Checked-in schema exports must remain byte-identical.

Tests run:
- Live mapping confirmed four adjacent dedicated builders with no registry
  mutation or contract-definition changes.
- Candidate focused files include timeline report/summary, operational
  timeline, and JSON-schema export contracts.
- No runtime or schema code has changed in this slice.

Behavior/schema changes:
None intended.

Outcome:
Pending.

Last completed slice:
Campaign-artifact schema dispatch published as implementation `11ef0e9e` and
handoff `ba4b237b`: focused 19/19, strict 3,653-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
Implement and verify timeline-report schema property dispatch.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-report property-dispatch extraction.

Status:
Implementation published as `4bf57bd4`; handoff publication pending.

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
- None for this slice. Full checked-in schema regeneration is byte-identical.
- Independent review found and verified the fix for one lazy-fallback
  regression. No API, schema, export, ordering, error-behavior, ownership, or
  behavioral finding remains.

Tests run:
- Baseline and final focused timeline schema/export subset: 42 passed with
  warnings as errors.
- Strict forced compile: 3,653 files clean with warnings as errors.
- Full schema export regenerated every checked-in schema and bundle with zero
  diff.
- Public `Schema` definitions match selection commit `d79cdea9`; xref reports
  the dispatcher has only the Schema runtime caller.
- Format, whitespace, and `git diff --check` passed.
- Independent review caught eager `:default_property` lookup in the existing
  `property/4` path. The corrected closure restores lazy fallback and exact
  error precedence; direct focused/fallback checks, 42/42, compile, and full
  export all passed on the final state.

Behavior/schema changes:
None intended.

Outcome:
The existing `TimelineReportPropertyDispatch` now also owns named contexts for
feedback, integrity, dependency-impact, and publication families. Its original
operational/diff/summary API remains compatible. Implementation published as
`4bf57bd4`.

Last completed slice:
Campaign-artifact schema dispatch published as implementation `11ef0e9e` and
handoff `ba4b237b`: focused 19/19, strict 3,653-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
Publish this handoff, then select the next cohesive Schema property family.

Blocked:
No.

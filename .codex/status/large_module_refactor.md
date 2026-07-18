# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline transition property-dispatch extraction.

Status:
Implementation published as `fc25d762`; handoff publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for timeline lifecycle-state
summary and transition-application report/summary into an internal
`Schema.TimelineTransitionPropertyDispatch` owner.

Why this slice:
`Schema` is 7,787 lines. These three adjacent transition/lifecycle summary
contracts already have dedicated builders but still assemble row, selected
activity, capability, count-map, stable-ID collection, and model-limit
dependencies in the facade.

Current coupling/problem:
The facade owns named contexts for lifecycle rollups and contract-dependent
transition-application routing, obscuring the family boundary behind public
schema export.

Public facade to preserve:
All `Schema` APIs; lifecycle summary and transition-application JSON Schema
documents; contract-dependent fields, checked-in exports, deterministic
ordering, focused fallback, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_transition_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The two facade clauses pass compact dependencies to the new owner; named
contexts and focused fallback routing move out of `Schema`; focused timeline
report/summary/export tests pass; strict compile, full byte-clean schema
regeneration, and independent review are clean.

Verification gaps:
- None for this slice. Full checked-in schema regeneration is byte-identical.
- Independent review was clean. No API, schema, export, ordering,
  error-behavior, ownership, or behavioral finding remains.

Tests run:
- Baseline and post-change focused timeline report/summary/export subset:
  40 passed with warnings as errors.
- Strict forced compile: 3,656 files clean with warnings as errors.
- Full schema export regenerated every checked-in schema and bundle with zero
  diff.
- Public `Schema` definitions match selection commit `35691054`; xref reports
  the dispatcher has only the Schema runtime caller.
- Format, tracked/new-file whitespace, and `git diff --check` passed.
- Independent review confirmed exact positional lifecycle dependencies,
  contract-sensitive transition routing, context/fallback error order, then
  reran compile, 40/40, and full export.

Behavior/schema changes:
None intended.

Outcome:
Lifecycle-state summary and transition-application report/summary property
routing now delegates to `TimelineTransitionPropertyDispatch`.
Implementation published as `fc25d762`.

Last completed slice:
Timeline protection schema dispatch published as implementation `facf3107` and
handoff `aaef69e3`: focused 32/32, strict 3,655-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
Publish this handoff, then select the next cohesive Schema property family.

Blocked:
No.

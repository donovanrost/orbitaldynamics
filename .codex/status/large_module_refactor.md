# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline protection property-dispatch extraction.

Status:
Implementation published as `facf3107`; handoff publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for activity precondition summaries
and timeline preservation report/status into an internal
`Schema.TimelineProtectionPropertyDispatch` owner.

Why this slice:
After activity-state dispatch, `Schema` is 7,788 lines. Preconditions and
preservation are the remaining adjacent lifecycle-safety contexts: both already
have dedicated JSON-schema builders but still assemble identity, protection,
assumption, count, status, and model-limit dependencies in the facade.

Current coupling/problem:
The Schema facade owns named contexts for one precondition contract and two
preservation contracts, including contract-dependent property selection and
assumption generation.

Public facade to preserve:
All `Schema` APIs; precondition and preservation JSON Schema documents;
contract-specific preservation behavior, checked-in exports, focused fallback,
deterministic ordering, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_protection_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The two facade clauses pass compact dependencies to the new owner; named
contexts and focused fallback routing move out of `Schema`; focused timeline
summary/export tests pass; strict compile, full byte-clean schema regeneration,
and independent review are clean.

Verification gaps:
- None for this slice. Full checked-in schema regeneration is byte-identical.
- Independent review was clean. No API, schema, export, ordering, evaluation,
  error-behavior, ownership, or behavioral finding remains.

Tests run:
- Baseline and post-change focused timeline summary/export subset: 32 passed
  with warnings as errors.
- Strict forced compile: 3,655 files clean with warnings as errors.
- Full schema export regenerated every checked-in schema and bundle with zero
  diff.
- Public `Schema` definitions match selection commit `a235ff14`; xref reports
  the dispatcher has only the Schema runtime caller.
- Format, tracked/new-file whitespace, and `git diff --check` passed.
- Independent review confirmed exact precondition/preservation contexts,
  contract-dependent routing, lazy precondition limits, eager preservation
  limits, fallback/error order, then reran compile, 32/32, and full export.

Behavior/schema changes:
None intended.

Outcome:
Activity precondition and preservation report/status property routing now
delegates to `TimelineProtectionPropertyDispatch`; named lifecycle-safety
contexts live in the family owner. Implementation published as `facf3107`.

Last completed slice:
Timeline activity-state schema dispatch published as implementation `a3bc7e2a`
and handoff `11e6498d`: focused 24/24, strict 3,654-file compile, full
byte-clean schema regeneration, and independent review passed.

Next candidate:
Publish this handoff, then select the next cohesive Schema property family.

Blocked:
No.

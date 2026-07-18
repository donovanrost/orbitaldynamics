# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline protection property-dispatch extraction.

Status:
Slice selected; implementation not started.

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
- Focused timeline summary/export baselines still need to be captured.
- Checked-in schema exports must remain byte-identical.

Tests run:
- Live mapping found two clauses covering three lifecycle-safety contracts and
  two existing family-specific JSON-schema builders.
- No runtime or schema code has changed in this slice.

Behavior/schema changes:
None intended.

Outcome:
Pending.

Last completed slice:
Timeline activity-state schema dispatch published as implementation `a3bc7e2a`
and handoff `11e6498d`: focused 24/24, strict 3,654-file compile, full
byte-clean schema regeneration, and independent review passed.

Next candidate:
Implement and verify timeline protection schema property dispatch.

Blocked:
No.

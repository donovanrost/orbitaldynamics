# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline activity-state property-dispatch extraction.

Status:
Implementation published as `a3bc7e2a`; handoff publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for `timeline_activity_state` and
the status/approval/lifecycle state trio into an internal
`Schema.TimelineActivityStatePropertyDispatch` owner.

Why this slice:
`Schema` remains 7,791 lines. These adjacent logical state contracts already
have two dedicated JSON-schema builders but no family dispatcher, leaving
lifecycle identity, transition, protection, context, assumption, and
model-limit wiring in the facade.

Current coupling/problem:
The Schema facade names and assembles the complete activity-state and
lifecycle-state builder contexts, including contract-specific lifecycle/default
assumption selection for three related contracts.

Public facade to preserve:
All `Schema` APIs; the four timeline activity-state JSON Schema documents;
contract-specific assumptions, checked-in exports, deterministic ordering,
focused fallback behavior, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_activity_state_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The two facade clauses pass compact dependencies to the new owner; named
builder contexts and focused fallback routing move out of `Schema`; focused
activity-state/export tests pass; strict compile, full byte-clean schema
regeneration, and independent review are clean.

Verification gaps:
- None for this slice. Full checked-in schema regeneration is byte-identical.
- Independent review was clean. No API, schema, export, ordering, assumptions,
  error-behavior, ownership, or behavioral finding remains.

Tests run:
- Baseline and post-change focused activity-state/export subset: 24 passed with
  warnings as errors.
- Strict forced compile: 3,654 files clean with warnings as errors.
- Full schema export regenerated every checked-in schema and bundle with zero
  diff.
- Public `Schema` definitions match selection commit `56fa8208`; xref reports
  the dispatcher has only the Schema runtime caller.
- Format, tracked/new-file whitespace, and `git diff --check` passed.
- Independent review confirmed exact named contexts, contract-specific
  lifecycle routing, stable-ID pattern, capability/limits, assumption closure,
  focused fallback/error order, then reran compile, 24/24, and full export.

Behavior/schema changes:
None intended.

Outcome:
Timeline activity state plus status/approval/lifecycle property routing now
delegates to `TimelineActivityStatePropertyDispatch`; the facade supplies only
compact captures/scalars. Implementation published as `a3bc7e2a`.

Last completed slice:
Timeline-report schema dispatch published as implementation `4bf57bd4` and
handoff `4351b7c7`: final focused 42/42, strict 3,653-file compile, full
byte-clean schema regeneration, and independent review passed after restoring
lazy default fallback in the pre-existing dispatcher API.

Next candidate:
Publish this handoff, then select the next cohesive Schema property family.

Blocked:
No.

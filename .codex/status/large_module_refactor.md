# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline activity-state property-dispatch extraction.

Status:
Slice selected; implementation not started.

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
- Focused activity-state/export baselines still need to be captured.
- Checked-in schema exports must remain byte-identical.

Tests run:
- Live mapping found two clauses covering four contracts and two existing
  family-specific JSON-schema builders.
- Timeline activity-state contract tests and JSON-schema export tests are the
  primary focused proof.
- No runtime or schema code has changed in this slice.

Behavior/schema changes:
None intended.

Outcome:
Pending.

Last completed slice:
Timeline-report schema dispatch published as implementation `4bf57bd4` and
handoff `4351b7c7`: final focused 42/42, strict 3,653-file compile, full
byte-clean schema regeneration, and independent review passed after restoring
lazy default fallback in the pre-existing dispatcher API.

Next candidate:
Implement and verify timeline activity-state schema property dispatch.

Blocked:
No.

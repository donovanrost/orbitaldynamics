# Autonomous Product Loop Status

Current slice:
Raw timeline lifecycle-event helper parity.

Status:
Implemented, verified, and reviewed locally; ready for publish handoff. Raw
timeline-map adapters can now apply provider lifecycle-event tokens through
`Timeline.apply_lifecycle_event/2` and `Timeline.apply_lifecycle_event!/2`,
with matching top-level `OrbitalDynamics.timeline_apply_lifecycle_event/2` and
`!/2` facades. The helper normalizes lifecycle aliases, validates resulting
status and approval transitions, preserves transition provenance, and keeps
operator-authority changes plus malformed raw activity inputs review-gated.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/mission_activities.md`
- `docs/feature_set/capability_map/08_mission_activities/lifecycle-helpers-diffs-and-transitions.md`
- `lib/orbital_dynamics.ex`
- `lib/orbital_dynamics/timeline.ex`
- `test/orbital_dynamics/timeline_test.exs`

Tests run:
- `mix format lib/orbital_dynamics.ex lib/orbital_dynamics/timeline.ex test/orbital_dynamics/timeline_test.exs`
- `mix test test/orbital_dynamics/timeline_test.exs`
- `git diff --check -- .codex/status/autonomous_product_loop.md docs/artifacts/field_families/mission_activities.md docs/feature_set/capability_map/08_mission_activities/lifecycle-helpers-diffs-and-transitions.md lib/orbital_dynamics.ex lib/orbital_dynamics/timeline.ex test/orbital_dynamics/timeline_test.exs`

Docs/artifacts changed:
Mission activity docs now describe raw timeline lifecycle-event helpers and their
review-gated transition provenance. No generated artifacts or schema exports
changed.

Last commit:
`4532335` (`Publish shared timeline direction normalization`) was pushed to
`origin/main` before this slice.

Next candidate:
Continue priority-1 typed operational activity/timeline semantics. A likely next
slice is to expose compact lifecycle-event review evidence in operator-review or
Cadence import rows if downstream adapters need a standalone lifecycle-event
preflight artifact.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

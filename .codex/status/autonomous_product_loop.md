# Autonomous Product Loop Status

Current slice:
Instantiate `activity_template.v1` artifacts into transition-ready timeline
activity rows.

Status:
Implemented, verified, and read-only reviewed.

What changed:
- Added `OrbitalDynamics.activity_from_template/2`.
- The helper resolves a template by catalog id, activity type, or direct
  `activity_template.v1` map.
- It validates direct template maps with `Schema.validate_artifact/1`, merges
  template `lifecycle_defaults`, template `default_fields`, and caller
  overrides, enforces declared required fields plus intrinsic `id`/`type`, and
  rejects undeclared top-level override fields except `metadata`.
- It normalizes the result through `Timeline.normalize_activity/1` and returns
  `{:ok, normalized_activity}` or a structured `{:error, reason}` map.
- It preserves template provenance on the normalized activity and nested
  `activity_context`.
- Added a focused public facade test that instantiates observe and downlink
  templates, verifies direct template-map input, covers unknown/missing/
  undeclared/type-mismatch/invalid-template errors, feeds a helper-produced
  replacement into `timeline_transition_application/2`, and validates a
  `timeline_transition_application_report.v1` no-mutation handoff.

Verification:
- `mix test test/orbital_dynamics/capabilities_test.exs` -> 6 passed.
- `mix test test/orbital_dynamics/timeline_test.exs:7359` -> 1 passed.
- Reviewer also ran
  `mix test test/orbital_dynamics/capabilities_test.exs test/orbital_dynamics/timeline_test.exs:7359`
  -> 7 passed, 124 excluded.
- Reviewer ran `mix orbital_dynamics.schema.lint --input study_results/activity_template_v1.json`
  -> pass.
- `git diff --check` -> pass.

Read-only review:
Sidecar `019e9c7e-e3c9-77b0-9f9d-abe44dcf49af` reported no findings.

Implementation commit:
Pending.

Last completed implementation commit:
`c58367c010f84e9c6e933bbbb0faeedc37904c50` pushed to `origin/main`.

Last ledger correction commit:
`c225b36595e00e919ff31ee4e47761ac559d4058` pushed to `origin/main`.

Next candidate:
Add a schema-backed or checked-in transition application example if the helper
surface warrants a durable fixture; otherwise continue deeper into typed
activity state/dependency validation.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

# Autonomous Product Loop Status

Current slice:
Add the first `activity_template.v1` executable schema contract.

Status:
Implemented, review-adjusted, and verified.

What changed:
- Added `activity_template.v1` to the executable schema registry and capability
  export.
- Added field-specific JSON Schema export for template ID, activity type,
  template version, validation level, required/optional/default field evidence,
  lifecycle defaults, resource hints, precondition hints, assumptions, and known
  limits.
- Added executable validation for stable template IDs, supported activity type,
  positive template version, `artifact_contract` validation level, string list
  fields, stale field counts, undeclared default fields, lifecycle defaults,
  resource hints, and precondition hints.
- Added a checked-in `study_results/activity_template_v1.json` fixture and
  exported `schemas/activity_template.v1.schema.json`.
- Refreshed generated schema bundle and validation/capability reference
  artifacts whose counts changed after adding the new contract.
- Updated focused schema and validation reference tests.

Verification:
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/orbital_dynamics/golden_artifact_test.exs:482 test/orbital_dynamics/validation_test.exs:48 test/orbital_dynamics/validation_test.exs:4042 test/orbital_dynamics/validation_test.exs:10515 test/orbital_dynamics/validation_test.exs:10599 test/orbital_dynamics/validation_test.exs:10690 test/mix/tasks/orbital_dynamics.schema.lint_test.exs:302`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Read-only review:
Found one must-fix validator/export alignment issue for optional
`activity_template.v1` fields. Fixed by making optional-field validation
presence-aware: omitted optional fields remain allowed, while present nulls and
wrong-typed optional strings/maps/lists/counts/nested hints now fail like the
exported JSON Schema. Added focused regression cases in
`test/orbital_dynamics/schema_test.exs`.

Full-suite note:
`mix test` currently fails outside this slice: 2981/3001 passed, 20 failed.
The residual failures are in the existing study manifest schema freshness check,
CandidateRefresh/contact-contention/contact-allocation validation paths, and
campaign-planner branch refresh validation paths. The known
`:propagator_exit` scenario-runner log appeared during the run and remains
expected noise when the suite result is otherwise interpreted.

Last completed implementation commit:
Pending this slice commit.

Last ledger correction commit:
Pending post-commit ledger correction.

Next candidate:
Wire `activity_template.v1` into a small public helper or add a typed template
example path that can later validate one transition path without mutating
schedules.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

# Autonomous Product Loop Status

Current slice:
Timeline transition helper provenance through transition application reports.

Status:
Implemented and focused verification passed. Safe
`Timeline.transition_activity_status/2` and
`Timeline.transition_activity_approval_status/2` outputs now carry
`transition_application_provenance` through normalized activity context,
selected activity rows, and transition application rows. Normalized activity
rows can re-enter transition application via `activity_id`/`activity_type`
aliases, while helper provenance only suppresses default lifecycle-change
review when it exactly matches a non-review status or approval transition and
the source is not preservation-sensitive. Locked/protected sources still select
the source row for review instead of recording the helper replacement.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/mission_activities.md`
- `lib/orbital_dynamics/timeline.ex`
- `schemas/study_manifest.v1.schema.json`
- `test/orbital_dynamics/timeline_test.exs`

Docs read:
- `docs/autonomous_work_guide.md`
- `.codex/status/autonomous_product_loop.md`
- `.codex/prompts/context_efficient_autonomous_product_loop.md`
- `docs/feature_set/capability_map/08_mission_activities_and_timelines.md`
- `docs/mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md`
- `docs/artifacts/field_families/mission_activities.md`

Tests run:
- `mix format lib/orbital_dynamics/timeline.ex test/orbital_dynamics/timeline_test.exs`
- `mix test test/orbital_dynamics/timeline_test.exs:6274`
- `mix test test/orbital_dynamics/timeline_test.exs:7388`
- `mix test test/orbital_dynamics/timeline_test.exs`
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json`
- `mix test test/orbital_dynamics/study/manifest_test.exs:726`
- `mix orbital_dynamics.schema.lint --all`

Full-suite status:
`mix test` was run after the slice and failed 19 tests. The known
`:propagator_exit` log appeared, and remaining failures were outside this slice:
stale validation fixture expected `model_limit_count` for
`fixture.artifact.timeline_activity_state.v1`, existing CampaignPlanner
source-report path/count expectations, and campaign/operator-review schema
failures around `lighting_confidence`/maneuver metadata. Focused timeline,
manifest-schema, and `study_results` schema-lint checks pass.

Docs/artifacts changed:
The mission-activities field-family doc now states that transition application
reports preserve helper provenance on selected activity context, selected rows,
and application rows. The checked-in study manifest schema was refreshed by the
manifest schema exporter after the activity context key became schema-visible.

Last commit:
Current slice code commit is `c131191` (`Preserve timeline transition helper provenance`).
`slice_reviewer` was unavailable because valid spawns hit the agent thread
limit, so review was performed manually with scoped diff/line checks. The
unrelated `.gitignore` scratch-ignore change remains unstaged.

Next candidate:
Re-read the guide/ledger/live worktree and continue with the highest-priority
current typed activity/timeline semantic gap, or address the stale
validation/CampaignPlanner fixture drift if the guide promotes verification
cleanup.

Blocked:
No.

Notes:
Treat current files as authoritative and do not revert unrelated changes.
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice.

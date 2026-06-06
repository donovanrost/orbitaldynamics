# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
V1 campaign resource-projection flow summary attachment.

Status:
Implemented, verified, committed, and pushed.

Product commit:
- `402a3692444dbbb697391da8bf9d4bee214b9790` pushed to `origin/main` for V1
  campaign resource-projection flow summary attachment.

Completed slice:
Attach the compact artifact-only `resource_projection_flow_summary.v1` to V1
`campaign_plan.v1` artifacts when a selected-activity
`resource_projection_report.v1` is present.

Why this slice:
ResourceProjection already performs deterministic storage/downlink roll-forward
over selected activities, but V1 campaign artifacts currently expose the full
resource projection report without the compact flow summary that adapter and
quality-gate queues can route by pressure, ignored activity, spacecraft, and
flow evidence.

Level 6 pillar:
Fleet-level resource/contact behavior and durable Cadence-facing integration
artifacts.

What changed:
- `CampaignPlanner.build/2` now attaches
  `resource_projection_flow_summary.v1` from the selected plan's own
  `resource_projection_report.v1`.
- Campaign operator-review and Cadence-import rows now include the compact
  flow-summary source alongside the full projected-resource source.
- `campaign_plan.v1` schema metadata, runtime validation, and checked-in schema
  exports declare and validate the nested summary artifact.
- Campaign tests prove selected-activity storage/downlink flow evidence,
  review/import routing, and readiness evidence counts carry the new summary.
- Capability-map docs describe the artifact-only campaign handoff boundary.

Verification:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:26` passed, 1 test.
- `mix test test/orbital_dynamics/campaign_planner_test.exs test/orbital_dynamics/schema_test.exs`
  passed, 777 tests.
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
  completed.
- `mix orbital_dynamics.schema.lint --all` passed across 127 artifacts with
  0 errors and 0 warnings.
- `git diff --check` passed.

Recently completed slices:
- `402a3692444dbbb697391da8bf9d4bee214b9790` pushed to `origin/main` for V1
  campaign resource-projection flow summary attachment.
- `375037e65ec3b1de1688cfc1f1273f5e49e4037b` pushed to `origin/main` for V1
  campaign readiness and quality-gate attachment.
- `625a2aac24b2ba5d0117efe649968357ea763cd9` pushed to `origin/main` for
  subsystem-state required-state precondition rows.
- `61315e1a0e0a2b2ca43c70d420f852ea2bf60c36` pushed to `origin/main` for
  artifact-only subsystem-state hints on `activity_template.v1`.
- `676e536c74ffdb1a03ac276f16ef8874df121635` pushed to `origin/main` for
  validation-reference fixture coverage for `resource_projection_flow_summary.v1`.

Next candidate:
Select the next Level 6 slice from the live checkout after committing and
pushing the current slice.

Blocked:
No.

Notes:
- `.gitignore` still has an unrelated pre-existing local scratch-ignore change
  and is not part of this slice.

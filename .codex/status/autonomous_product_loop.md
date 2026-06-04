# Autonomous Product Loop Status

Current slice:
Validation reference fixture drift for current typed timeline/capability catalog outputs.

Status:
Implemented and verified. The validation capability catalog now includes
`timeline_activity_precondition_summary` in the candidate-refresh source-report
input order, and its expected candidate-refresh input/source-report/helper
counts match the current public catalog. The timeline activity state validation
fixture now expects five model limits, matching the current checked-in artifact
surface. The curated reference fixture report was regenerated from the current
embedded observations and reports all 144 fixtures passing.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/validation.ex`
- `study_results/validation_reference_fixtures.json`
- `test/orbital_dynamics/validation_test.exs`

Docs read:
- `docs/autonomous_work_guide.md`
- `.codex/prompts/context_efficient_autonomous_product_loop.md`
- `.codex/status/autonomous_product_loop.md`
- `docs/feature_set/capability_map/18_validation_and_verification.md`
- `docs/mission_planning/high_fidelity/11_verification_and_validation.md`
- `docs/artifacts/compatibility_checks.md`

Tests run:
- `mix format lib/orbital_dynamics/validation.ex test/orbital_dynamics/validation_test.exs`
- `mix test test/orbital_dynamics/validation_test.exs:3754`
- `mix test test/orbital_dynamics/validation_test.exs:6779`
- `mix test test/orbital_dynamics/validation_test.exs:10291`
- `mix test test/orbital_dynamics/validation_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs:10678`
- `mix orbital_dynamics.schema.lint --all`
- `mix test`

Full-suite status:
`mix test` now reports `2802/2817 passed`; 15 failures remain. The stale
validation fixture/schema failure from the prior ledger is resolved. Remaining
failures are outside this slice: malformed maneuver optional metadata still
leaks `source_recommendation.maneuver_success_factor` outside the schema range,
multiple CampaignPlanner/operator-review paths still emit invalid
`lighting_confidence` values, several CampaignPlanner result-artifact
source-report path/count expectations still need reconciliation, and the
checked-in V3 campaign run task still fails because its generated campaign
artifact does not validate. The known `:propagator_exit` log still appears
during the suite.

Review:
`slice_reviewer` was unavailable because valid spawns hit the agent thread
limit. Manual scoped review passed: changed assertions match the capability
catalog fixture updates, the generated reference fixture report is internally
all-pass, and residual full-suite failures remain outside this slice.

Next candidate:
Re-read the guide/ledger/live worktree and choose the next guide-backed slice.
The remaining full-suite failures point to maneuver optional metadata gating,
campaign/operator-review `lighting_confidence` normalization, and
CampaignPlanner source-report path/count expectation drift.

Blocked:
No.

Notes:
Treat current files as authoritative and do not revert unrelated changes.
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice.

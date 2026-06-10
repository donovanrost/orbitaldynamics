# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Schema-validation error pressure affects V3 recommendation selection.

Status:
Implemented, reviewed, verified, and published locally.
Behavior commit: `248aa8c` Block schema validation error recommendations by default.

Files changed:
- V3 campaign strategy default approval policy:
  `lib/orbital_dynamics/campaign_planner.ex`
- Shared approval fallback matching: `lib/orbital_dynamics/policy.ex`
- Focused V3 recommendation regression:
  `test/orbital_dynamics/campaign_planner_test.exs`
- Direct shared-policy regression:
  `test/orbital_dynamics/policy_test.exs`
- Regenerated checked-in repair fixture:
  `study_results/campaign_repair_readiness_source_handoff_v2.json`
- Ledger: `.codex/status/autonomous_product_loop.md`

Tests/checks run:
- `mix test test/orbital_dynamics/policy_test.exs`
- `mix test test/orbital_dynamics/campaign_planner_test.exs:9617`
- `mix test test/orbital_dynamics/campaign_planner_test.exs`
- Initial `mix test` confirmed one expected checked-in fixture drift:
  `3340/3341` passed.
- `mix test test/orbital_dynamics/schema_test.exs:16173`
- `mix orbital_dynamics.schema.lint --input study_results/campaign_repair_readiness_source_handoff_v2.json --contract campaign_repair.v2`
- Intermediate `mix test`: `3341 passed`.
- Final `mix test` after direct policy regression: `3342 passed`.
- `git diff --check`

Behavior changed:
Schema-validation fail/error pressure now affects V3 branch recommendation
selection by default before review/import handoff. The V3 default approval
policy includes the semantic `schema_validation_blocked` alias, and the shared
fallback matcher treats failed schema-validation status, error severity,
positive error counts, or branch-local schema-error pressure as
`blocked_by_policy`. Warning-only schema-validation pressure remains selectable
with operator review.

Level 6 pillar advanced:
Planner-visible schema-validation compatibility gates.

Remaining maturity gaps:
- Use selected contact/readiness pressure in additional planner-visible
  selection or scoring paths where live code still leaves it only review-visible.
- Add additional stale-but-plausible resource/contact fixtures only after
  verifying the target family is not already covered.
- Continue reassessing from live code and Level 6 docs between slices.

Last behavior commit:
`248aa8c` Block schema validation error recommendations by default.

Last docs commit:
`a4b6dca` Document operational readiness fixture coverage.

Next candidate:
After this slice, reassess from current code and roadmap. Good next areas are
refresh-pressure blocking or a missing challenge fixture with exact
regeneration evidence.

Blocked:
Not blocked.

Notes:
- Selection note: live search found `schema_validation_report.v1` errors and
  warnings derive `schema_validation_pressure` events and feed scored branch
  risk terms, but the V3 default approval policy has no semantic blocked alias
  for failing/error schema-validation evidence. Selected slice:
  schema-validation error pressure affects V3 recommendation selection. Why
  this slice: a branch carrying schema-validation failure or error evidence
  should stop an otherwise high-value recommendation by default before
  review/import handoff, while warning-only schema-validation pressure should
  remain selectable with operator review. Level 6 pillar: schema-validation and
  compatibility gates become planner-visible, not only artifact-visible. Docs
  to read:
  `docs/feature_set/capability_map/18_validation_and_verification.md`,
  `docs/mission_planning/high_fidelity/11_verification_and_validation.md`,
  `docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md`,
  and `docs/artifacts/field_families/candidate_refresh_artifact.md`. Likely
  files: `lib/orbital_dynamics/campaign_planner.ex`,
  `lib/orbital_dynamics/policy.ex`,
  `test/orbital_dynamics/campaign_planner_test.exs`, possible fixture drift,
  and this ledger. Likely tests: focused new campaign planner regression,
  `mix test test/orbital_dynamics/policy_test.exs`, `mix test
  test/orbital_dynamics/campaign_planner_test.exs`, schema fixture/lint if
  needed, full `mix test`, and `git diff --check`. Definition of done: a
  high-value branch with schema-validation fail/error pressure is classified
  `blocked_by_policy` by default and skipped when a selectable branch exists,
  ordinary warning-only schema-validation pressure remains reviewable/selectable
  unless configured otherwise, focused and full tests pass, parent review is
  recorded, and behavior plus ledger commits are pushed.
- Reviewer notes: `slice_reviewer` found the implementation and fixture drift
  consistent with the intended behavior, flagged the ledger as needing final
  completion details, and recommended a direct `Policy` regression for the
  shared matcher. Added the policy regression before final verification.

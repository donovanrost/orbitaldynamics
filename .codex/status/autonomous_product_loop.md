# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Blocked validation safety-case pressure affects V3 recommendation selection.

Status:
Implemented, parent-reviewed, verified, and published locally.
Behavior commit: `21662ab`.

Files changed:
- V3 campaign strategy default approval policy:
  `lib/orbital_dynamics/campaign_planner.ex`
- Shared approval fallback matching: `lib/orbital_dynamics/policy.ex`
- Focused V3 recommendation regression:
  `test/orbital_dynamics/campaign_planner_test.exs`
- Regenerated checked-in repair fixture:
  `study_results/campaign_repair_readiness_source_handoff_v2.json`
- Ledger: `.codex/status/autonomous_product_loop.md`

Tests/checks run:
- `mix test test/orbital_dynamics/policy_test.exs`
- `mix test test/orbital_dynamics/campaign_planner_test.exs:9475`
- `mix test test/orbital_dynamics/campaign_planner_test.exs`
- Initial `mix test` confirmed one expected checked-in fixture drift:
  `3339/3340` passed.
- `mix test test/orbital_dynamics/schema_test.exs:16173`
- `mix orbital_dynamics.schema.lint --input study_results/campaign_repair_readiness_source_handoff_v2.json --contract campaign_repair.v2`
- Final `mix test`: `3340 passed`.
- `git diff --check`

Behavior changed:
Blocked validation safety-case pressure now affects V3 branch recommendation
selection by default before review/import handoff. The V3 default approval
policy includes the semantic `validation_safety_case_blocked` alias, and the
shared fallback matcher treats blocked safety-case/evidence status, blocked
evidence counts, schema error counts, model/quality blocked counts,
branch-local blocking pressure, or the blocked safety-case operator action as
`blocked_by_policy`. Ordinary review-required safety-case pressure remains
selectable with operator review.

Level 6 pillar advanced:
Planner-visible validation safety-case gates.

Remaining maturity gaps:
- Use selected contact/readiness pressure in additional planner-visible
  selection or scoring paths where live code still leaves it only review-visible.
- Add additional stale-but-plausible resource/contact fixtures only after
  verifying the target family is not already covered.
- Continue reassessing from live code and Level 6 docs between slices.

Last behavior commit:
`21662ab` Block validation safety case recommendations by default.

Last docs commit:
`a4b6dca` Document operational readiness fixture coverage.

Next candidate:
After this slice, reassess from current code and roadmap. Good next areas are
schema-validation blocked/error pressure, refresh-pressure blocking, or a
missing challenge fixture with exact regeneration evidence.

Blocked:
Not blocked.

Notes:
- Selection note: live search found `validation_safety_case_summary.v1`
  evidence that is review-required or blocked derives
  `validation_safety_case_pressure` events and feeds scored branch risk terms,
  but the V3 default approval policy has no semantic blocked alias for blocked
  safety-case evidence. Selected slice: blocked validation safety-case pressure
  affects V3 recommendation selection. Why this slice: a safety-case row with
  blocked evidence, blocked evidence counts, schema errors, or the blocked
  safety-case operator action should stop an otherwise high-value branch by
  default before validation/import handoff, while ordinary safety-case review
  pressure should remain selectable with operator review. Level 6 pillar:
  validation safety-case evidence becomes planner-visible, not only
  artifact-visible. Docs to read:
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
  high-value branch with blocked validation safety-case pressure is classified
  `blocked_by_policy` by default and skipped when a selectable branch exists,
  ordinary validation safety-case review pressure remains reviewable/selectable
  unless configured otherwise, focused and full tests pass, parent review is
  recorded, and behavior plus ledger commits are pushed.
- Parent review notes: implementation kept the default policy alias semantic
  instead of changing raw pressure event types. The matcher blocks explicit
  safety-case blocked evidence through status fields, blocked/schema/model/
  quality counts, branch-local blocking pressure, or the blocked operator
  action. The regression proves a high-value blocked safety-case branch is
  skipped in favor of baseline while a high-value review-required safety-case
  branch remains recommended with `operator_review_required`. The checked-in
  repair readiness fixture was regenerated through
  `OrbitalDynamics.campaign_repair/1` because it stores the default fallback
  policy list.

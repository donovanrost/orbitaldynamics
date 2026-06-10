# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
V2 repair honors supplied candidate-refresh contact-allocation outcomes during
replacement selection.

Status:
Implemented, reviewer-cleared, and locally verified; publish pending.

Files changed:
- V2 repair candidate filtering:
  `lib/orbital_dynamics/campaign_planner.ex`
- Focused repair regression:
  `test/orbital_dynamics/campaign_planner_test.exs`
- Ledger:
  `.codex/status/autonomous_product_loop.md`

Tests/checks run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:4644`
- `mix test test/orbital_dynamics/campaign_planner_test.exs:4122 test/orbital_dynamics/campaign_planner_test.exs:4424 test/orbital_dynamics/campaign_planner_test.exs:4519 test/orbital_dynamics/campaign_planner_test.exs:4644 test/orbital_dynamics/campaign_planner_test.exs:8688 test/orbital_dynamics/campaign_planner_test.exs:8753`
- `mix compile --warnings-as-errors`
- `git diff --check`

Level 6 pillar advanced:
Refreshed candidates from current mission state and fleet-level contact/station
behavior, by making V2 repair exclude contacts that the same supplied
candidate-refresh allocation report marks deferred, blocked, or policy-blocked.

Slice selection note:
Selected slice: make V2 repair honor supplied `candidate_refresh.v1`
`contact_allocation_report.rows` during replacement selection.

Why this slice: supplied filter reports now affect repair candidate selection,
but supplied allocation reports can still say a contact was deferred or blocked
while leaving that contact selectable. The allocation outcome should be a
candidate usability input, not just review evidence.

Current evidence gap:
Supplied contact-allocation outcomes are review-visible but not
candidate-selection-visible in V2 repair.

Slice result:
- V2 repair now removes contacts marked `deferred`, `blocked`, or
  `policy_blocked` in a supplied candidate refresh's
  `contact_allocation_report.rows` before replacement selection.
- Added a regression proving higher-score deferred, blocked, and policy-blocked
  contacts are not selected, while the source allocation report still feeds
  operator review and Cadence import rows.
- Neighboring supplied-refresh, filter, and generated station-suppression tests
  remain green.

Last completed slice:
V2 repair honors supplied candidate-refresh contact suppressions during
replacement selection.

Last pushed commits:
- Product/ledger: `b07fbec` Honor refresh resource suppressions in repair
- Ledger correction: `2c88d1e` Update autonomous loop ledger after repair
  publish
- Product/ledger: `5fba8f0` Honor refresh contact suppressions in repair

Review/publish queue:
- Reviewer sidecar cleared the supplied refresh contact-allocation repair slice
  after blocked and policy-blocked regression coverage was added.
- Publisher sidecar pending.

Remaining maturity gaps:
- Continue converting replayed resource/contact/readiness pressure into
  planner-visible branch scoring or candidate-selection effects where live code
  still routes evidence only to review/import.
- Add exact challenge or compatibility fixtures for stale-but-plausible
  readiness/resource/contact inputs where current behavior is only protected by
  focused strategy assertions.
- Keep golden and validation-reference fixtures exact-regenerable whenever
  planner pressure families change public artifact shape.

Next candidate:
Reassess remaining candidate-selection or compatibility gaps from live evidence.

Blocked:
Not blocked.

Notes:
- Reviewer found no publish blocker and asked to pin `blocked` and
  `policy_blocked` repair-path coverage; the focused regression now covers all
  three unusable allocation statuses.
- Reviewer found no publish blocker and asked to pin bare-`id` contact-filter
  rows; the focused regression now covers both `contact_id` and bare `id`.
- Focused CampaignPlanner tests still emit existing unrelated `0.0`
  pattern-match warnings from another test; selected tests exit green.
- Reviewer sidecar: `019eb084-5d80-7d00-b3b5-3c2e5a1cba9c`.
- Publisher sidecar: pending.

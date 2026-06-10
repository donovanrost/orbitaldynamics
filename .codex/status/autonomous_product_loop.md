# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Opt-in V1 campaign contact candidate generation from ground-station access
windows.

Status:
Implemented, parent-reviewed, locally verified, and published locally.
Behavior commit: `4a78f29`.

Files changed:
- V1 campaign planner:
  `lib/orbital_dynamics/campaign_planner.ex`
- Focused planner coverage:
  `test/orbital_dynamics/campaign_planner_test.exs`
- V1 generation docs:
  `docs/mission_planning/leo_campaign_planner/01_v1_campaign_plan_generation.md`
- Ledger:
  `.codex/status/autonomous_product_loop.md`

Tests/checks run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:1893`
- `mix test test/orbital_dynamics/campaign_planner_test.exs` (714 passed)
- `mix test` (3326 passed)
- `mix format lib/orbital_dynamics/campaign_planner.ex test/orbital_dynamics/campaign_planner_test.exs`
- `git diff --check`

Behavior changed:
V1 campaign planning still derives a downlink candidate from each
ground-station access window by default. When
`campaign.scoring_policy.contact_activity_types` is supplied, the planner can
now deterministically derive downlink, command, tracking, and health-check
candidate activities from those windows. Downlink candidates keep throughput and
`proposed_contact.v1` surfaces; command/tracking/health-check candidates remain
contact-intent/report-visible without pretending to be downlink throughput
products.

Level 6 pillar advanced:
Fleet-level contact/allocation behavior and richer reproducible V1 campaign
branch inputs: ground-station windows can now expose operational command,
tracking, and health-check candidate shapes through the public V1 planner
artifact without changing default checked-in campaign output.

Remaining maturity gaps:
- Add dedicated command-window candidate derivation when command opportunities
  should come from command-specific source windows rather than generic
  ground-station access.
- Continue converting artifact evidence into planner-visible selection,
  ranking, or branch-scoring effects where live code still leaves it passive.
- Reassess the guide and current code for the next verified Level 6 gap before
  editing; do not rely on stale ledger candidates.

Last behavior commit:
`4a78f29` Add opt-in campaign contact candidates.

Next candidate:
Recalibrate from live code and Level 6 docs. The timeline integrity/publication
path is already planner-visible in branch scoring; choose the next slice from a
fresh verified gap, not from stale assumptions.

Blocked:
Not blocked.

Notes:
- Selection note: the current V1 campaign generator only emitted downlink
  candidates from ground-station access windows by default, while Level 6 LEO
  campaign completeness calls for richer operational activity coverage. This
  slice kept defaults stable and added an explicit policy knob for richer
  contact candidate generation.
- The read-only mapper confirmed timeline integrity/publication replay evidence
  already feeds V2/V3 branch scoring and ranking, so no scoring-path edit was
  made for that candidate.
- Full-suite pass still emits the existing campaign-planner `0.0` pattern-match
  warnings; no test failures remain in this slice.

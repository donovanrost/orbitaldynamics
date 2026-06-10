# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Validate V2 repair timeline-protection metadata against row-derived evidence.

Status:
Implemented, parent-reviewed, locally verified, and published locally.
Behavior commit: `ab22ad8`.

Files changed:
- Executable schema validation:
  `lib/orbital_dynamics/schema.ex`
- Focused regression:
  `test/orbital_dynamics/campaign_planner_test.exs`
- Schema exports:
  `schemas/orbital_dynamics.schema_bundle.v1.json`
  `schemas/resource_filter_summary.v1.schema.json`
- Golden fixture:
  `study_results/campaign_repair_readiness_source_handoff_v2.json`
- Capability and compatibility docs:
  `docs/feature_set/capability_map/08_mission_activities/integrity-rejection-and-preservation-reports.md`
  `docs/artifacts/compatibility_checks.md`
- Ledger:
  `.codex/status/autonomous_product_loop.md`

Tests/checks run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:3065`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix format --check-formatted lib/orbital_dynamics/schema.ex`
- `mix format --check-formatted test/orbital_dynamics/campaign_planner_test.exs`
  (fails only on pre-existing distant formatting drift at lines near 29035,
  39500, and 50040)
- `git diff --check`

Behavior changed:
`campaign_repair.v2` executable validation now recomputes
`repair_metadata.timeline_protection` counts and activity-ID sets from repair
activities and deltas, rejecting stale metadata when locked, approved, or
executed timeline evidence changes. The regression mutates
`changed_locked_or_approved_count` and asserts schema validation rejects the
stale value.

Docs/artifacts changed:
The V2 repair readiness source-handoff fixture was regenerated from the current
public repair facade, and schema exports were refreshed. Capability and
compatibility docs now describe the row-derived timeline-protection validation
boundary.

Level 6 pillar advanced:
Durable approval-aware automation boundaries: V2 repair artifacts can no longer
carry schema-valid but stale timeline-protection summaries that would hide
locked, approved, or executed evidence from downstream review/import gates.

Remaining maturity gaps:
- Continue converting artifact evidence into planner-visible selection,
  ranking, or branch-scoring effects where live code still leaves it passive.
- Add exact compatibility or stale-input challenge coverage only after verifying
  the target family is not already covered by current fixtures.
- Reassess the guide and current code for the next verified Level 6 gap before
  editing; do not rely on stale ledger candidates.

Last behavior commit:
`ab22ad8` Validate repair timeline protection metadata.

Next candidate:
Recalibrate from live code. Resource/communications evidence and branch-scoring
challenge fixtures remain likely high-value areas, but verify before editing.

Blocked:
Not blocked.

Notes:
- Selection note: live mapping showed timeline integrity, publication,
  dependency-impact, lifecycle, precondition, preservation, and transition
  pressure already wired into branch scoring, so the slice pivoted to a stale
  V2 repair timeline-protection challenge under the same Level 6 pillar.
- Existing warnings during the focused planner test are the known `0.0` pattern
  warnings in a different test.

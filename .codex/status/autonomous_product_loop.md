# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Make relay data-path summaries branch-visible as link-capacity pressure.

Status:
Selected; implementation pending.
`relay_data_path_summary.v1` handoffs are CandidateRefresh-visible as compact
link-capacity provenance, but CampaignPlanner currently derives branch pressure
from link-capacity reports/summaries only.

Slice-selection note:
- Selected slice: derive branch-local link-capacity pressure from
  `relay_data_path_summary.v1` handoffs.
- Why this slice: relay summaries are the compact Cadence-facing contract for
  relay/direct downlink route status; CandidateRefresh already replays route,
  custody, latency, risk, station, contact, and trust-boundary evidence, but
  strategy branch scoring still ignores those compact summaries.
- Level 6 pillar: fleet-level communications planning, artifact-only relay
  handoffs, and reproducible branch trees from compact operational evidence.
- Current evidence gap: CampaignPlanner source-report plumbing carries
  `source_relay_data_path_summary` and `relay_data_path_summary`, but derived
  link-capacity pressure reads only link-capacity report/summary inputs.
- Docs read:
  `docs/autonomous_work_guide.md`,
  `.codex/prompts/long_running_context_efficient_product_loop.md`,
  `docs/feature_set/capability_map/07_ground_network_and_communications_planning.md`,
  `docs/artifacts/field_families/candidate_refresh_artifact.md`.
- Likely files: `lib/orbital_dynamics/campaign_planner.ex`,
  `test/orbital_dynamics/campaign_planner_test.exs`,
  `.codex/status/autonomous_product_loop.md`.
- Definition of done: direct/canonical/result-artifact relay summaries create
  branch-local link-capacity pressure retaining source paths, trust boundaries,
  route IDs, route/status counts, ground-station and ground-downlink contact
  evidence, relay assumptions, and no-scheduling/no-provider-write boundaries;
  events affect risk/scoring/comparison without mutating schedules or granting
  operator/provider authority; focused tests, compile, and whitespace checks
  pass.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `test/orbital_dynamics/campaign_planner_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/campaign_planner.ex test/orbital_dynamics/campaign_planner_test.exs .codex/status/autonomous_product_loop.md`
- `mix test test/orbital_dynamics/campaign_planner_test.exs:42119` (1 passed, 676 excluded)
- `mix test test/orbital_dynamics/campaign_planner_test.exs:42119 test/orbital_dynamics/candidate_refresh_test.exs:30035` (2 passed, 1416 excluded)
- `mix compile --warnings-as-errors`
- `git diff --check`

Docs/artifacts changed:
- None expected; this is a planner/test slice for an existing readiness summary
  artifact.

Local review:
- Direct, canonical, and result-artifact
  `operational_readiness_gate_summary.v1` inputs now feed derived
  operational-readiness pressure.
- Summary-derived events carry readiness/import/status evidence, gate counts,
  status/classification maps, gate ID routing, trust boundaries, and
  no-authority assumptions.
- Source paths distinguish direct, canonical, and wrapped result-artifact
  summary rows.
- Branch comparison rows expose readiness levels, import classifications,
  statuses, gate statuses/classifications, and review/analysis/blocked/non-passed
  gate IDs.

Level 6 pillar advanced:
Compact Cadence-facing readiness summaries now affect V2/V3 branch scoring and
comparison without reopening full readiness reports or granting import/operator
authority.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last commit:
`aa4cb47` Derive readiness gate summary pressure.

Next candidate:
Reinspect live code for the next planner-visible resource/contact evidence gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `aa4cb47` derived operational-readiness gate-summary pressure branches.
- `fe0ac70` derived timeline preservation report/status pressure branches.
- `f75382e` derived timeline activity-precondition summary pressure branches.
- `e22b772` derived timeline lifecycle-state and activity lifecycle-state
  pressure branches.
- `157220f` added contradictory reservation/contact-allocation challenge coverage.
- `a0d04e3` derived import-readiness quality-gate summary pressure.
- `b72180e` derived schema-validation quality-gate summary pressure.
- `fcd9a35` derived operator-training quality-gate summary pressure.
- `9bfadda` derived unavailable-resource quality-gate summary pressure.
- `13e927a` derived quality-gate summary pressure branches.
- `482bcf2` derived counteroffer plan-impact pressure branches.
- `1b5bbb8` derived provider reservation request pressure branches.
- `4796e0e` rejected stale lifecycle-state protection evidence.
- `9fdfb3a` derived timeline publication summary pressure branches.
- `9c45b20` derived timeline dependency-impact summary pressure branches.
- `b9fed8e` derived timeline-integrity report pressure branches.
- `7ebe694` derived prior-plan contact-allocation summary pressure branches.
- `a97d1ca` derived mission-state contact-allocation summary pressure branches.
- `27ab76f` added hold import-readiness direction routing.
- `cb62212` flattened reservation-conflict direction handoffs.
- `cd331cf` flattened station-pressure direction handoffs.
- `0c7c0e2` flattened capacity-pack direction handoffs.

Blocked:
No.

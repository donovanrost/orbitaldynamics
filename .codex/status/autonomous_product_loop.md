# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Make relay data-path summaries branch-visible as link-capacity pressure.

Status:
Implemented and parent-verified.
`relay_data_path_summary.v1` handoffs now derive planner-visible
link-capacity pressure with relay-route, custody, latency, risk, station,
ground-downlink contact, trust-boundary, and artifact-only no-authority
evidence.

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
- `mix test test/orbital_dynamics/campaign_planner_test.exs:26837` (1 passed, 677 excluded)
- `mix test test/orbital_dynamics/campaign_planner_test.exs:26837 test/orbital_dynamics/candidate_refresh_test.exs:11844` (2 passed, 1417 excluded)
- `mix compile --warnings-as-errors`
- `git diff --check`

Docs/artifacts changed:
- None expected; this is a planner/test slice for an existing relay data-path
  summary artifact.

Local review:
- Direct, canonical, and result-artifact
  `relay_data_path_summary.v1` inputs now feed derived link-capacity pressure.
- Summary-derived relay pressure events carry route IDs, source/relay
  spacecraft IDs, custody/latency/risk statuses and counts, ground-station and
  ground-downlink contact evidence, trust boundaries, and no-scheduling /
  no-provider-write assumptions.
- Strategy mission-state normalization now preserves direct relay summary fields
  alongside existing result-artifact wrappers.
- Branch comparison rows expose `relay_data_path_pressure` risk types and score
  penalties without inventing downlink volume demand or mutating schedules.

Level 6 pillar advanced:
Compact Cadence-facing relay route summaries now affect V2/V3 branch scoring and
comparison without reopening full relay reports, mutating schedules, writing
provider reservations, or granting operator/provider authority.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last commit:
`3920603` Derive relay data path pressure.

Next candidate:
Reinspect live code for the next planner-visible resource/contact evidence gap.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `3920603` derived relay data-path summary pressure branches.
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

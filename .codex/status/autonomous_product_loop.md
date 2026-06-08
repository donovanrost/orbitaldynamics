# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Expose reservation-conflict identities in branch comparison rows.

Status:
Published locally in product commit `ae950a5`; handoff commit pending.

Slice-selection note:
- Selected slice: add branch-comparison fields for contact/reservation IDs whose
  station-reservation match status indicates an overlap, conflict, unmatched, or
  owner-mismatch condition.
- Why this slice: the roadmap prioritizes making resource/contact pressure
  directly visible in branch score explanations; generic reservation IDs and
  match statuses are present, but conflict-specific routing is not separated for
  adapter-facing review.
- Level 6 pillar: fleet-level resource/contact behavior and reproducible V3
  branch trees with explainable score terms and deltas.
- Current evidence gap: `contact_allocation_reservation_conflict_summary.v1`
  already flows into V3 pressure branches, but branch comparison rows expose
  only generic `branch_station_reservation_*` fields, making conflict contact
  routing less explicit than CandidateRefresh replay and quality-gate routing.
- Docs read:
  `docs/autonomous_work_guide.md`,
  `.codex/prompts/long_running_context_efficient_product_loop.md`,
  `docs/feature_set/recommended_roadmap.md`,
  `docs/feature_set/capability_map/07_ground_network_and_communications_planning.md`,
  `docs/artifacts/field_families/candidate_refresh_artifact.md`.
- Likely files: `lib/orbital_dynamics/campaign_planner.ex`,
  `lib/orbital_dynamics/schema.ex`,
  `test/orbital_dynamics/campaign_planner_test.exs`,
  `test/orbital_dynamics/schema_test.exs`,
  `schemas/*.schema.json`,
  `.codex/status/autonomous_product_loop.md`.
- Definition of done: branch comparison rows expose conflict contact IDs,
  reservation IDs, and match statuses for reservation-conflict pressure; schema
  validation/export surfaces the optional fields; focused planner/schema tests,
  schema export/lint, compile, and whitespace checks pass.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/schema.ex`
- `test/orbital_dynamics/campaign_planner_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- `schemas/*.schema.json` branch-comparison export dependents
- `schemas/orbital_dynamics.schema_bundle.v1.json`

Tests run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:40973 test/orbital_dynamics/schema_test.exs:24696`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix orbital_dynamics.schema.lint --all`
- `mix compile --warnings-as-errors`
- `git diff --check`

Docs/artifacts changed:
- Checked-in schema exports refreshed for `branch_comparison_report.v1` and
  top-level exports that embed the updated branch-comparison row shape.

Local review:
Branch comparison rows now derive conflict-specific contact IDs, reservation
IDs, and match statuses from events whose station-reservation match status is
not matched/owned. Generic reservation fields remain unchanged, while conflict
fields stay absent for matched owner rows. Focused planner coverage asserts the
fields for a reservation-conflict summary branch, and schema coverage pins the
new optional arrays. Read-only reviewer `Boyle` found that mixed matched plus
conflict status aliases could leak matched values into the conflict-status
field; the collector now filters individual status values, and the focused test
adds a matched alias regression.

Level 6 pillar advanced:
Planner-visible resource/contact reservation-conflict explanation.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last commit:
`ae950a5` Expose reservation conflict branch comparison fields.

Next candidate:
After this slice, inspect whether resource/contact pressure should influence
candidate ranking more directly or whether another compatibility fixture is
higher-value.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `eae9483` derived operational-readiness gate pressure classification from
  row-local status.
- `110ba8e` hardened timeline-preservation pressure status against stale
  aggregate report status.
- `df963da` exposed contact-allocation pressure status in branch comparison rows.
- `d3cd30f` derived prior-plan readiness and quality-gate pressure branches.
- `4904a47` derived station-reservation review summary pressure branches.
- `3920603` derived relay data-path summary pressure branches.
- Earlier published slices covered schema-validation, operator-training,
  unavailable-resource, provider-counteroffer/reservation, lifecycle,
  publication/dependency/integrity, contact-allocation, and direction-routing
  pressure paths.

Blocked:
No.

# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Score candidate-diff replay pressure from candidate-source reports.

Status:
Completed; product commit created.

Files changed:
- Planner: `lib/orbital_dynamics/campaign_planner.ex`
- Focused planner test: `test/orbital_dynamics/campaign_planner_test.exs`
- Golden artifact test: `test/orbital_dynamics/golden_artifact_test.exs`
- Golden fixture: `study_results/leo_constellation_campaign_strategy_v3.json`
- Ledger: `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix test test/orbital_dynamics/campaign_planner_test.exs:38039`
- `mix test test/orbital_dynamics/golden_artifact_test.exs`
- `mix compile --warnings-as-errors`
- Decoded equality check between checked-in
  `study_results/leo_constellation_campaign_strategy_v3.json` and a fresh
  public-facade regeneration.
- `git diff --check`

Docs/artifacts changed:
- Regenerated `study_results/leo_constellation_campaign_strategy_v3.json`
  through `OrbitalDynamics.campaign_strategy_from_file!/1`.

Level 6 pillar advanced:
Planner-visible realized-feedback provenance and branch-local scoring for
artifact-only candidate-source replay.

Slice selection note:
Selected slice: Score branch-local candidate-diff replay pressure from
candidate-source `candidate_diff_report.v1` summaries.

Why this slice: `CandidateRefresh.candidate_diff_replay_summary/1` preserves
retained/new/invalidated counts, diff/invalidated/semantic-change reasons,
changed fields, candidate and station routing, trust boundaries, and
artifact-only assumptions, but the planner does not read that candidate-source
replay summary into branch risk scoring or branch-comparison rows.

Level 6 pillar: Refreshed candidates from current mission state and realized
feedback with explainable score terms and Cadence-facing artifact-only review
boundaries.

Current evidence gap: Candidate-diff replay evidence is preserved in
candidate-refresh summaries but is not planner-visible as a dedicated branch
score term or comparison-row evidence family.

Docs read: `docs/artifacts/field_families/candidate_refresh_artifact.md`.

Likely files: `lib/orbital_dynamics/campaign_planner.ex`;
`test/orbital_dynamics/campaign_planner_test.exs`;
`test/orbital_dynamics/golden_artifact_test.exs`;
`study_results/leo_constellation_campaign_strategy_v3.json`;
`.codex/status/autonomous_product_loop.md`.

Likely tests: focused candidate-diff candidate-source replay campaign-planner
test; `test/orbital_dynamics/golden_artifact_test.exs`;
`mix compile --warnings-as-errors`; fixture decoded equality; `git diff --check`.

Slice result:
- Branch-generated candidate sources now read
  `CandidateRefresh.candidate_diff_replay_summary/1` into a dedicated
  `candidate_diff_pressure` risk when branch-local diff pressure exists.
- The risk preserves source report counts, paths, retained/new/invalidated
  counts, diff/invalidated/semantic-change reasons, changed fields, candidate
  and station routing, trust boundaries, and artifact-only assumptions.
- Candidate-diff pressure now has an explicit `candidate_diff_pressure_penalty`
  score term and is excluded from generic risk double counting.
- Branch-comparison rows now expose candidate-diff source paths, diff reasons,
  invalidated reasons, semantic-change reasons, changed fields, candidate IDs,
  ground-station IDs, and trust boundaries.
- Focused tests now assert the risk, score term, and branch-comparison fields.
- The checked-in strategy fixture includes the new score term across all
  branches and the updated review/import counts.

Last completed slice:
Scored candidate-diff replay pressure from candidate-source reports.

Last commit:
- Product: `1e6021a` Score candidate-diff replay pressure
- Ledger: pending

Remaining maturity gaps:
- Continue making existing review evidence planner-visible through candidate
  selection, branch scoring, compatibility checks, and challenge fixtures.
- Continue closing queue-2/queue-3 handoff completeness gaps for branch evidence
  families not present in checked-in strategy artifacts.

Next candidate:
After this slice, reassess timeline-diff and timeline-activity-state replay for
source-report evidence that is preserved but not yet scored or
comparison-visible.

Blocked:
Not blocked.

Notes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.
- Sidecar delegation is unavailable in this runtime; parent used the same
  bounded review and mechanical publish scope.

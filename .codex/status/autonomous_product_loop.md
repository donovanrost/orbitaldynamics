# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Score candidate-refresh diff pressure in V2 repair.

Status:
Implemented and verified; publish pending.

Why this slice:
V2 preserves `candidate_diff_report.v1` and emits review/import rows for
invalidated, reviewable-new, and semantically changed candidates, but its repair
score currently ignores that source pressure. V3 already derives one aggregate
`candidate_diff_pressure` risk when the shared replay summary finds new,
invalidated, semantic-change, candidate-routing, or station-routing evidence.

Level 6 pillar:
Refreshed candidates from current mission state plus reproducible, explainable
V2/V3 branch scores.

Behavior/evidence added:
- Pass the canonical candidate-refresh diff report into V2 repair scoring.
- Reuse `CandidateRefresh.candidate_diff_replay_summary/1` as the pressure
  classifier so V2 and V3 keep the same evidence semantics.
- Emit one `candidate_diff_pressure_penalty` using normalized `risk_weight` when
  `branch_local_diff_pressure` is true; omit the term for empty or absent
  reports.
- Keep `score`, `score_terms`, `score_term_report`, operator review, Cadence
  import, and artifact schemas aligned.
- Regenerate the checked-in V3 strategy artifact: 25 branch-local repairs now
  expose the nested V2 term, while zero strategic branches have a nonzero
  strategic candidate-diff term and branch ranking is unchanged.

Verification:
- Focused source-report suite: 4 passed; regenerated golden suite: 12 passed.
- All V2 repair tests: 56 passed.
- Full campaign-planner area: 746 passed.
- Full `mix test --timeout 120000`: 3,489 passed.
- Schema lint: 155 artifacts, zero errors/warnings.
- `mix compile --warnings-as-errors`, formatting, and diff checks: pass.

Parent review:
Complete. The parent checked argument ordering, shared replay-classifier reuse,
one-unit multi-row semantics, numeric-string policy handling, empty/absent
omission, score/report totals, review/import alignment, schemas, docs, and the
regenerated strategy golden. Review explicitly ruled out double-counting: the
new nonzero terms are nested generated-refresh V2 terms, while the strategic V3
candidate-diff term remains zero in that fixture. Review added exact golden
nested-score keys/counts and absent score-report assertions; no code must-fix
findings remain. Runtime policy disallows subagent delegation, so the parent
performed review and publish prep.

Previous published slice:
- `6ab8683c` Score repair refresh freshness pressure (`3488 passed`).

Remaining maturity gaps:
- Continue calibrated realized-feedback depth and remaining candidate-selection
  or scoring gaps only where live evidence proves they still exist.
- Continue deeper numerical/backend and resource-model maturity separately.

Blocked:
Not blocked. Runtime policy disallows subagent delegation, so the parent will
perform bounded review and publish handoff.

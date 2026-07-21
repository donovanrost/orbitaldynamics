# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Validate V1 ranked-timeline score explanations.

Status:
Implemented, fully verified, and parent-reviewed; ready to publish.

Selected slice:
Validate each V1 ranked timeline's score shape and the optional score-term
report against the enclosing ranked timelines.

Why this slice:
`campaign_plan.v1` exports typed ranked timelines, but runtime validation only
checks that the collection is a list. Its optional `score_term_report.v1` is
validated only internally, so stale ranks, scenario IDs, term values, timeline
scores, selections, or duplicate/missing rows can disagree with the plan.

Level 6 pillar:
Reproducible ranked timelines with explainable, versioned score handoffs.

Implemented:
- Each ranked timeline requires a stable scenario ID, numeric score, map-shaped
  score terms, and numeric term values at runtime.
- An optional score-term report must use the V1 model/source, match the union of
  term keys, and contain one unique row for every rank/scenario/term with the
  enclosing value, timeline score, and selected status.
- Cross-field comparisons use an absolute `1.0e-9` numeric tolerance and skip
  malformed shapes already reported by field validators.
- The V1 JSON Schema constrains ranked-timeline score-term values to numbers.

Docs changed:
- `docs/feature_set/capability_map/12_v1_campaign_planning.md`
- `docs/feature_set/capability_map/17_reproducibility_artifacts_and_audit.md`
- `docs/feature_set/recommended_roadmap.md`

Verification:
- Focused plan/export/communications tests: `19 passed`.
- Schema area: `198 passed`.
- Campaign-planner area: `754 passed`.
- Full suite with `--timeout 120000`: `3523 passed`.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, and
  `git diff --check`: passed.

Parent review:
- Validation is additive and preserves the optional report boundary and report
  row reordering.
- V1 score terms intentionally are not summed: the map includes counts and
  subtotals, unlike the additive V2 repair score-term map.
- Exact/multi-rank and mutation tests cover malformed timelines, source/model,
  rank/scenario identity, values, scores, selection, duplicates, and malformed
  rows without secondary crashes.
- Schema regeneration changed only the standalone V1 campaign export and its
  bundle entry, solely tightening score-term value types.

Previous published slice:
- `65279045` Validate aggregate repair scores (`3517 passed`).

Remaining maturity gaps:
- Continue calibrated realized-feedback depth where evidence is genuinely
  candidate-specific.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performed bounded
mapping, implementation, review, and mechanical publish checks.

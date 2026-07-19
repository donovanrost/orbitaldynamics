# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness evidence-normalization extraction.

Status:
Completed and pushed in `c8501c35`.

Selected boundary:
Extract readiness row access/counting plus freshness, schema-validation,
source-model/model-limit, and policy-classification evidence normalization
into `OrbitalDynamics.OperationalReadiness.EvidenceNormalization`. Preserve
the public OperationalReadiness facade and private delegates used by the
central evidence builder and quality-gate summaries.

Selection evidence:
- Live re-ranking placed `operational_readiness.ex` at 2,766 lines, fourth
  behind Schema, Timeline, and MissionPlan.Activity, and ahead of
  RecommendationRiskContext, TimelineFeedback, StationCalendar, and
  LinkCapacity.
- The extracted family owns artifact/review/import freshness extraction,
  schema-validation status and issue counts, source model and model-limit
  collection, policy classification extraction, scalar normalization, and
  deterministic frequency aggregation.
- The central readiness evidence builder consumes all normalized families;
  quality-gate and resource summaries also consume row extraction, integer,
  list, normalized-string, and map-value primitives through narrow delegates.
- Gate construction, resource/adapter/operator-training/timeline evidence,
  import classification, execution boundaries, public clauses, and artifact
  contracts remain outside this boundary.

Verification:
- Strict warning-clean compile passed across 3,956 files:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`.
- Focused OperationalReadiness regression passed 31 tests; adjacent
  operational-readiness/quality-gate operator review, candidate-refresh
  replay, and validation fixture consumers passed 22 tests. The final
  consolidated run passed all 53 tests.
- Exact old/new parity passed 9 comparisons from selection commit `a361cea1`
  with `/tmp/operational_readiness_evidence_normalization_compare.exs`,
  covering review/import rows, direct freshness/schema/policy artifacts,
  mixed atom/string/integer/float coercion, nested source evidence, model
  limits, empty evidence, quality-gate wrapping, and public errors.
- `mix xref callers
  OrbitalDynamics.OperationalReadiness.EvidenceNormalization` reports only the
  OperationalReadiness facade.
- Compile-connected xref scope for the new owner does not expand beyond the
  owner itself.
- Focused formatting, `git diff --check`, removed-family static checks, and
  final facade/owner review passed.

Behavior/schema changes:
None. The public OperationalReadiness facade, nested lookup precedence,
blank/null omission, vocabularies, integer coercion, list wrapping, frequency
semantics, row filtering, deterministic artifacts, and exact errors are
unchanged.

Last completed slice:
OperationalReadiness evidence-normalization extraction, selected in
`a361cea1` and implemented in `c8501c35`.
`operational_readiness.ex` moved from 2,766 to 2,500 lines; the dedicated
evidence-normalization owner is 312 lines.

Next candidate:
Re-rank the live largest-module inventory and select the next cohesive,
facade-preserving ownership boundary.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness evidence-normalization extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract readiness row access/counting plus freshness, schema-validation,
source-model/model-limit, and policy-classification evidence normalization
into `OrbitalDynamics.OperationalReadiness.EvidenceNormalization`. Preserve
the public OperationalReadiness facade and private delegates used by the
central evidence builder and quality-gate summaries.

Selection evidence:
- Live re-ranking places `operational_readiness.ex` at 2,766 lines, fourth
  behind Schema, Timeline, and MissionPlan.Activity, and ahead of
  RecommendationRiskContext, TimelineFeedback, StationCalendar, and
  LinkCapacity.
- The selected family spans lines 1,832-2,139. It owns artifact/review/import
  freshness extraction, schema-validation status and issue counts, source
  model and model-limit collection, policy classification extraction, scalar
  normalization, and deterministic frequency aggregation.
- The central readiness evidence builder consumes all normalized families;
  quality-gate summaries also consume row extraction and map-value counting.
  Narrow delegates keep those facade callers stable.
- Gate construction, resource/adapter/operator-training/timeline evidence,
  import classification, execution boundaries, public clauses, and artifact
  contracts remain outside this boundary.
- Existing nested lookup precedence, blank/null omission, accepted status and
  classification vocabularies, integer truncation/parsing, list wrapping,
  duplicate frequency semantics, row filtering, and exact errors must remain
  unchanged.

Verification plan:
- Run the strict warning-clean compile before and after implementation.
- Run the focused OperationalReadiness regression file and adjacent
  quality-gate, operator-review, import, and schema consumers selected from
  live references.
- Run exact old/new parity from this selection commit across direct and nested
  freshness/schema/policy evidence, mixed atom/string/count inputs,
  source-model limits, review/import row precedence, empty evidence,
  deterministic output, and invalid public errors.
- Run `mix xref callers` for the new owner, inspect compile-connected
  dependents, check formatting and `git diff --check`, prove the removed
  helper family is absent from the facade, and review final facade/owner
  boundaries.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar approval-policy extraction, selected in `7ca6a115`,
implemented in `7cf1481b`, and handed off in `9f6325b8`.
`station_calendar.ex` moved from 2,778 to 2,595 lines; the dedicated approval
policy owner is 213 lines.

Next candidate:
Implement and verify the selected OperationalReadiness evidence-normalization
extraction.

Blocked:
No.

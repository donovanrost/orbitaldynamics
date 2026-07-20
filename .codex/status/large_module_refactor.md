# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness gate-summary extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract operational-readiness gate-summary construction and shared row-derived
gate count/status/classification/ID routing into
`OrbitalDynamics.OperationalReadiness.GateSummary`.
Preserve all OperationalReadiness and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,768 lines, the
  largest ordinary eligible facade.
- OperationalReadiness already delegates nine focused evidence and specialized
  summary responsibilities, while gate-summary projection and shared gate
  aggregations remain inline at lines 463-543.
- The selected block has one responsibility: derive compact gate routing and
  deterministic counts/ID maps from readiness gate rows.
- Readiness report classification, import-eligibility/execution-boundary
  semantics, quality-gate row construction, evidence collection, and all public
  contracts remain outside the boundary.
- Exact malformed-row filtering, status/classification frequencies, ID
  grouping/sorting, non-passed ordering, counts, assumptions, model limits,
  public output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext relay-data-path extraction, selected in `189a5e6a`
and implemented in `574e2a13`.
`recommendation_risk_context.ex` moved from 1,772 to 1,650 lines; the dedicated
RelayDataPath owner is 155 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `operational_readiness.ex` is now the largest ordinary eligible
facade at 1,768 lines, followed by ContactAllocation and StationCalendar.

Blocked:
No.

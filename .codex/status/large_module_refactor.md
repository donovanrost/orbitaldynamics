# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness quality-gate schema-validation summary extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract quality-gate schema-validation row selection, context detection,
positive-count aggregation, failed/blocked classification, status and gate-ID
routing, deterministic ID ordering, summary construction, and the advertised
summary artifact contract into
`OrbitalDynamics.OperationalReadiness.QualityGateSchemaValidationSummary`.
Preserve all public OperationalReadiness report, gate, quality-summary, and
capability facades.

Selection evidence:
- Live re-ranking places `operational_readiness.ex` at 2,276 lines, the largest
  eligible facade behind Schema, Timeline, MissionPlan.Activity, and the root
  public facade.
- The selected summary builder at lines 786-844 and its dedicated row/context/
  failure helpers at lines 1,138-1,169 exclusively project existing
  `cadence_import` quality-gate schema-validation evidence.
- The public direct-report and derived-report clauses already converge on this
  private builder, matching the established operator-training summary owner
  pattern.
- Readiness classification, quality-gate construction, unavailable-resource,
  operator-training, import-readiness, adapter, evidence, and public report
  behavior remain outside this boundary.
- Existing positive-integer filtering, count summation, row inclusion, failure
  rules, blocked/review ID routing, stable sort/deduplication, omission of nil
  fields, assumptions/model limits, exact keys, and capability metadata must
  remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OrbitData TLE metadata inspection extraction, selected in `88ff0fb6` and
implemented in `edc3ffee`.
`orbit_data.ex` moved from 2,304 to 2,016 lines; the dedicated TLE metadata
owner is 325 lines.

Next candidate:
Implement and verify the selected OperationalReadiness quality-gate
schema-validation summary boundary.

Blocked:
No.

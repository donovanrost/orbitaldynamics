# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness resource-availability gate extraction.

Status:
Completed and pushed in `a0fccffa`.

Selected boundary:
Extract resource-availability gate classification and context projection into
`OrbitalDynamics.OperationalReadiness.ResourceAvailabilityGate`. Preserve all
OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,295 lines, the
  largest ordinary eligible facade.
- OperationalReadiness delegates five focused gate/decision owners, while the
  resource-availability gate and its context remain inline at lines 973-1,014.
- The selected code has one responsibility: classify declared resource
  pressure and project stable reason, station, blocking, provenance, and trust
  context into the resource-availability gate.
- Quality-gate row helpers, evidence construction, mission policy, operator
  training, and all other gates remain outside the boundary.
- Exact gate inclusion, status/classification/reason strings, map keys and
  values, positive-count filtering, sorted reason IDs, station/unavailable
  reason classification, public output, and error behavior must remain
  unchanged.

Implementation:
- Added `OrbitalDynamics.OperationalReadiness.ResourceAvailabilityGate` as the
  focused owner of resource-pressure classification and reason, station,
  blocking, provenance, and trust context projection.
- Preserved the public OperationalReadiness facade through the gate builder.
- Evidence construction, quality-gate row helpers, and all other gates remain
  outside the extraction.
- `operational_readiness.ex` moved from 1,295 to 1,253 lines; the dedicated
  ResourceAvailabilityGate owner is 84 lines.

Verification:
- Strict focused baseline: 31 tests passed with warnings treated as errors.
- Exact old/new public parity: five results passed, covering no-pressure
  omission, rich station/unavailable reasons, stable IDs, blocking and
  provenance context, downstream quality-gate output, the root facade, and
  invalid-input error behavior.
- Post-change core, operator-review, schema, and fixture checks: 51 tests
  passed with warnings treated as errors.
- Static ownership and xref checks passed; only the facade calls the extracted
  owner at runtime.
- Forced warning-clean test compile passed across 4,029 files.
- Focused formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness resource-availability gate extraction, selected in
`60ee070b` and implemented in `a0fccffa`.
`operational_readiness.ex` moved from 1,295 to 1,253 lines; the dedicated
ResourceAvailabilityGate owner is 84 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.

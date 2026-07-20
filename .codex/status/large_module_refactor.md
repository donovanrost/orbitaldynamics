# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness quality-gate summary extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract row-derived quality-gate summary projection and its classification and
routing rules into
`OrbitalDynamics.OperationalReadiness.QualityGateSummary`.
Preserve all OperationalReadiness and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,598 lines, the
  largest ordinary eligible facade.
- OperationalReadiness already delegates twelve focused responsibilities,
  while the quality-gate summary projection remains inline at lines 486-542.
- The selected block has one responsibility: derive readiness classification,
  row counts, gate and row routing sets, non-passed rows, and explicit execution
  boundaries from a quality-gate report.
- Readiness evidence collection, gate decisions, quality-gate reporting,
  unavailable-resource summaries, import-eligibility summaries, and all public
  contracts remain outside the boundary.
- Exact schema/model fields, row-derived classification precedence, counts,
  stable ID sorting/grouping, non-passed row filtering and order, assumptions,
  model limits, atom-key normalization, public output, and error behavior must
  remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness import-eligibility summary extraction, selected in
`a4788975` and implemented in `3eb8d213`.
`operational_readiness.ex` moved from 1,635 to 1,598 lines; the dedicated
ImportEligibilitySummary owner is 46 lines.

Next candidate:
After this slice, re-rank the live checkout. ContactContention and
ResourceFilter are the next largest ordinary eligible facades, followed by the
reduced OperationalReadiness facade.

Blocked:
No.

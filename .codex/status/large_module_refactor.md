# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness operator-training evidence extraction.

Status:
Completed and pushed.

Selected boundary:
Extract artifact/review/import operator-training evidence traversal,
role/training/certification/qualification alias resolution, stable string
normalization, deduplication/sorting, and requirement-count projection into
`OrbitalDynamics.OperationalReadiness.OperatorTrainingEvidence`. Preserve all
public OperationalReadiness report and summary facades.

Selection evidence:
- Live re-ranking places `operational_readiness.ex` at 2,385
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected helper family spans lines 1,876-1,984 and exclusively owns
  operator-training evidence collection and aggregation.
- Readiness evidence construction is the single consumer of the resulting
  training context.
- Quality-gate summary projection, training gate decisions, generic evidence
  normalization, shared stable-ID map routing, other evidence families, public
  clauses, and artifact contracts remain outside this boundary.
- Existing artifact-before-review-before-import traversal, nested source-row
  discovery, field-alias order, scalar/list wrapping, atom/string
  normalization, unsupported-value omission, deduplication, lexical sorting,
  positive-count omission, total counting, exact keys, and empty behavior must
  remain unchanged.

Implementation:
- Selection was recorded and pushed in `0a2611d2`.
- Implementation was committed and pushed in `7d28b490`.
- `operational_readiness.ex` moved from 2,385 to 2,276 lines.
- `OrbitalDynamics.OperationalReadiness.OperatorTrainingEvidence` is a
  131-line owner reached through a private facade delegate.

Verification:
- Strict warning-clean compilation passed across 3,972 files.
- The focused OperationalReadiness file and six adjacent Cadence-import,
  campaign-strategy, replay, operator-review, and schema consumers passed
  together: 64 tests.
- Exact old/new public parity passed for 6 report-to-quality-gate chains
  covering empty, artifact-level, nested training, source-review/source-gate,
  duplicate, atom/scalar/list, blank, and unsupported evidence.
- `mix xref callers` reports only the OperationalReadiness facade.
- The removed collector, nested traversal, alias readers, and list collector
  are absent from the facade apart from the thin delegate, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness operator-training evidence extraction, selected in
`0a2611d2` and implemented in `7d28b490`.
`operational_readiness.ex` moved from 2,385 to 2,276 lines; the dedicated
operator-training evidence owner is 131 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.

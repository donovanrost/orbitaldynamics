# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness resource-availability evidence extraction.

Status:
Completed and pushed.

Selected boundary:
Extract resource-availability reason and blocking-dimension aggregation,
blocked contact-ID map construction, resource provenance counts, nested
resource evidence traversal, and the shared stable evidence-map normalization
into `OrbitalDynamics.OperationalReadiness.ResourceAvailabilityEvidence`.
Preserve all public OperationalReadiness report, eligibility, gate-summary,
execution-boundary, quality-gate, specialized-summary, and capability facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 2,186 lines,
  the largest ordinary eligible facade behind Schema, Timeline, and
  MissionPlan.Activity.
- OperationalReadiness already has six responsibility owners, while resource
  evidence aggregation remains in the facade at lines 1,841-2,004 and depends
  on stable evidence-map helpers at lines 1,790-1,830.
- The selected functions form one pure evidence-routing boundary consumed by
  readiness report construction and resource quality-gate row context.
- General evidence normalization remains authoritative in
  `EvidenceNormalization`; the new owner will compose its public list/string
  normalization helpers rather than fork them.
- Gate classification, quality-gate row construction, import/readiness
  summaries, timeline-publication context, adapter/training evidence,
  artifact conversion, and report identity remain outside the boundary.
- Existing review-row precedence over import rows, nested source traversal,
  stable ID normalization, dedup/sort behavior, exact availability reason
  allowlist, group-map merging, and provenance selection must remain unchanged.

Implementation:
- Selection was recorded and pushed in `d5786ac1`.
- Implementation was committed and pushed in `efb06679`.
- `operational_readiness.ex` moved from 2,186 to 2,018 lines.
- `OrbitalDynamics.OperationalReadiness.ResourceAvailabilityEvidence` is a
  215-line owner reached through thin private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,985 files.
- The focused OperationalReadiness suite and six adjacent operator-review,
  quality-gate, candidate-refresh, schema, and validation consumers passed
  together: 52 tests.
- Exact old/new public readiness/eligibility/gate/execution/quality-summary
  parity passed for 4 chains covering direct resource projections, nested
  contact-allocation suppressions and provenance, import-row fallback, stable
  blocked-ID maps, and capabilities.
- One adjacent strategy readiness-row score assertion was already failing at
  the selection-only baseline `d5786ac1`; it is unrelated to this evidence
  ownership move.
- `mix xref callers` reports only the OperationalReadiness facade.
- The facade-owned nested resource traversal, reason/dimension aggregation,
  provenance, and stable-map helpers are absent apart from thin delegates;
  formatting and `git diff --check` passed, and the final diff is
  ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness resource-availability evidence extraction, selected in
`d5786ac1` and implemented in `efb06679`.
`operational_readiness.ex` moved from 2,186 to 2,018 lines; the dedicated
resource-availability evidence owner is 215 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.

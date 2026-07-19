# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness resource-availability evidence extraction.

Status:
Selected; strict focused baseline pending.

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
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
ContactAllocation station-capacity evidence extraction, selected in
`fb4cb586` and implemented in `e60823d7`.
`communications/contact_allocation.ex` moved from 2,197 to 1,953 lines; the
dedicated station-capacity evidence owner is 315 lines.

Next candidate:
Complete the selected OperationalReadiness resource-availability evidence
extraction.

Blocked:
No.

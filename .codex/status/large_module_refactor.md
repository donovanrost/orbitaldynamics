# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceFilter summary extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract `resource_filter_summary.v1` construction, report-row normalization,
review/routing counts, stable ID grouping, and duplicate-row summary evidence
into `OrbitalDynamics.ResourceFilter.Summary`. Preserve all ResourceFilter and
root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `resource_filter.ex` at 2,059 lines,
  the largest ordinary eligible facade.
- The summary builder remains in the facade at lines 418-483 and consumes only
  an existing report plus facade-owned contract/model-limit values.
- Count, routing, stable-ID, and duplicate summary helpers form a cohesive
  output-aggregation family near lines 1,331-1,376; shared report helpers will
  remain facade-owned where still required.
- Candidate/resource-summary normalization, lookup ambiguity, suppression and
  margin policy, approval requirements, report construction, station context,
  provenance, and provider-result handling remain outside the boundary.
- Exact string/atom report parity, pass-through summary behavior, deterministic
  ID ordering, sparse omission, review status, invalid-input evidence,
  duplicate collision counts, routing maps, source defaults, and public
  exception behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
ContactFilter provider-counteroffer context extraction, selected in `b1f30133`
and implemented in `a24fb6f8`.
`communications/contact_filter.ex` moved from 2,062 to 1,898 lines; the
dedicated provider-counteroffer context owner is 149 lines.

Next candidate:
Complete the selected ResourceFilter summary extraction.

Blocked:
No.

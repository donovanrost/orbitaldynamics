# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback provider-result normalization extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract provider-result flattening, token outcome classification, and artifact
scalar normalization into
`OrbitalDynamics.TimelineFeedback.ProviderResult`. Preserve the existing
private outcome and artifact-value seams used by `TimelineFeedback`.

Selection evidence:
- Live re-ranking shows `timeline_feedback.ex` is the second-largest production
  module at 5,463 lines after `schema.ex` reached 6,764 lines.
- The selected provider-result seams span 4,331-4,343 and 4,355-4,468 and share
  one responsibility with no timeline reconciliation state dependency.
- The provider result map keys remain capability/facade data passed into the new
  owner; completion-fraction weighting remains in `TimelineFeedback`.
- The prior validation-context Schema candidate was rejected during bounded
  review because it added 48 lines of aggregation for only 6 facade lines while
  specialized modules already owned the behavior.

Verification:
Pending: focused timeline-feedback baselines, exact old/new public artifact
outputs, strict compile, broader timeline-feedback tests, capability checks,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema strategy-context JSON Schema extraction, selected in `42dddf3b` and
implemented in `f6d4ad0b`. `schema.ex` moved from 6,786 to 6,764 lines; the
dedicated owner is 77 lines.

Next candidate:
Re-inventory remaining TimelineFeedback normalization/reconciliation families
after provider-result normalization has one production owner.

Blocked:
No.

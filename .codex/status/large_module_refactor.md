# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema strategy-context JSON Schema extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract strategy branch tradeoff/risk/event/assumptions/provenance/branch plus
strategy explanation and branch-event-summary JSON Schema construction into
`OrbitalDynamics.Schema.StrategyContextJsonSchema`. Preserve the existing
private Schema helper seams.

Selection evidence:
- `schema.ex` is 6,786 lines; the selected strategy-schema seams span
  3,788-3,800, 3,807-3,849, and 3,856-3,867.
- The cluster has one responsibility: construct reusable strategy branch and
  recommendation context schemas.
- Stable-ID, collection, policy, semantic-change, and scoped-downlink schemas
  remain facade-owned inputs; registry-backed strategy documents and branch
  comparison source rows remain outside.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
Pending: focused strategy-schema baselines, exact old/new JSON Schema documents,
strict compile, broader Schema contract tests, JSON Schema export checks,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema timeline-context JSON Schema extraction, selected in `a3b0ad64` and
implemented in `b082045f`. `schema.ex` moved from 6,861 to 6,786 lines; the
dedicated owner is 124 lines.

Next candidate:
Re-inventory remaining Schema families after strategy-context JSON Schema
construction has one production owner.

Blocked:
No.

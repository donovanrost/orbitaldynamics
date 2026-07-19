# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema strategy-context JSON Schema extraction.

Status:
Completed and published.

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
- Strict compile passed across 3,871 files with warnings as errors.
- Focused JSON Schema export, strategy-recommendation, and branch-lint
  contracts passed: 17 tests, including all 15 export contracts.
- Full Schema suite passed: 175 tests.
- Exact old/new JSON Schema documents matched for 6 strategy, branch,
  operator-review, and campaign contracts.
- Static inspection confirms the facade retains one explicit primitive/context
  bundle and the three orphaned internal wrappers were removed; runtime xref
  reports `Schema` as the sole caller of the new owner.
- `git diff --check` and bounded ownership review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema strategy-context JSON Schema extraction, selected in `42dddf3b` and
implemented in `f6d4ad0b`. `schema.ex` moved from 6,786 to 6,764 lines; the
dedicated owner is 77 lines.

Next candidate:
Re-inventory remaining Schema families after strategy-context JSON Schema
construction has one production owner.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy requirement-context resolution extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract requirement-context lookup and list expansion, station/direction
normalization, provider-result tokenization, nested protection lookup, and
their direction/provider alias constants into
`OrbitalDynamics.Policy.RequirementContext`. Preserve the private Policy seams
used by rule normalization, rule matching, and decision evidence construction.

Selection evidence:
- `policy.ex` is 5,555 lines; the selected continuous cluster spans roughly 610
  lines at 3,761-4,372.
- The cluster has one responsibility: resolve normalized selector values from
  approval-requirement top-level, source activity, activity, and metadata
  contexts.
- Its direction-alias and provider-result-key constants are otherwise exposed
  only through Policy capability metadata, so the new owner can remain the
  single source of truth.
- Policy bundles, rule validation, decision orchestration, risk/event/activity
  matching, escalation, fallback classification, and public APIs remain outside
  the boundary.

Verification:
Pending: focused direction/station/provider/protection baselines, exact old/new
decision proofs, strict compile, full Policy tests, relevant schema/contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport capability ownership extraction, selected in `ace1eb07` and
implemented in `7d081341`. `cadence_import.ex` moved from 866 to 663 lines; the
dedicated capability owner is 216 lines.

Next candidate:
Re-inventory the remaining Policy rule-match families after requirement context
resolution has one production owner.

Blocked:
No.

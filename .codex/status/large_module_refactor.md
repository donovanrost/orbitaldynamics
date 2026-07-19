# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy requirement-context resolution extraction.

Status:
Completed and pushed in `44d83250`.

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
- Strict warnings-as-errors compile passed across 3,847 files.
- Five focused provider/station/direction/protection tests passed.
- All 89 Policy tests passed.
- The Policy schema-contract test passed.
- Exact old/new comparison passed for the complete Policy capability map and 55
  built-in bundle/context decisions spanning direction aliases, station lists,
  provider results, nested protection, and resource evidence.
- Static search confirms one resolver owner with nine explicit private Policy
  seams shared by requirement, risk, event, and activity matching.
- Runtime xref confirms Policy owns the dependency on RequirementContext.
- Formatting, diff checks, and bounded review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Policy requirement-context extraction, selected in `56a7dfce` and implemented
in `44d83250`. `policy.ex` moved from 5,555 to 4,960 lines; the dedicated
resolver is 630 lines.

Next candidate:
Re-inventory the remaining Policy rule-match families after requirement context
resolution has one production owner.

Blocked:
No.

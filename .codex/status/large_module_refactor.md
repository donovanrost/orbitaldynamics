# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection validation context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Add default-context entry points to ResourceValidation for required and
optional resource-projection report/flow-summary validation. Compose defaults
from PolicyValidation and StableIdValidation, route two eager and four lazy
Schema consumers directly, and remove four facade wrappers plus their callback
builder. Keep the existing customizable owner APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,796 lines; the other
  targeted public facades are now 164 to 524 lines.
- All four wrappers pass the same three callbacks: owner-default policy
  approval/rule-match validation and StableIdValidation nested-ID matching.
- Exact usage finds two eager validations and four callbacks across campaign
  plan/repair and strategy validation.
- Every dependency is now owner-level; no recursive Schema lookup or facade
  capability context is required.
- Owner-default entry points preserve the customizable APIs for callers that
  supply alternate callbacks.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema policy validation context extraction, selected in `03338711` and
implemented in `2c7523d3`.
`schema.ex` moved from 5,841 to 5,796 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.

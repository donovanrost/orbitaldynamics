# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection validation context extraction.

Status:
Completed and pushed.

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
Added default-context entry points to ResourceValidation for required and
optional resource-projection report/flow-summary validation. Kept all
customizable APIs, composed defaults from PolicyValidation and
StableIdValidation, routed two eager and four lazy facade consumers directly,
and removed four wrappers plus their callback builder. `schema.ex` moved from
5,796 to 5,752 lines.

Verification:
- Strict resource/campaign/policy/operator-review baseline before extraction:
  11 passed.
- The same strict focused suite after extraction: 11 passed.
- Strict checked-in export, review/import handoff, JSON Schema export, and
  Cadence import coverage: 26 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms two direct eager validations, four direct
  callbacks, zero facade wrappers/callback builders, and retained customizable
  owner APIs.
- `mix xref callers OrbitalDynamics.Schema.ResourceValidation` reports the
  expected Schema facade and internal contact-report validation consumers.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,072 files with no warnings.
- Bounded local diff review found no must-fix findings.
- Implementation commit `90f0fb94` pushed to `main`.

Behavior/schema changes:
None. Resource model limits, policy and nested-ID callbacks, issue ordering and
paths, customizable owner entry points, public Schema APIs, validation results,
and checked-in exports remain unchanged.

Last completed slice:
Schema resource-projection validation context extraction, selected in
`d922c4fd` and implemented in `90f0fb94`.
`schema.ex` moved from 5,796 to 5,752 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.

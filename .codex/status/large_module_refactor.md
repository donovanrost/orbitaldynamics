# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy validation context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Add default-context entry points to PolicyValidation for approval requirements,
optional decision evidence, decisions, rule matches, and bundles. Derive model
limits and field groups from existing policy owners, route Schema's eager and
lazy consumers directly, and remove all five facade wrappers. Keep the existing
customizable owner APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,841 lines; the other
  targeted public facades are now 164 to 524 lines.
- All five wrappers supply only policy-owned model limits or action/rule-match
  field groups.
- Exact usage finds twelve eager/callback consumers across policy artifacts,
  campaign repair, resource validation, Cadence, and operator review.
- `PolicyCapabilityContext` and `PolicyFieldGroups` already own every default
  dependency; no recursive Schema lookup is required.
- Owner-default entry points preserve the customizable APIs for callers that
  supply alternate limits or field groups.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema candidate-rejection validation context extraction, selected in
`41574844` and implemented in `ef9b3d23`.
`schema.ex` moved from 5,860 to 5,841 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.

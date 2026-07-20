# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy validation context extraction.

Status:
Completed and pushed.

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
Added default-context entry points to PolicyValidation for approval
requirements, optional decision evidence, decisions, rule matches, and bundles.
Kept all customizable APIs, derived defaults from PolicyCapabilityContext and
PolicyFieldGroups, routed twelve facade consumers directly, and removed all
five wrappers. `schema.ex` moved from 5,841 to 5,796 lines.

Verification:
- Strict policy/campaign/resource/Cadence/operator-review baseline before
  extraction: 15 passed.
- The same strict focused suite after extraction: 15 passed.
- Strict checked-in export, review/import handoff, JSON Schema export, and
  contact-feedback coverage: 27 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms four approval, three evidence, three
  decision, one rule-match, and one bundle direct owner consumers, zero facade
  wrappers, and retained customizable owner APIs.
- `mix xref callers OrbitalDynamics.Schema.PolicyValidation` reports only the
  expected Schema facade runtime caller.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,072 files with no warnings.
- Bounded local diff review found no must-fix findings.
- Implementation commit `2c7523d3` pushed to `main`.

Behavior/schema changes:
None. Model limits, policy field groups, issue ordering and paths, customizable
owner entry points, public Schema APIs, validation results, and checked-in
exports remain unchanged.

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

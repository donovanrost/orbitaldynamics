# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-transition validation context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Add default-context arity-three entry points to TimelineTransitionValidation,
route Schema's two eager validations and eight lazy callbacks directly to
those owner APIs, and remove five facade wrappers plus their shared callback
builder. Keep the existing arity-four customizable owner APIs. Preserve issue
ordering, paths, callback behavior, public Schema APIs, and validation results.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,913 lines; the other
  targeted public facades are now 164 to 524 lines.
- Five facade wrappers always pass the same three
  TimelineContextValidation callbacks to the existing owner.
- Exact usage finds two eager validation pipelines and eight lazy callback
  entries across campaign, Cadence, and operator-review validation contexts.
- Owner-default entry points preserve the customizable arity-four APIs for any
  callers that supply alternate callbacks.
- Unrelated decision-support and domain validation wrappers remain out of
  scope.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema numeric-triplet primitive routing, selected in `01c64f0e` and
implemented in `1537a415`.
`schema.ex` moved from 5,919 to 5,913 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.

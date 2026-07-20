# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-transition validation context extraction.

Status:
Completed and pushed.

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
Added default-context arity-three entry points to TimelineTransitionValidation,
kept all customizable arity-four APIs, routed two eager facade validations and
eight lazy callbacks directly to the owner, and removed five wrappers plus the
shared callback builder. `schema.ex` moved from 5,913 to 5,860 lines.

Verification:
- Strict campaign/Cadence/operator-review/timeline baseline before extraction:
  16 passed.
- The same strict focused suite after extraction: 16 passed.
- Strict checked-in export, review/import handoff, and JSON Schema export
  coverage: 22 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms two direct eager validations, eight direct
  lazy callbacks, zero facade wrappers, and retained arity-four owner APIs.
- `mix xref callers OrbitalDynamics.Schema.TimelineTransitionValidation`
  reports only the expected Schema facade runtime caller.
- `git diff --check` passed.
- Strict forced compile passed across 4,072 files with no warnings.
- Implementation commit `f1a0f77f` pushed to `main`.

Behavior/schema changes:
None. Issue ordering, paths, default TimelineContextValidation callbacks,
customizable owner entry points, public Schema APIs, validation results, and
checked-in exports remain unchanged.

Last completed slice:
Schema timeline-transition validation context extraction, selected in
`0f55f0bb` and implemented in `f1a0f77f`.
`schema.ex` moved from 5,913 to 5,860 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operator-review validation context extraction.

Status:
Completed and pushed.

Selected boundary:
Add owner-default required-package, optional-package, and row entry points to
OperatorReviewValidation. Compose registry requirements, capability metadata,
package callbacks, and the complete row callback graph from existing owners,
route every Schema consumer directly, and remove three wrappers plus both
callback bags. Keep all customizable owner APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,576 lines; the other
  targeted public facades are now 164 to 524 lines.
- Package defaults require only registry fields, operator-review capability
  metadata, and four existing owner callbacks.
- Row defaults require only review/counteroffer capability metadata and schema
  owner callbacks; contact-allocation dependencies are now owner-default.
- Exact usage finds one required package validation, four optional-package
  callbacks, and owner-internal row validation.
- No callback requires recursive Schema lookup or facade-local validation.
- Owner-default entry points preserve all customizable APIs.

Implementation:
Added owner-default required-package, optional-package, and row entry points to
OperatorReviewValidation. Kept all customizable APIs, moved registry,
capability, package, and row callback context into the owner, routed one
required validation and four optional facade callbacks directly, removed three
wrappers plus both callback bags, and removed two stale facade imports.
`schema.ex` moved from 5,576 to 5,475 lines.

Verification:
- Strict operator-review/Cadence/campaign/contact-allocation/timeline baseline
  before extraction: 24 passed.
- The same strict focused suite after extraction: 24 passed.
- Strict checked-in export, JSON Schema export, review/import handoff,
  contact-feedback, and communications coverage: 35 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms one direct required validation, four direct
  optional callbacks, owner-internal row validation, zero facade wrappers or
  callback bags, and retained customizable owner APIs.
- `mix xref callers OrbitalDynamics.Schema.OperatorReviewValidation` reports
  only the expected Schema facade runtime caller.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,072 files with no warnings.
- Bounded local review found and fixed duplicate required-field validation;
  the focused suite and strict compile passed again after the fix.
- Implementation commit `c8223f43` pushed to `main`.

Behavior/schema changes:
None. Required fields, capability metadata, package/row callbacks, issue
ordering and paths, customizable owner entry points, public Schema APIs,
validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema operator-review validation context extraction, selected in `3b0ee4c3`
and implemented in `c8223f43`.
`schema.ex` moved from 5,576 to 5,475 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.

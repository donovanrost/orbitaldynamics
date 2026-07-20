# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operator-review validation context extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema contact-allocation validation context extraction, selected in
`526df568` and implemented in `b255fe53`.
`schema.ex` moved from 5,707 to 5,576 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.

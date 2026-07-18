# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operator-review row callback-provider extraction.

Status:
Implementation `1688b4f9` published; verified handoff publication pending.

Completed slice:
Moved the exact ordered operator-review row callback registry and all external
domain/handoff captures from `Schema` into internal
`Schema.OperatorReviewRowCallbacks.build/1`. The facade now injects only its
private validator captures; the package registry and row caller are unchanged.

Why this slice:
`Schema` was 7,409 lines. The row-domain registry was a 163-line responsibility
with 86 ordered callback keys, 58 stable external captures, and 28
facade-private captures. `Schema` is now 7,293 lines.

Published commits:
- Selection: `4c3f9571`
- Implementation: `1688b4f9`
- Handoff: pending

Preserved facade and behavior:
All `Schema` APIs; operator-review row/package and Cadence-import validation
behavior; callback keys, order, values, arities, error ordering, deterministic
output, and all schema exports.

Verification:
- Focused operator-review/Cadence-import/review-handoff/timeline/export tests:
  33/33.
- Strict warnings-as-errors compile: 3,671 files.
- Full schema export regeneration: byte-clean checked-in `schemas/`.
- AST registry comparison: exact 86-key order, zero value mismatches, no
  duplicates, exact 58 external and 28 facade-private captures.
- Capture arities unchanged: external 56x/3 and 2x/4; private 20x/3 and 8x/4.
- Four-entry package registry and row validation caller: unchanged.
- Public `Schema` definition diff: empty.
- Format, whitespace, diff, xref caller, and independent read-only review:
  clean.

Verification gaps:
None for this slice.

Behavior/schema changes:
None.

Next candidate:
Remap the reduced `Schema` facade and choose between the small operator-review
package registry and remaining campaign/contact callback registries.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence source-review callback-provider extraction.

Status:
Implementation `e9fe1aae` published; verified handoff publication pending.

Completed slice:
Moved the exact ordered callback registry and all external contract captures from
`Schema.cadence_source_review_row_contract_callbacks/0` into internal
`Schema.CadenceSourceReviewRowCallbacks.build/1`. The facade now injects only
its private validator captures.

Why this slice:
`Schema` was 7,725 lines. The source-review callback registry was a 164-line
responsibility mixing stable external contract captures with private facade
validators. `Schema` is now 7,613 lines.

Published commits:
- Selection: `3f001bbe`
- Implementation: `e9fe1aae`
- Handoff: pending

Preserved facade and behavior:
All `Schema` APIs; Cadence source-review validation behavior; callback keys,
order, values, arities, error ordering, deterministic output, and all schema
exports.

Verification:
- Focused Cadence source-review/import/readiness/timeline/export tests: 34/34.
- Strict warnings-as-errors compile: 3,668 files.
- Full schema export regeneration: byte-clean checked-in `schemas/`.
- AST registry comparison: exact 89-key order, zero value mismatches, no
  duplicates, exact 56 external and 33 facade-private captures.
- Capture arities unchanged: external 54x/3 and 2x/4; private 1x/2, 21x/3,
  9x/4, and 2x/5.
- Public `Schema` definition diff: empty.
- Independent supplementary focused tests: 28/28.
- Format, whitespace, diff, xref caller, and independent read-only review:
  clean.

Verification gaps:
None for this slice.

Behavior/schema changes:
None.

Next candidate:
Remap the reduced `Schema` facade and select a bounded callback-provider
extraction from the Cadence import or operator-review registries.

Blocked:
No.

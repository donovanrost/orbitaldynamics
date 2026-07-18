# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence-import handoff callback-provider extraction.

Status:
Implementation `14f0715a` published; verified handoff publication pending.

Completed slice:
Moved the exact ordered Cadence-import handoff callback registry and all external
contract captures from `Schema` into internal
`Schema.CadenceImportRowHandoffCallbacks.build/1`. The facade now injects only
its private validator captures, and the existing base-registry
`Keyword.merge/2` boundary is unchanged.

Why this slice:
`Schema` was 7,613 lines. The handoff registry was a 194-line responsibility
with 96 ordered callback keys, 83 stable external captures, and only 13
facade-private captures. `Schema` is now 7,447 lines.

Published commits:
- Selection: `4e4d5c9c`
- Implementation: `14f0715a`
- Handoff: pending

Preserved facade and behavior:
All `Schema` APIs; Cadence import and source-review validation behavior;
callback keys, order, values, arities, merge behavior, error ordering,
deterministic output, and all schema exports.

Verification:
- Focused Cadence import/review-handoff/readiness/timeline/export tests: 34/34.
- Strict warnings-as-errors compile: 3,669 files.
- Full schema export regeneration: byte-clean checked-in `schemas/`.
- AST registry comparison: exact 96-key order, zero value mismatches, no
  duplicates, exact 83 external and 13 facade-private captures.
- Capture arities unchanged: all external captures arity 3; private captures
  12x/3 and 1x/4.
- Base import registry and `Keyword.merge/2` AST: unchanged.
- Public `Schema` definition diff: empty.
- Format, whitespace, diff, xref caller, and independent read-only review:
  clean.

Verification gaps:
None for this slice.

Behavior/schema changes:
None.

Next candidate:
Remap the reduced `Schema` facade and select the base Cadence-import or
operator-review callback registry.

Blocked:
No.

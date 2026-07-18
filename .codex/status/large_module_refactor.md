# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema base Cadence-import callback-provider extraction.

Status:
Implementation `1554fcd4` published; verified handoff publication pending.

Completed slice:
Moved the exact ordered base Cadence-import callback registry and its external
contract captures from `Schema` into internal
`Schema.CadenceImportRowCallbacks.build/1`. The facade now injects only its
private validators and preserves the existing merge with the extracted handoff
provider.

Why this slice:
`Schema` was 7,447 lines. The base import registry was a 65-line responsibility
with 35 ordered callback keys, 19 stable external captures, and 16
facade-private captures. `Schema` is now 7,409 lines.

Published commits:
- Selection: `5bde39d0`
- Implementation: `1554fcd4`
- Handoff: pending

Preserved facade and behavior:
All `Schema` APIs; Cadence import and source-review validation behavior;
callback keys, order, values, arities, merge behavior, error ordering,
deterministic output, and all schema exports.

Verification:
- Focused Cadence import/review-handoff/readiness/timeline/export tests: 34/34.
- Strict warnings-as-errors compile: 3,670 files.
- Full schema export regeneration: byte-clean checked-in `schemas/`.
- AST registry comparison: exact 35-key order, zero value mismatches, no
  duplicates, exact 19 external and 16 facade-private captures.
- Capture arities unchanged: external 17x/3 and 2x/4; private 11x/3, 4x/4,
  and 1x/7.
- Handoff `Keyword.merge/2` boundary and three-phase import caller: unchanged.
- Public `Schema` definition diff: empty.
- Format, whitespace, diff, xref caller, and independent read-only review:
  clean.

Verification gaps:
None for this slice.

Behavior/schema changes:
None.

Next candidate:
Remap the reduced `Schema` facade and select the operator-review row callback
registry.

Blocked:
No.

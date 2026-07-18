# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport resource-projection manifest-row builder extraction.

Status:
Implementation `6f621cde` published; verified handoff publication pending.

Completed slice:
Moved the resource-projection and flow-summary manifest row projection into
internal `CadenceImport.ResourceProjectionManifestRow.build/3`. The facade
injects only three shared review/status/compaction callbacks.

Why this slice:
`CadenceImport` was 6,327 lines. The builder was a 125-line transformation with
108 projected keys. `CadenceImport` is now 6,211 lines.

Published commits:
- Selection: `7f3df537`
- Implementation: `6f621cde`
- Handoff: pending

Preserved facade and behavior:
All `CadenceImport` APIs; all 108 resource-projection keys and value
expressions; approval defaults, review action, constant present adapter status,
compaction, deterministic output, and artifact contracts.

Verification:
- Focused Cadence-import plus schema-contract tests: 100/100.
- Strict warnings-as-errors compile: 3,680 files.
- Whole-builder AST comparison after callback normalization: exact.
- Projection comparison: 108/108 keys and expressions, zero mismatches.
- Three shared callbacks: exact identities and arities.
- Resource-projection dispatch and public `CadenceImport` definitions:
  unchanged.
- Format, whitespace, diff, xref caller, and independent read-only review:
  clean.
- Schema export not rerun: no schema-generation code or schema artifacts
  changed.

Verification gaps:
None for this slice.

Behavior/schema changes:
None.

Next candidate:
Remap the reduced `CadenceImport` module and select the next low-coupling
source-specific manifest-row builder.

Blocked:
No.

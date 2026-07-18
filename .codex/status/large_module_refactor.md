# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport operational-timeline manifest-row builder extraction.

Status:
Implementation `a05666c3` published; verified handoff publication pending.

Completed slice:
Moved the operational-timeline manifest row projection into internal
`CadenceImport.OperationalTimelineManifestRow.build/3`. The facade now injects
only six shared import-presence/review/status/provider-result/compaction
callbacks.

Why this slice:
`CadenceImport` was 7,460 lines. The operational-timeline builder was a
306-line transformation with 287 projected keys. `CadenceImport` is now 7,166
lines.

Published commits:
- Selection: `6a4bb929`
- Implementation: `a05666c3`
- Handoff: pending

Preserved facade and behavior:
All `CadenceImport` APIs; all 287 operational-timeline keys and value
expressions; approval/import defaults, import presence, provider-result
normalization, import status/action, compaction, deterministic output, and
artifact contracts.

Verification:
- Full Cadence-import tests plus schema Cadence-import contracts: 100/100.
- Strict warnings-as-errors compile: 3,675 files.
- Whole-builder AST comparison after callback normalization: exact.
- Projection comparison: 287/287 keys and expressions, zero mismatches.
- Six shared facade callbacks: exact names, purposes, and arities.
- Exact four provider-result conversions, two context normalizations, and final
  compaction position.
- Operational-timeline dispatch and public `CadenceImport` definitions:
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
Remap the reduced `CadenceImport` module and select the next source-specific
manifest-row builder.

Blocked:
No.

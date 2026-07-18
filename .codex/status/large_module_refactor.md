# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport station-calendar manifest-row builder extraction.

Status:
Implementation `099f0ef9` published; verified handoff publication pending.

Completed slice:
Moved the station-calendar and reservation manifest row projection into internal
`CadenceImport.StationCalendarManifestRow.build/3`. The facade injects only
four shared review/status/provider-result/compaction callbacks.

Why this slice:
`CadenceImport` was 6,481 lines. The station-calendar builder was a 164-line
transformation with 125 projected keys. `CadenceImport` is now 6,327 lines.

Published commits:
- Selection: `c2a02192`
- Selection correction: `e707b14e`
- Implementation: `099f0ef9`
- Handoff: pending

Preserved facade and behavior:
All `CadenceImport` APIs; all 125 station-calendar keys and value expressions;
approval defaults, constant present adapter status, provider-result
normalization, review action, compaction, deterministic output, station-
reservation reuse, and artifact contracts.

Verification:
- Focused Cadence-import plus schema-contract tests: 100/100.
- Strict warnings-as-errors compile: 3,679 files.
- Whole-builder AST comparison after callback normalization: exact.
- Projection comparison: 125/125 keys and expressions, zero mismatches.
- Four shared callbacks are exact; provider-result conversion remains only at
  `contact_result` and `command_result`.
- Station-calendar dispatch, station-reservation reuse, and public
  `CadenceImport` definitions: unchanged.
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

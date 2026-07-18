# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport contact-allocation manifest-row builder extraction.

Status:
Implementation `0d59c21b` published; verified handoff publication pending.

Completed slice:
Moved the contact-allocation manifest row projection and exclusive provider-
reservation action clauses into internal
`CadenceImport.ContactAllocationManifestRow.build/3`. The facade injects only
four shared review/status/provider-result/compaction callbacks.

Why this slice:
`CadenceImport` was 6,683 lines. The contact-allocation builder was a 205-line
transformation with 185 projected keys. `CadenceImport` is now 6,481 lines.

Published commits:
- Selection: `2ce1d7b7`
- Selection correction: `6c1bc239`
- Implementation: `0d59c21b`
- Handoff: pending

Preserved facade and behavior:
All `CadenceImport` APIs; all 185 contact-allocation keys and value expressions;
approval/import defaults, provider-reservation action, provider-result
normalization, import status, compaction, deterministic output, and artifact
contracts.

Verification:
- Focused Cadence-import plus schema-contract tests: 100/100.
- Strict warnings-as-errors compile: 3,678 files.
- Whole-builder AST comparison after callback normalization: exact.
- Projection comparison: 185/185 keys and expressions, zero mismatches.
- Moved two-clause import-action helper: AST-identical.
- Four shared callbacks are exact; provider-result conversion remains only at
  `contact_result` and `command_result`.
- Contact-allocation dispatch and public `CadenceImport` definitions: unchanged.
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

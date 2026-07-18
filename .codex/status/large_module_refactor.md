# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport strategy-recommendation manifest-row builder extraction.

Status:
Implementation `1126b2ac` published; verified handoff publication pending.

Completed slice:
Moved the strategy-recommendation manifest row projection and ordered context
merge pipeline into internal
`CadenceImport.StrategyRecommendationManifestRow.build/3`. The facade now
injects only six shared review/status/branch-catalog/compaction callbacks.

Why this slice:
`CadenceImport` was 7,827 lines. The builder was a 379-line transformation with
200 direct projection keys and 30 risk-context catalog merges.
`CadenceImport` is now 7,460 lines.

Published commits:
- Selection: `6f9fb251`
- Implementation: `1126b2ac`
- Handoff: pending

Preserved facade and behavior:
All `CadenceImport` APIs; all 200 strategy-recommendation keys and value
expressions; exact 34-stage merge/compaction order; defaults, import
status/action, collision precedence, deterministic output, and artifact
contracts.

Verification:
- Full Cadence-import tests plus schema Cadence-import contracts: 100/100.
- Strict warnings-as-errors compile: 3,674 files.
- Whole-builder AST comparison after callback normalization: exact.
- Projection comparison: 200/200 keys and expressions, zero mismatches.
- Pipeline comparison: exact 30 risk-context merges, three branch-field merges,
  and final compaction.
- Six shared facade callbacks: exact names, purposes, and arities.
- Strategy-recommendation dispatch and public `CadenceImport` definitions:
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

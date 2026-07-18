# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport timeline-diff manifest-row builder extraction.

Status:
Implementation `7cde78b9` published; verified handoff publication pending.

Completed slice:
Moved the timeline-diff and transition-application manifest row projection into
internal `CadenceImport.TimelineDiffManifestRow.build/3`. The facade now
injects only five shared review/status/context/normalization/compaction
callbacks.

Why this slice:
`CadenceImport` was 7,166 lines. The timeline-diff builder was a 266-line
transformation with 182 projected keys. `CadenceImport` is now 6,911 lines.

Published commits:
- Selection: `aa847108`
- Implementation: `7cde78b9`
- Handoff: pending

Preserved facade and behavior:
All `CadenceImport` APIs; all 182 timeline-diff keys and value expressions;
approval/import defaults, activity-context fallback and normalization, import
status/action, compaction, deterministic output, and artifact contracts.

Verification:
- Full Cadence-import tests plus schema Cadence-import contracts: 100/100.
- Strict warnings-as-errors compile: 3,676 files.
- Whole-builder AST comparison after callback normalization: exact.
- Projection comparison: 182/182 keys and expressions, zero mismatches.
- Five shared facade callbacks: exact names, purposes, and arities.
- Generic context fallback, three normalization sites, and final compaction:
  unchanged.
- Timeline-diff dispatch and public `CadenceImport` definitions: unchanged.
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

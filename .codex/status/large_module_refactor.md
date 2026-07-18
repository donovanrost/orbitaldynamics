# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport maneuver-review manifest-row builder extraction.

Status:
Implementation published as `a9b6565b`; handoff publication pending.

Selected slice:
Move `maneuver_review_manifest_row/2` into internal
`CadenceImport.ManeuverReviewManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,388 lines. The builder was a 50-line transformation with
41 projected keys, no exclusive helper dependencies, and one facade caller.
The facade is now 5,348 lines.

Public facade to preserve:
All `CadenceImport` APIs; all maneuver-review keys and value expressions;
action/status semantics, import/approval defaults, compaction, deterministic
output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/maneuver_review_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 41-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,699 files.
- Exact AST proof: 41/41 entries, full normalized body, and all public facade
  definitions match selection `5f7acd7e`.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Maneuver-review action/status, import/approval defaults, compaction,
deterministic output, and APIs are exact.

Last completed slice:
Maneuver-review row builder selected in `5f7acd7e` and published in `a9b6565b`:
focused 100/100, strict 3,699-file compile, exact 41-entry/full-body AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.

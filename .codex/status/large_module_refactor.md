# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport maneuver-review manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `maneuver_review_manifest_row/2` into internal
`CadenceImport.ManeuverReviewManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` is 5,388 lines. The builder is a 50-line transformation with 41
projected keys, no exclusive helper dependencies, and one facade caller.

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
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Quality-gate row builder selected in `d82271bc` and published in `01fc9f40`:
focused 100/100, strict 3,698-file compile, exact 33-entry/full-body and
merge-order comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.

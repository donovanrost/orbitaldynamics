# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport operational-readiness manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `operational_readiness_manifest_row/2` into internal
`CadenceImport.OperationalReadinessManifestRow.build/3`. Inject eight shared
facade helpers for generic action, review action, adapter status, four readiness
contexts, and compact-map cleanup.

Why this slice:
`CadenceImport` is 5,348 lines. The builder has 36 projected keys, four ordered
context merges, eight shared dependencies, and one facade caller.

Public facade to preserve:
All `CadenceImport` APIs; all operational-readiness keys and value expressions;
resource, adapter, training, then cadence context precedence; generic action,
import/approval defaults, compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/operational_readiness_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 36-key projection and four ordered merges;
the facade supplies eight exact callbacks; focused tests, strict compile,
equivalence/API checks, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Maneuver-review row builder selected in `5f7acd7e` and published in `a9b6565b`:
focused 100/100, strict 3,699-file compile, exact 41-entry/full-body AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.

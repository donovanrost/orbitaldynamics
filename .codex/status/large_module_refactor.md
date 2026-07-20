# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema cadence-import manifest owner completion.

Status:
Complete and pushed.

Selected boundary:
Add `CadenceImportValidation.validate_manifest_artifact/3`, reusing the
existing `CadenceImportRegistryContracts` requirements before the manifest
validator. Route the direct `cadence_import_manifest.v1` `Schema` clause through
the owner and preserve every existing owner API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,739 lines; the other
  targeted public facades are now 164 to 524 lines.
- The direct clause repeats required-field setup before delegating to the
  existing `CadenceImportValidation` owner.
- `CadenceImportRegistryContracts` is already the authoritative registry source
  for this single artifact family.
- No route needs recursive `Schema` lookup.

Implementation:
Added `CadenceImportValidation.validate_manifest_artifact/3`, which owns
registry-backed required-field validation before the existing manifest
validator. Routed the direct `cadence_import_manifest.v1` `Schema` clause
through that owner. `schema.ex` moved from 4,739 to 4,737 lines; the focused
owner moved from 187 to 202 lines.

Verification:
- Strict focused baseline: 85 tests passed.
- Full cadence-import family plus replay, planner, export, and fixture adjacency:
  131 tests passed.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,086 files successfully.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `CadenceImportValidation` APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema cadence-import manifest owner completion, selected in `4111306d` and
implemented in `62b6341a`. `schema.ex` moved from 4,739 to 4,737 lines.

Next candidate:
Re-rank the remaining direct `Schema` validation clauses, prioritizing a
cohesive owner that can absorb facade-owned required-field and model-limit
setup without recursive `Schema` lookup or public API changes.

Blocked:
No.

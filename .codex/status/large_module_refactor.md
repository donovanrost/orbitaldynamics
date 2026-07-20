# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema cadence-import manifest owner completion.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `CadenceImportValidation` APIs, validation results, and checked-in
exports must remain unchanged.

Last completed slice:
Schema candidate-rejection owner completion, selected in `ab9be7ad` and
implemented in `c86ebe51`. `schema.ex` moved from 4,741 to 4,739 lines.

Next candidate:
Implement and verify the selected cadence-import manifest owner completion,
then re-rank the remaining Schema responsibility clusters.

Blocked:
No.

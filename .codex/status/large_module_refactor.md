# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport provider-result normalization extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract provider-result artifact normalization into
`OrbitalDynamics.CadenceImport.ProviderResultNormalization`. Move ownership of
the provider-result field list, map-value key list, recursive value collection,
artifact scalarization, and result-field normalization. Preserve
`CadenceImport` as the public facade with narrow private delegates, and source
the capability metadata from the extracted module.

Selection evidence:
- `cadence_import.ex` remains a 3,813-line production facade after the test-ledger
  extractions.
- The selected private family spans about 89 lines and is used through two
  callback surfaces across proposed-contact, review, suppression, timeline, and
  generic import row builders.
- The family has one cohesive responsibility: flatten provider result values
  from strings, lists, maps, atoms, numerics, and booleans into stable artifact
  strings, deleting empty results.
- Capability metadata exposes the map-value key list, so the extracted module
  will own and return that exact list without changing the public capability
  shape.
- Manifest dispatch, row construction, public function signatures, schemas,
  ordering, and every non-provider normalization helper remain outside the
  boundary.

Verification:
Pending: capability/provider-map focused baselines, strict compile, focused and
all combined CadenceImport tests, schema contracts, exact capability equality,
static ownership checks, compile-connected xref, and bounded review.

Behavior/schema changes:
None. This is a test-only ownership split with all assertions preserved.

Last completed slice:
CadenceImport wrapped specialized quality-gate test family split, selected in
`189bd883`, corrected in `aa645476`, and implemented in `00d8d22d`.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing map after
provider-result normalization has one production owner.

Blocked:
No.

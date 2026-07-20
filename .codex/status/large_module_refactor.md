# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence-import validation context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add an owner-default CadenceImportValidation entry point for manifests and keep
manifest, import-row, source-review-row, and handoff callback composition in
that owner. Route the Schema manifest consumer directly and remove the three
facade validators plus three callback bags. Keep the existing customizable
contract and callback-builder APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,475 lines; the other
  targeted public facades are now 164 to 524 lines.
- Manifest defaults require only Cadence capability metadata, existing
  expiration/suppression owners, and the owner-local import-row validator.
- Import-row defaults require capability metadata, primitive/ID validators,
  previously extracted validation owners, and the owner-local source-review
  validator.
- Source-review and handoff callback graphs resolve entirely to primitive
  validators or existing owner modules.
- The only recursive edge is import row to source-review row, so no callback
  needs Schema lookup or facade-local validation.
- Owner-default entry points preserve all customizable contract and callback
  APIs.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Capability metadata, callback ordering, issue ordering and paths,
customizable contract APIs, public Schema APIs, validation results, and
checked-in exports must remain unchanged.

Last completed slice:
Schema operator-review validation context extraction, selected in `3b0ee4c3`
and implemented in `c8223f43`.
`schema.ex` moved from 5,576 to 5,475 lines.

Next candidate:
Implement and verify the selected Cadence-import validation context extraction,
then re-rank the remaining non-capability Schema responsibility clusters.

Blocked:
No.

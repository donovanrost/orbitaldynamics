# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence-import validation context extraction.

Status:
Completed and pushed.

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
Added CadenceImportValidation with owner-default manifest, import-row, and
source-review-row entry points. Moved manifest capability context and all three
callback bags into that owner, kept the customizable contract/callback-builder
APIs, routed the Schema manifest consumer directly, removed the facade
validators and callback bags, and moved shared scalar-count metadata into
CadenceImportCapabilityContext. `schema.ex` moved from 5,475 to 5,294 lines.

Verification:
- Strict Cadence-import/review baseline before extraction: 14 passed.
- The same strict focused suite after extraction: 14 passed.
- Strict full Cadence-import, review, and campaign-contract coverage: 125
  passed.
- Strict schema-export and export-task coverage: 25 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms one direct facade manifest call, zero
  facade Cadence validators or callback bags, and owner-local row recursion.
- `mix xref callers OrbitalDynamics.Schema.CadenceImportValidation` reports
  only the expected Schema facade runtime caller.
- Capability-context xref reports only the expected Schema export/runtime and
  CadenceImportValidation runtime callers.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,073 files with no warnings.
- Bounded local review found no callback loss, ordering change, or duplicate
  validation.
- Implementation commit `e4d9f571` pushed to `main`.

Behavior/schema changes:
None. Capability metadata, callback ordering, issue ordering and paths,
customizable contract APIs, public Schema APIs, validation results, and
checked-in exports remain unchanged.

Last completed slice:
Schema Cadence-import validation context extraction, selected in `3f6438ff` and
implemented in `e4d9f571`.
`schema.ex` moved from 5,475 to 5,294 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.

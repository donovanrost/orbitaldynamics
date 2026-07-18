# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport generic-review passthrough field-registry extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move the exact ordered field list from
`CadenceImport.generic_review_passthrough_fields/0` into internal
`CadenceImport.GenericReviewPassthroughFields.fields/0`. Keep the sole
`generic_review_manifest_row/2` `Map.take/2` call and all row construction in
the facade.

Why this slice:
`CadenceImport` is 8,674 lines. The field registry is a 388-line static data
responsibility with 384 ordered entries and one intentional duplicate
(`requires_operator_review`).

Current coupling/problem:
The main artifact adapter embeds a large generic-review field catalog directly
beside manifest construction and source-specific row transformation behavior.

Public facade to preserve:
All `CadenceImport` APIs; generic operator-review row keys and values;
passthrough field membership and order; the intentional duplicate; import
actions/statuses; deterministic manifest output; and all artifact contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/generic_review_passthrough_fields.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal module owns the exact 384-entry ordered registry; the facade’s sole
caller delegates to it; focused Cadence-import/operator-review and contract
tests pass; strict warnings-as-errors compile, exact field-list comparison,
public API comparison, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and independent
  review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Operator-review row callback provider published as implementation `1688b4f9`
and handoff `68ee425d`: focused 33/33, strict 3,671-file compile, full
byte-clean schema regeneration, exact 86-key comparison, and independent
review passed.

Next candidate:
Remap `CadenceImport` after extraction and select a source-specific manifest-row
builder or another large static registry.

Blocked:
No.
